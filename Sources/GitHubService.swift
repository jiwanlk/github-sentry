import Foundation

class GitHubService {
    private let token: String
    private let session: URLSession
    private let baseURL = "https://api.github.com"
    private var notificationLastModified: String?
    private var lastNotificationCheck: Date?

    init(token: String) {
        self.token = token
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Accept": "application/vnd.github+json",
            "Authorization": "Bearer \(token)",
            "X-GitHub-Api-Version": "2022-11-28"
        ]
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    func getAuthenticatedUser() async throws -> AuthenticatedUser {
        let data = try await get("/user")
        return try JSONDecoder().decode(AuthenticatedUser.self, from: data)
    }

    func getMyPullRequests() async throws -> [PullRequest] {
        let user = try await getAuthenticatedUser()
        let login = user.login

        let items = try await searchPRs(query: "is:pr is:open author:\(login)")

        // Deduplicate by URL
        var seen = Set<String>()
        var prs: [PullRequest] = []
        for item in items {
            if !seen.contains(item.htmlUrl) {
                seen.insert(item.htmlUrl)
                prs.append(normalizePR(item))
            }
        }
        return prs
    }

    func getActivities(for prs: [PullRequest]) async throws -> [Activity] {
        var activities: [Activity] = []

        for pr in prs {
            do {
                async let comments = getComments(owner: pr.owner, repo: pr.repo, number: pr.number)
                async let reviews = getReviews(owner: pr.owner, repo: pr.repo, number: pr.number)
                async let checks = getCheckRuns(owner: pr.owner, repo: pr.repo, ref: pr.headSha)

                let (c, r, ch) = try await (comments, reviews, checks)

                for comment in c {
                    activities.append(Activity(
                        id: "comment-\(comment.id)",
                        type: .comment,
                        prUrl: pr.htmlUrl,
                        prTitle: pr.title,
                        repo: pr.repoFullName,
                        prNumber: pr.number,
                        author: comment.user.login,
                        body: String((comment.body ?? "").prefix(120)),
                        state: "",
                        timestamp: comment.updatedAt
                    ))
                }

                for review in r {
                    activities.append(Activity(
                        id: "review-\(review.id)",
                        type: .review,
                        prUrl: pr.htmlUrl,
                        prTitle: pr.title,
                        repo: pr.repoFullName,
                        prNumber: pr.number,
                        author: review.user.login,
                        body: "",
                        state: review.state,
                        timestamp: review.submittedAt ?? ""
                    ))
                }

                for check in ch {
                    activities.append(Activity(
                        id: "ci-\(pr.number)-\(check.id)",
                        type: .ci,
                        prUrl: pr.htmlUrl,
                        prTitle: pr.title,
                        repo: pr.repoFullName,
                        prNumber: pr.number,
                        author: check.name,
                        body: "",
                        state: check.conclusion ?? check.status,
                        timestamp: check.completedAt ?? check.startedAt ?? ""
                    ))
                }
            } catch {
                print("Error fetching activities for \(pr.owner)/\(pr.repo)#\(pr.number): \(error.localizedDescription)")
            }
        }

        return activities
    }

    /// Check GitHub Notifications API using conditional requests.
    /// Returns true if new PR-related notifications exist, false on 304 (nothing new).
    func checkForNewNotifications() async throws -> Bool {
        var urlString = "\(baseURL)/notifications?participating=true&per_page=10"

        // Use 'since' to only get notifications after last check
        if let lastCheck = lastNotificationCheck {
            let formatter = ISO8601DateFormatter()
            urlString += "&since=\(formatter.string(from: lastCheck))"
        }

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        if let lastModified = notificationLastModified {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Save Last-Modified for next conditional request
        if let lm = http.value(forHTTPHeaderField: "Last-Modified") {
            notificationLastModified = lm
        }

        if http.statusCode == 304 {
            return false // Nothing new — zero rate limit cost
        }

        if http.statusCode == 401 {
            throw GitHubError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            throw GitHubError.apiError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "")
        }

        lastNotificationCheck = Date()

        let notifications = try JSONDecoder().decode([GitHubNotification].self, from: data)
        let hasPRActivity = notifications.contains { $0.subject.type == "PullRequest" && $0.unread }
        print("[notif-check] \(notifications.count) notifications, PR activity: \(hasPRActivity)")
        return hasPRActivity
    }

    // MARK: - Private API calls

    private func searchPRs(query: String) async throws -> [SearchItem] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        let data = try await get("/search/issues?q=\(encoded)&sort=updated&order=desc&per_page=50")
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        return response.items
    }

    private func getComments(owner: String, repo: String, number: Int) async throws -> [IssueComment] {
        let data = try await get("/repos/\(owner)/\(repo)/issues/\(number)/comments?per_page=20&sort=updated&direction=desc")
        return try JSONDecoder().decode([IssueComment].self, from: data)
    }

    private func getReviews(owner: String, repo: String, number: Int) async throws -> [Review] {
        let data = try await get("/repos/\(owner)/\(repo)/pulls/\(number)/reviews?per_page=20")
        return try JSONDecoder().decode([Review].self, from: data)
    }

    private func getCheckRuns(owner: String, repo: String, ref: String?) async throws -> [CheckRun] {
        guard let ref = ref, !ref.isEmpty else { return [] }
        do {
            let data = try await get("/repos/\(owner)/\(repo)/commits/\(ref)/check-runs?per_page=30")
            let response = try JSONDecoder().decode(CheckRunsResponse.self, from: data)
            return response.checkRuns
        } catch {
            return []
        }
    }

    private func get(_ path: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if http.statusCode == 401 {
            throw GitHubError.unauthorized
        }
        guard (200...299).contains(http.statusCode) else {
            throw GitHubError.apiError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }

    private func normalizePR(_ item: SearchItem) -> PullRequest {
        // URL format: https://github.com/owner/repo/pull/123
        // URL(path).pathComponents: ["/", "owner", "repo", "pull", "123"]
        let components = URL(string: item.htmlUrl)?.pathComponents ?? []
        let owner = components.count > 1 ? components[1] : ""
        let repo = components.count > 2 ? components[2] : ""

        return PullRequest(
            id: item.number,
            number: item.number,
            title: item.title,
            htmlUrl: item.htmlUrl,
            owner: owner,
            repo: repo,
            updatedAt: item.updatedAt,
            headSha: nil, // Search API doesn't return head SHA directly
            user: item.user.login
        )
    }
}

enum GitHubError: LocalizedError {
    case unauthorized
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Invalid or expired GitHub token"
        case .apiError(let code, let msg):
            return "GitHub API error \(code): \(msg.prefix(100))"
        }
    }
}

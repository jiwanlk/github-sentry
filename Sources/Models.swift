import Foundation

struct PullRequest: Codable, Identifiable {
    let id: Int
    let number: Int
    let title: String
    let htmlUrl: String
    let owner: String
    let repo: String
    let updatedAt: String
    let headSha: String?
    let user: String

    var url: URL? { URL(string: htmlUrl) }
    var repoFullName: String { "\(owner)/\(repo)" }
}

struct PRStatus {
    var isApproved: Bool = false
    var changesRequested: Bool = false
    var ciFailed: Bool = false
    var ciPassed: Bool = false
}

struct Activity: Codable, Identifiable {
    let id: String
    let type: ActivityType
    let prUrl: String
    let prTitle: String
    let repo: String
    let prNumber: Int
    let author: String
    let body: String
    let state: String
    let timestamp: String
}

enum ActivityType: String, Codable {
    case comment
    case review
    case ci
}

// MARK: - GitHub API Response Models

struct SearchResponse: Codable {
    let totalCount: Int
    let items: [SearchItem]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case items
    }
}

struct SearchItem: Codable {
    let number: Int
    let title: String
    let htmlUrl: String
    let state: String
    let updatedAt: String
    let user: GitHubUser
    let pullRequest: PullRequestRef?

    enum CodingKeys: String, CodingKey {
        case number, title, state, user
        case htmlUrl = "html_url"
        case updatedAt = "updated_at"
        case pullRequest = "pull_request"
    }
}

struct PullRequestRef: Codable {
    let url: String?
}

struct GitHubUser: Codable {
    let login: String
}

struct AuthenticatedUser: Codable {
    let login: String
}

struct IssueComment: Codable {
    let id: Int
    let body: String?
    let user: GitHubUser
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, body, user
        case updatedAt = "updated_at"
    }
}

struct Review: Codable {
    let id: Int
    let state: String
    let user: GitHubUser
    let submittedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, state, user
        case submittedAt = "submitted_at"
    }
}

struct CheckRunsResponse: Codable {
    let totalCount: Int
    let checkRuns: [CheckRun]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case checkRuns = "check_runs"
    }
}

struct CheckRun: Codable {
    let id: Int
    let name: String
    let status: String
    let conclusion: String?
    let startedAt: String?
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status, conclusion
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
}

struct GitHubNotification: Codable {
    let id: String
    let subject: NotificationSubject
    let reason: String
    let unread: Bool
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, subject, reason, unread
        case updatedAt = "updated_at"
    }
}

struct NotificationSubject: Codable {
    let title: String
    let type: String
    let url: String?
    let latestCommentUrl: String?

    enum CodingKeys: String, CodingKey {
        case title, type, url
        case latestCommentUrl = "latest_comment_url"
    }
}

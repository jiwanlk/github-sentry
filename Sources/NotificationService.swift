import Foundation
import UserNotifications
import AppKit

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    func sendBatch(_ activities: [Activity]) {
        guard !activities.isEmpty else { return }

        // Group by PR
        var grouped: [String: (prTitle: String, repo: String, prUrl: String, prNumber: Int, items: [Activity])] = [:]
        for activity in activities {
            if grouped[activity.prUrl] == nil {
                grouped[activity.prUrl] = (activity.prTitle, activity.repo, activity.prUrl, activity.prNumber, [])
            }
            grouped[activity.prUrl]?.items.append(activity)
        }

        for (_, group) in grouped {
            sendGroupNotification(group)
        }
    }

    private func sendGroupNotification(_ group: (prTitle: String, repo: String, prUrl: String, prNumber: Int, items: [Activity])) {
        let content = UNMutableNotificationContent()
        content.title = "#\(group.prNumber) \(group.prTitle)"
        content.subtitle = "\(group.repo) · \(activitySummary(group.items))"
        content.sound = .default
        content.userInfo = ["url": group.prUrl]

        let count = group.items.count
        if count == 1 {
            content.body = formatActivity(group.items[0])
        } else {
            let preview = group.items.prefix(3).map { formatActivity($0) }
            var body = preview.joined(separator: "\n")
            if count > 3 {
                body += "\n+\(count - 3) more"
            }
            content.body = body
        }

        let request = UNNotificationRequest(
            identifier: "pr-\(group.prUrl)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }

    private func activitySummary(_ items: [Activity]) -> String {
        if items.count == 1 {
            let item = items[0]
            switch item.type {
            case .comment: return "New comment"
            case .review:
                switch item.state {
                case "APPROVED": return "Approved"
                case "CHANGES_REQUESTED": return "Changes requested"
                case "COMMENTED": return "Review comment"
                case "DISMISSED": return "Review dismissed"
                default: return "Review"
                }
            case .ci:
                switch item.state {
                case "success": return "Build passed"
                case "failure": return "Build failed"
                default: return "CI update"
                }
            }
        }
        // Multiple items — summarize types
        var labels: [String] = []
        let types = Set(items.map { $0.type })
        if types.contains(.comment) { labels.append("comment") }
        if types.contains(.review) {
            if items.contains(where: { $0.type == .review && $0.state == "APPROVED" }) {
                labels.append("approval")
            } else if items.contains(where: { $0.type == .review && $0.state == "CHANGES_REQUESTED" }) {
                labels.append("changes requested")
            } else {
                labels.append("review")
            }
        }
        if types.contains(.ci) {
            if items.contains(where: { $0.type == .ci && $0.state == "failure" }) {
                labels.append("build failed")
            } else {
                labels.append("CI update")
            }
        }
        return labels.joined(separator: ", ")
    }

    private func formatActivity(_ activity: Activity) -> String {
        switch activity.type {
        case .comment:
            return "💬 \(activity.author): \(String(activity.body.prefix(80)))"
        case .review:
            let stateMap: [String: String] = [
                "APPROVED": "✅ Approved",
                "CHANGES_REQUESTED": "🔴 Changes requested",
                "COMMENTED": "💬 Reviewed",
                "DISMISSED": "⚪ Dismissed",
                "PENDING": "⏳ Pending"
            ]
            let label = stateMap[activity.state] ?? activity.state
            return "\(label) by \(activity.author)"
        case .ci:
            let icon = activity.state == "success" ? "✅" : activity.state == "failure" ? "❌" : "⏳"
            return "\(icon) CI: \(activity.author) — \(activity.state)"
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let urlString = response.notification.request.content.userInfo["url"] as? String,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

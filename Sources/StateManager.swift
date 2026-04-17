import Foundation

class StateManager {
    private var state: ActivityState
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("GitHubSentry", isDirectory: true)

        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        fileURL = appDir.appendingPathComponent("activity-state.json")
        state = StateManager.load(from: fileURL)
    }

    func findNewActivities(_ activities: [Activity]) -> [Activity] {
        activities.filter { state.seen[$0.id] == nil }
    }

    func markSeen(_ activities: [Activity]) {
        for a in activities {
            if state.seen[a.id] == nil {
                state.unread[a.prUrl, default: 0] += 1
            }
            state.seen[a.id] = true
        }

        // Prune old entries (keep last 5000)
        if state.seen.count > 5000 {
            let keys = Array(state.seen.keys)
            let toRemove = keys.prefix(keys.count - 5000)
            for key in toRemove {
                state.seen.removeValue(forKey: key)
            }
        }

        save()
    }

    func markAllRead() {
        state.unread = [:]
        save()
    }

    func getUnreadCounts() -> [String: Int] {
        state.unread
    }

    func getTotalUnread() -> Int {
        state.unread.values.reduce(0, +)
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save state: \(error.localizedDescription)")
        }
    }

    private static func load(from url: URL) -> ActivityState {
        guard let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(ActivityState.self, from: data) else {
            return ActivityState(seen: [:], unread: [:])
        }
        return state
    }
}

private struct ActivityState: Codable {
    var seen: [String: Bool]
    var unread: [String: Int]
}

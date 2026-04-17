import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController!
    var githubService: GitHubService?
    var notificationService: NotificationService!
    var stateManager: StateManager!
    var pollTimer: Timer?
    var settingsWindowController: SettingsWindowController?
    var isPolling = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        notificationService = NotificationService()
        notificationService.requestPermission()
        stateManager = StateManager()

        statusBarController = StatusBarController(
            onOpenPR: { url in NSWorkspace.shared.open(url) },
            onMarkAllRead: { [weak self] in self?.markAllRead() },
            onSettings: { [weak self] in self?.showSettings() },
            onRefresh: { [weak self] in self?.poll() },
            onQuit: { NSApp.terminate(nil) }
        )

        let token = KeychainHelper.getToken()
        if token == nil || token?.isEmpty == true {
            showSettings()
        } else {
            startPolling()
        }
    }

    func showSettings() {
        if let wc = settingsWindowController {
            wc.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let wc = SettingsWindowController(onSave: { [weak self] in
            self?.restartPolling()
        })
        wc.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController = wc
    }

    func startPolling() {
        guard let token = KeychainHelper.getToken(), !token.isEmpty else { return }
        githubService = GitHubService(token: token)

        poll()

        let interval = UserDefaults.standard.integer(forKey: "pollInterval")
        let minutes = max(1, interval == 0 ? 5 : interval)
        pollTimer = Timer.scheduledTimer(withTimeInterval: Double(minutes) * 60, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func restartPolling() {
        stopPolling()
        startPolling()
    }

    func poll() {
        guard let service = githubService, !isPolling else {
            print("[poll] Skipped (already polling or no service)")
            return
        }
        isPolling = true

        Task { @MainActor in
            statusBarController.startRefreshing()
        }

        Task {
            do {
                let prs = try await service.getMyPullRequests()
                print("[poll] Found \(prs.count) PRs")
                let activities = try await service.getActivities(for: prs)
                print("[poll] Found \(activities.count) total activities")
                let newActivities = stateManager.findNewActivities(activities)
                print("[poll] Found \(newActivities.count) NEW activities")

                let notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
                print("[poll] Notifications enabled: \(notificationsEnabled)")
                if notificationsEnabled {
                    notificationService.sendBatch(newActivities)
                }

                stateManager.markSeen(activities)

                // Compute PR statuses from activities
                var prStatuses: [String: PRStatus] = [:]
                for activity in activities {
                    var status = prStatuses[activity.prUrl] ?? PRStatus()
                    switch activity.type {
                    case .review:
                        if activity.state == "APPROVED" { status.isApproved = true }
                        if activity.state == "CHANGES_REQUESTED" { status.changesRequested = true }
                    case .ci:
                        if activity.state == "failure" { status.ciFailed = true }
                        if activity.state == "success" { status.ciPassed = true }
                    case .comment:
                        break
                    }
                    prStatuses[activity.prUrl] = status
                }

                let finalStatuses = prStatuses

                await MainActor.run {
                    statusBarController.stopRefreshing()
                    statusBarController.updateMenu(prs: prs, prStatuses: finalStatuses)
                }
                isPolling = false
            } catch {
                isPolling = false
                await MainActor.run {
                    statusBarController.stopRefreshing()
                    statusBarController.setError(error.localizedDescription)
                }
            }
        }
    }

    func markAllRead() {
        stateManager.markAllRead()
        statusBarController.updateMenu(prs: [], prStatuses: [:])
        poll()
    }
}

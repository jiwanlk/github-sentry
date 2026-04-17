import Cocoa

class StatusBarController {
    private var statusItem: NSStatusItem
    private var prs: [PullRequest] = []
    private var prStatuses: [String: PRStatus] = [:]
    private var blipTimer: Timer?

    private let onOpenPR: (URL) -> Void
    private let onMarkAllRead: () -> Void
    private let onSettings: () -> Void
    private let onRefresh: () -> Void
    private let onQuit: () -> Void

    init(
        onOpenPR: @escaping (URL) -> Void,
        onMarkAllRead: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onRefresh: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onOpenPR = onOpenPR
        self.onMarkAllRead = onMarkAllRead
        self.onSettings = onSettings
        self.onRefresh = onRefresh
        self.onQuit = onQuit

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = GitHubIcon.menuBarIcon()
            button.toolTip = "GitHub Sentry"
        }

        buildMenu()
    }

    func updateMenu(prs: [PullRequest], prStatuses: [String: PRStatus]) {
        self.prs = prs
        self.prStatuses = prStatuses
        buildMenu()
        updateBadge()
    }

    func setError(_ message: String) {
        let menu = NSMenu()
        let truncated = String(message.prefix(50))
        menu.addItem(NSMenuItem(title: "⚠️ Error: \(truncated)", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        addItem(to: menu, title: "Settings…", action: #selector(settingsClicked))
        addItem(to: menu, title: "Refresh Now", action: #selector(refreshClicked))
        menu.addItem(.separator())
        addItem(to: menu, title: "Quit GitHub Sentry", action: #selector(quitClicked))
        statusItem.menu = menu
    }

    // MARK: - Private

    private func buildMenu() {
        let menu = NSMenu()

        let header = NSMenuItem(title: "GitHub Sentry", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        if prs.isEmpty {
            let empty = NSMenuItem(title: "No open pull requests", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            // Group by repo
            var byRepo: [(String, [PullRequest])] = []
            var repoOrder: [String] = []
            var repoMap: [String: [PullRequest]] = [:]
            for pr in prs {
                let key = pr.repoFullName
                if repoMap[key] == nil {
                    repoOrder.append(key)
                }
                repoMap[key, default: []].append(pr)
            }
            byRepo = repoOrder.map { ($0, repoMap[$0]!) }

            for (repoName, repoPRs) in byRepo {
                let repoItem = NSMenuItem(title: repoName, action: nil, keyEquivalent: "")
                repoItem.isEnabled = false
                menu.addItem(repoItem)

                for pr in repoPRs {
                    let status = prStatuses[pr.htmlUrl] ?? PRStatus()
                    var indicator = "  "
                    if status.changesRequested {
                        indicator = "🔴"
                    } else if status.ciFailed {
                        indicator = "❌"
                    } else if status.isApproved && status.ciPassed {
                        indicator = "✅"
                    } else if status.isApproved {
                        indicator = "✅"
                    } else if status.ciPassed {
                        indicator = "🟢"
                    }
                    let title = String(pr.title.prefix(45))
                    let label = "\(indicator) #\(pr.number) \(title)"

                    let item = PRMenuItem(title: label, action: #selector(prClicked(_:)), keyEquivalent: "")
                    item.target = self
                    item.prURL = pr.url
                    menu.addItem(item)
                }

                menu.addItem(.separator())
            }
        }

        menu.addItem(.separator())
        addItem(to: menu, title: "Mark All as Read", action: #selector(markAllReadClicked))
        addItem(to: menu, title: "Refresh Now", action: #selector(refreshClicked))
        menu.addItem(.separator())
        addItem(to: menu, title: "Settings…", action: #selector(settingsClicked))
        menu.addItem(.separator())
        addItem(to: menu, title: "Quit GitHub Sentry", action: #selector(quitClicked))

        statusItem.menu = menu
    }

    private func addItem(to menu: NSMenu, title: String, action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    private func updateBadge() {
        if let button = statusItem.button {
            button.image = GitHubIcon.menuBarIcon()
            button.title = ""
        }
    }

    func startRefreshing() {
        var visible = true
        blipTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            guard let button = self?.statusItem.button else { return }
            button.image = visible ? nil : GitHubIcon.menuBarIcon()
            button.title = visible ? "⟳" : ""
            visible.toggle()
        }
    }

    func stopRefreshing() {
        blipTimer?.invalidate()
        blipTimer = nil
        updateBadge()
    }

    // MARK: - Actions

    @objc private func prClicked(_ sender: NSMenuItem) {
        if let item = sender as? PRMenuItem, let url = item.prURL {
            onOpenPR(url)
        }
    }

    @objc private func markAllReadClicked() { onMarkAllRead() }
    @objc private func refreshClicked() { onRefresh() }
    @objc private func settingsClicked() { onSettings() }
    @objc private func quitClicked() { onQuit() }
}

private class PRMenuItem: NSMenuItem {
    var prURL: URL?
}

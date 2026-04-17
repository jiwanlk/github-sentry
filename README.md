# GitHub Sentry

A native macOS menu bar app that monitors your GitHub pull requests and sends notifications for new activity.

Built with **Swift** — zero external dependencies, no downloads blocked by corporate proxies.

## Features

- **Menu bar icon** with unread badge count (SF Symbols bell icon)
- **Polls GitHub API** at a configurable interval (1–60 minutes)
- **Detects new activity**: comments, reviews, CI status changes
- **Native macOS notifications** — click to open the PR in your browser
- **Tray menu** showing open PRs grouped by repo, with unread indicators
- **Mark all as read** clears unread state
- **Settings window** (SwiftUI) for token, polling interval, notifications, and launch-at-login
- **Secure token storage** via macOS Keychain
- **Persists seen-activity state** in `~/Library/Application Support/GitHubSentry/`
- **Launch at login** via SMAppService

## Requirements

- **macOS 13+** (Ventura or later)
- **Xcode Command Line Tools** (`xcode-select --install`)

## Build & Run

```bash
# Build and run (development)
make run

# Or step by step:
swift build
.build/debug/GitHubSentry
```

### Create .app Bundle

```bash
# Debug bundle
make bundle

# Release bundle (optimized)
make release

# Run the app
open "build/GitHub Sentry.app"
```

## GitHub Token

You need a **Personal Access Token** with these scopes:

| Scope | Why |
|---|---|
| `repo` | Read PR details, comments, reviews, check runs |
| `read:user` | Identify the authenticated user |

Create one at: https://github.com/settings/tokens/new?scopes=repo,read:user&description=GitHub+Sentry

Enter the token in **Settings** (click the menu bar icon → Settings…).

## Architecture

```
Sources/
  main.swift                    Entry point — sets up NSApplication
  AppDelegate.swift             App lifecycle, polling timer, orchestration
  StatusBarController.swift     NSStatusItem, context menu, badge count
  GitHubService.swift           URLSession-based GitHub REST API client
  NotificationService.swift     UNUserNotificationCenter notifications
  StateManager.swift            JSON persistence for seen/unread state
  KeychainHelper.swift          macOS Keychain for secure token storage
  SettingsView.swift            SwiftUI settings UI
  SettingsWindowController.swift  NSWindow host for SwiftUI view
  Models.swift                  Data models + GitHub API response types
Resources/
  Info.plist                    App bundle config (LSUIElement for menu bar)
```

### Key Design Decisions

- **Zero dependencies** — uses only Foundation, AppKit, SwiftUI, Security, and UserNotifications frameworks
- **No Electron/npm** — nothing to download that corporate proxies (Zscaler) can block
- **macOS Keychain** — token stored with `kSecAttrAccessibleWhenUnlocked`, encrypted by the OS
- **URLSession** — uses macOS system proxy and certificate trust settings automatically

### Polling Flow

1. `GitHubService.getMyPullRequests()` — searches for PRs you authored + PRs requesting your review
2. `GitHubService.getActivities(for:)` — fetches comments, reviews, and CI check runs per PR
3. `StateManager.findNewActivities()` — diffs against previously seen activity IDs
4. `NotificationService.sendBatch()` — groups new activities by PR, fires native notifications
5. `StatusBarController.updateMenu()` — rebuilds the context menu with unread counts

## License

MIT

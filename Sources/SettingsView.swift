import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var token: String = ""
    @State private var pollInterval: Int = 5
    @State private var launchAtLogin: Bool = false
    @State private var notificationsEnabled: Bool = true
    @State private var statusMessage: String = ""
    @State private var statusIsError: Bool = false
    @State private var isTesting: Bool = false
    @State private var isSaving: Bool = false
    @State private var testResult: String = ""
    @State private var testSuccess: Bool = false

    var onSave: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("GitHub Sentry")
                .font(.title)
                .fontWeight(.bold)

            Text("Configure your PR monitoring preferences")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Token
            VStack(alignment: .leading, spacing: 6) {
                Text("GitHub Personal Access Token")
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack {
                    SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $token)
                        .textFieldStyle(.roundedBorder)

                    Button(isTesting ? "Testing…" : "Test") {
                        testToken()
                    }
                    .disabled(isTesting || token.isEmpty)
                }

                Text("Needs `repo` and `read:user` scopes. ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                + Text("[Create token →](https://github.com/settings/tokens/new?scopes=repo,read:user&description=GitHub+Sentry)")
                    .font(.caption)

                if !testResult.isEmpty {
                    Text(testResult)
                        .font(.caption)
                        .foregroundColor(testSuccess ? .green : .red)
                        .padding(6)
                        .background(testSuccess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            // Poll interval
            VStack(alignment: .leading, spacing: 6) {
                Text("Polling Interval (minutes)")
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack {
                    TextField("5", value: $pollInterval, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)

                    Stepper("", value: $pollInterval, in: 1...60)
                        .labelsHidden()
                }
            }

            // Toggles
            Toggle("Enable notifications", isOn: $notificationsEnabled)
            Toggle("Launch at login", isOn: $launchAtLogin)

            Spacer()

            // Save
            HStack {
                Spacer()
                Button(isSaving ? "Saving…" : "Save Settings") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
                Spacer()
            }

            if !statusMessage.isEmpty {
                HStack {
                    Spacer()
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(statusIsError ? .red : .green)
                    Spacer()
                }
            }
        }
        .padding(24)
        .frame(width: 440, height: 480)
        .onAppear(perform: loadSettings)
    }

    private func loadSettings() {
        token = KeychainHelper.getToken() ?? ""
        let stored = UserDefaults.standard.integer(forKey: "pollInterval")
        pollInterval = stored > 0 ? stored : 5
        launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
    }

    private func testToken() {
        isTesting = true
        testResult = ""

        Task {
            let service = GitHubService(token: token)
            do {
                let user = try await service.getAuthenticatedUser()
                await MainActor.run {
                    testResult = "✓ Authenticated as \(user.login)"
                    testSuccess = true
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = "✗ \(error.localizedDescription)"
                    testSuccess = false
                    isTesting = false
                }
            }
        }
    }

    private func save() {
        isSaving = true
        statusMessage = ""

        let saved = KeychainHelper.saveToken(token)
        UserDefaults.standard.set(pollInterval, forKey: "pollInterval")
        UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")

        if launchAtLogin {
            if #available(macOS 13.0, *) {
                try? SMAppService.mainApp.register()
            }
        } else {
            if #available(macOS 13.0, *) {
                try? SMAppService.mainApp.unregister()
            }
        }

        statusMessage = saved ? "Settings saved successfully." : "Failed to save token to Keychain."
        statusIsError = !saved
        isSaving = false

        onSave?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            statusMessage = ""
        }
    }
}

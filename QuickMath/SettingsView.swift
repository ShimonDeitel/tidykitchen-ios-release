import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue

    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    private var theme: AppTheme {
        get { AppTheme(rawValue: themeRaw) ?? .system }
        set { themeRaw = newValue.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                List {
                    // MARK: Pro
                    Section("Pro") {
                        if store.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.qmAccent)
                                Text("TidyKitchen Pro — Active")
                                    .font(.subheadline.weight(.medium))
                            }
                            Link("Manage Subscription",
                                 destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                                .font(.subheadline)
                                .foregroundStyle(Color.qmAccent)
                        } else {
                            Button("Unlock Pro — \(store.displayPrice)/month") {
                                showPaywall = true
                            }
                            .foregroundStyle(Color.qmAccent)
                            Button("Restore Purchases") {
                                Task { await store.restore() }
                            }
                            .foregroundStyle(Color.qmAccent)
                        }
                    }

                    // MARK: Appearance
                    Section("Appearance") {
                        Picker("Theme", selection: $themeRaw) {
                            ForEach(AppTheme.allCases) { t in
                                Text(t.label).tag(t.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(.primary)
                    }

                    // MARK: Legal
                    Section("Legal") {
                        Link("Privacy Policy",
                             destination: URL(string: "https://shimondeitel.github.io/tidykitchen-site/privacy.html")!)
                            .font(.subheadline)
                            .foregroundStyle(Color.qmAccent)
                        Link("Terms of Use",
                             destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .font(.subheadline)
                            .foregroundStyle(Color.qmAccent)
                    }

                    // MARK: Data
                    Section("Data") {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .confirmationDialog(
                "Delete all kitchen tasks and streak data?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    appModel.deleteAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

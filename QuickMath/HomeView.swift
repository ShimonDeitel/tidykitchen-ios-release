import SwiftUI
import SwiftData

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false

    var body: some View {
        ZStack {
            QMBackground()
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TidyKitchen")
                                .font(.title2.weight(.bold))
                            Text("5-minute kitchen reset")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                                .font(.title3)
                                .foregroundStyle(Color.qmAccent)
                                .padding(10)
                                .background(Color.qmCard, in: Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Streak tiles (always visible, values shown to all)
                    HStack(spacing: 12) {
                        MetricTile(
                            value: "\(appModel.streak?.currentCount ?? 0)",
                            label: "Day Streak"
                        )
                        MetricTile(
                            value: "\(appModel.streak?.longestCount ?? 0)",
                            label: "Best Streak"
                        )
                    }
                    .padding(.horizontal)

                    // Today's task card
                    GridView()

                    // Pro tile
                    Button {
                        if store.isPro { showInsights = true } else { showPaywall = true }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: store.isPro ? "chart.bar.fill" : "lock.fill")
                                .font(.title3)
                                .foregroundStyle(Color.qmAccent)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.isPro ? "Your Insights" : "Unlock Pro")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(store.isPro
                                    ? "Streaks, calendar, custom zones"
                                    : "Streaks, reminders & more — $0.99/mo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .qmCard()
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
                .environmentObject(appModel)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showInsights) {
            InsightsView()
                .environmentObject(appModel)
        }
        .onAppear {
            if forceScreen == "paywall" { showPaywall = true }
            if forceScreen == "insights" { showInsights = true }
            if forceScreen == "settings" { showSettings = true }
        }
    }
}

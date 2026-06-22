import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let benefits = [
        ("Current and longest cleanup streaks with a completion calendar",
         "chart.bar.fill"),
        ("Customize zones and task frequency to fit your kitchen",
         "slider.horizontal.3"),
        ("Optional daily reminder at a time you choose",
         "bell.fill"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 28) {
                        // Icon & title
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.qmAccent.opacity(0.12))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 34, weight: .medium))
                                    .foregroundStyle(Color.qmAccent)
                            }
                            Text("TidyKitchen Pro")
                                .font(.title.weight(.bold))
                            Text("\(store.displayPrice) / month. Auto-renews until you cancel.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 12)

                        // Benefits
                        VStack(spacing: 14) {
                            ForEach(benefits, id: \.0) { benefit in
                                BenefitRow(text: benefit.0, icon: benefit.1)
                            }
                        }
                        .padding(.horizontal)

                        // Unlock button
                        Button {
                            Task { await store.purchase() }
                        } label: {
                            if store.purchaseInFlight {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Unlock Pro — \(store.displayPrice)/mo")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .prominentButton()
                        .padding(.horizontal)
                        .disabled(store.purchaseInFlight)

                        // Restore
                        Button {
                            Task { await store.restore() }
                        } label: {
                            Text("Restore Purchases")
                        }
                        .softButton()

                        // Auto-renew disclosure
                        Text("Subscription automatically renews at \(store.displayPrice)/month unless cancelled at least 24 hours before the end of the current period. Manage your subscription in App Store settings.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        // Legal links
                        HStack(spacing: 24) {
                            Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                .font(.caption2)
                                .foregroundStyle(Color.qmAccent)
                            Link("Privacy", destination: URL(string: "https://shimondeitel.github.io/tidykitchen-site/privacy.html")!)
                                .font(.caption2)
                                .foregroundStyle(Color.qmAccent)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: store.isPro) { _, newValue in
                if newValue { dismiss() }
            }
        }
    }
}

private struct BenefitRow: View {
    let text: String
    let icon: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.qmAccent)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

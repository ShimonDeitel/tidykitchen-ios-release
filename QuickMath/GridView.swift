import SwiftUI

struct GridView: View {
    @EnvironmentObject var appModel: AppModel

    private var task: TidyTask? { appModel.todayTask }
    private var assignment: DailyAssignment? { appModel.todayAssignment }

    var body: some View {
        VStack(spacing: 0) {
            if let task, let assignment {
                ZoneTag(zone: task.zone)
                    .padding(.bottom, 12)

                Text(task.title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(task.minutes) min")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.top, 6)

                Spacer(minLength: 28)

                if assignment.isDone {
                    DoneCheckmark()
                        .padding(.bottom, 8)
                    Text("Done for today!")
                        .font(.headline)
                        .foregroundStyle(Color.qmCorrect)
                    Text("Come back tomorrow for the next task.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    Button {
                        appModel.markTodayDone()
                    } label: {
                        Label("Mark Done", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .prominentButton()
                    .padding(.horizontal, 8)
                }
            } else {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundStyle(Color.qmAccent)
                    .padding(.bottom, 8)
                Text("Loading today's task…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal)
    }
}

// MARK: - Sub-views

private struct ZoneTag: View {
    let zone: String
    var body: some View {
        Text(zone.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(1.2)
            .foregroundStyle(Color.qmAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.qmAccent.opacity(0.12), in: Capsule())
    }
}

private struct DoneCheckmark: View {
    @State private var appeared = false
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.qmCorrect.opacity(0.15))
                .frame(width: 72, height: 72)
            Image(systemName: "checkmark")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.qmCorrect)
                .scaleEffect(appeared ? 1 : 0.4)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                appeared = true
            }
        }
    }
}

import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Streak summary
                        HStack(spacing: 12) {
                            MetricTile(
                                value: "\(appModel.streak?.currentCount ?? 0)",
                                label: "Current Streak"
                            )
                            MetricTile(
                                value: "\(appModel.streak?.longestCount ?? 0)",
                                label: "Longest Streak"
                            )
                        }
                        .padding(.horizontal)

                        // Completion calendar (last 28 days)
                        CalendarSection(assignments: appModel.recentAssignments)
                            .padding(.horizontal)

                        // Recent history list
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Tasks")
                                .font(.headline)
                                .padding(.horizontal)

                            if appModel.recentAssignments.isEmpty {
                                Text("No completed tasks yet. Start today!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding()
                            } else {
                                ForEach(appModel.recentAssignments.prefix(20), id: \.id) { assignment in
                                    AssignmentRow(assignment: assignment, appModel: appModel)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Calendar Grid (last 28 days)

private struct CalendarSection: View {
    let assignments: [DailyAssignment]

    private var last28: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        return (0..<28).reversed().compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: today)
        }
    }

    private func isDone(on date: Date) -> Bool {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return assignments.contains { a in
            a.isDone && a.date >= start && a.date < end
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 28 Days")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(last28, id: \.self) { day in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isDone(on: day) ? Color.qmCorrect : Color.qmField)
                        .frame(height: 36)
                        .overlay(
                            Text(dayNumber(day))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(isDone(on: day) ? .white : .secondary)
                        )
                }
            }
        }
        .qmCard()
    }

    private func dayNumber(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: date)
    }
}

// MARK: - Assignment row

private struct AssignmentRow: View {
    let assignment: DailyAssignment
    let appModel: AppModel

    private var dateString: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: assignment.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: assignment.isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(assignment.isDone ? Color.qmCorrect : Color.qmHair)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(dateString)
                    .font(.subheadline.weight(.medium))
                Text(assignment.isDone ? "Completed" : "Missed")
                    .font(.caption)
                    .foregroundStyle(assignment.isDone ? Color.qmCorrect : Color.qmWrong)
            }
            Spacer()
        }
        .qmCard()
    }
}

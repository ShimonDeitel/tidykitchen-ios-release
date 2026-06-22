import SwiftUI
import SwiftData

// MARK: - SwiftData Models

@Model
final class TidyTask {
    var id: UUID
    var title: String
    var zone: String
    var minutes: Int
    var frequencyDays: Int

    init(id: UUID = UUID(), title: String, zone: String, minutes: Int, frequencyDays: Int) {
        self.id = id
        self.title = title
        self.zone = zone
        self.minutes = minutes
        self.frequencyDays = frequencyDays
    }
}

@Model
final class DailyAssignment {
    var id: UUID
    var taskId: UUID
    var date: Date
    var isDone: Bool

    init(id: UUID = UUID(), taskId: UUID, date: Date, isDone: Bool = false) {
        self.id = id
        self.taskId = taskId
        self.date = date
        self.isDone = isDone
    }
}

@Model
final class StreakRecord {
    var id: UUID
    var currentCount: Int
    var longestCount: Int
    var lastDoneDate: Date?

    init(id: UUID = UUID(), currentCount: Int = 0, longestCount: Int = 0, lastDoneDate: Date? = nil) {
        self.id = id
        self.currentCount = currentCount
        self.longestCount = longestCount
        self.lastDoneDate = lastDoneDate
    }
}

// MARK: - Built-in Task Library

private let builtInTasks: [(title: String, zone: String, minutes: Int, frequencyDays: Int)] = [
    ("Wipe down stovetop", "Stovetop", 5, 2),
    ("Clear and wipe countertops", "Counters", 5, 1),
    ("Wipe microwave interior", "Microwave", 5, 7),
    ("Empty and clean sink", "Sink", 5, 1),
    ("Wipe cabinet fronts", "Cabinets", 5, 14),
    ("Clean refrigerator handle", "Fridge", 5, 7),
    ("Take out trash", "Trash", 2, 3),
    ("Sweep or vacuum floor", "Floor", 5, 3),
    ("Wipe oven door exterior", "Oven", 5, 7),
    ("Organize one drawer", "Storage", 5, 14),
    ("Descale kettle", "Appliances", 5, 30),
    ("Wipe toaster crumbs", "Appliances", 3, 14),
    ("Organize spice shelf", "Storage", 5, 30),
    ("Wipe light switch and door knob", "Surfaces", 2, 7),
    ("Clean dish drying rack", "Sink", 4, 7),
    ("Wipe exhaust fan exterior", "Ventilation", 3, 30),
    ("Organize plastic bags/wraps", "Storage", 5, 30),
    ("Wash reusable shopping bags", "Cleaning", 5, 30),
    ("Wipe dish soap dispenser", "Sink", 2, 14),
    ("Check fridge for expired items", "Fridge", 5, 7),
    ("Wipe range hood filters", "Ventilation", 5, 30),
    ("Clean sponge or replace", "Cleaning", 2, 7),
    ("Organize under-sink cabinet", "Storage", 5, 30),
    ("Wipe windowsill", "Surfaces", 3, 14),
    ("Descale coffee maker", "Appliances", 5, 30),
    ("Clean garbage disposal", "Sink", 3, 14),
    ("Organize pot lid drawer", "Storage", 5, 30),
    ("Wipe refrigerator door seals", "Fridge", 4, 14),
    ("Mop a small floor section", "Floor", 5, 7),
    ("Wipe backsplash tiles", "Surfaces", 5, 7),
]

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var todayTask: TidyTask?
    @Published private(set) var todayAssignment: DailyAssignment?
    @Published private(set) var streak: StreakRecord?
    @Published private(set) var recentAssignments: [DailyAssignment] = []

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([TidyTask.self, DailyAssignment.self, StreakRecord.self])
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [fallback])) ?? {
                fatalError("Cannot create ModelContainer: \(error)")
            }()
        }
    }

    func reload() {
        let ctx = container.mainContext
        ensureTasksSeeded(ctx: ctx)
        let streakRec = fetchOrCreateStreak(ctx: ctx)
        self.streak = streakRec
        self.todayAssignment = fetchOrCreateTodayAssignment(ctx: ctx)
        if let assignment = self.todayAssignment {
            self.todayTask = fetchTask(id: assignment.taskId, ctx: ctx)
        }
        let fetchDesc = FetchDescriptor<DailyAssignment>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        self.recentAssignments = (try? ctx.fetch(fetchDesc)) ?? []
    }

    func refresh() { reload() }

    func markTodayDone() {
        guard let assignment = todayAssignment, !assignment.isDone else { return }
        let ctx = container.mainContext
        assignment.isDone = true
        try? ctx.save()
        updateStreak(ctx: ctx)
        Haptics.success()
        reload()
    }

    func deleteAllData() {
        let ctx = container.mainContext
        try? ctx.delete(model: TidyTask.self)
        try? ctx.delete(model: DailyAssignment.self)
        try? ctx.delete(model: StreakRecord.self)
        try? ctx.save()
        reload()
    }

    // MARK: - Private helpers

    private func ensureTasksSeeded(ctx: ModelContext) {
        let desc = FetchDescriptor<TidyTask>()
        let existing = (try? ctx.fetch(desc)) ?? []
        guard existing.isEmpty else { return }
        for item in builtInTasks {
            let t = TidyTask(title: item.title, zone: item.zone, minutes: item.minutes, frequencyDays: item.frequencyDays)
            ctx.insert(t)
        }
        try? ctx.save()
    }

    private func fetchOrCreateStreak(ctx: ModelContext) -> StreakRecord {
        let desc = FetchDescriptor<StreakRecord>()
        if let existing = (try? ctx.fetch(desc))?.first { return existing }
        let rec = StreakRecord()
        ctx.insert(rec)
        try? ctx.save()
        return rec
    }

    private func fetchOrCreateTodayAssignment(ctx: ModelContext) -> DailyAssignment? {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        var desc = FetchDescriptor<DailyAssignment>(
            predicate: #Predicate { a in a.date >= today && a.date < tomorrow }
        )
        desc.fetchLimit = 1
        if let existing = (try? ctx.fetch(desc))?.first { return existing }
        // Pick a task for today using deterministic day-of-year rotation
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: today) ?? 1
        let allTasks = (try? ctx.fetch(FetchDescriptor<TidyTask>())) ?? []
        guard !allTasks.isEmpty else { return nil }
        let idx = (dayOfYear - 1) % allTasks.count
        let task = allTasks[idx]
        let assignment = DailyAssignment(taskId: task.id, date: today)
        ctx.insert(assignment)
        try? ctx.save()
        return assignment
    }

    private func fetchTask(id: UUID, ctx: ModelContext) -> TidyTask? {
        var desc = FetchDescriptor<TidyTask>(predicate: #Predicate { t in t.id == id })
        desc.fetchLimit = 1
        return (try? ctx.fetch(desc))?.first
    }

    private func updateStreak(ctx: ModelContext) {
        guard let rec = streak else { return }
        let today = Calendar.current.startOfDay(for: Date())
        if let last = rec.lastDoneDate {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            let lastDay = Calendar.current.startOfDay(for: last)
            if lastDay == yesterday {
                rec.currentCount += 1
            } else if lastDay < yesterday {
                rec.currentCount = 1
            }
            // same day: no change
        } else {
            rec.currentCount = 1
        }
        if rec.currentCount > rec.longestCount {
            rec.longestCount = rec.currentCount
        }
        rec.lastDoneDate = today
        try? ctx.save()
    }
}

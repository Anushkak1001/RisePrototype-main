//
//  ContentView.swift
//  Rise_prototype1
//
//  Created by Anushka Karthikeyan on 11/10/25.
//

import SwiftUI

// MARK: - Models

struct Skill: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    var xp: Int
    var lessons: [Lesson]
}

struct Lesson: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let content: String
    let choices: [String]? // if nil -> real-world prompt
    let answerIndex: Int?  // correct choice index
    let xpReward: Int
}

struct Quest: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let goalCount: Int
    let xpReward: Int
}

// MARK: - ViewModel

final class RiseViewModel: ObservableObject {
    @Published var xp: Int = 0
    @Published var streak: Int = 0
    @Published var skills: [Skill] = []
    @Published var completedLessons: Set<UUID> = []

    // Quest state (multi-quest)
    @Published var quests: [Quest] = [
        Quest(title: "Cook 3 meals this week", description: "Make and log three home-cooked meals. Add a photo or a note for each.", goalCount: 3, xpReward: 50),
        Quest(title: "Budget check-in", description: "Log your expenses on 2 different days this week.", goalCount: 2, xpReward: 40),
        Quest(title: "Laundry day", description: "Do 2 loads: lights and darks. Fold and put away.", goalCount: 2, xpReward: 45)
    ]
    @Published var selectedQuestIndex: Int = 0

    // Per-quest progress keyed by quest id
    @Published var questProgress: [UUID: Int] = [:]
    @Published var questStarted: Set<UUID> = []
    @Published var questCompleted: Set<UUID> = []
    @Published var questNotes: [UUID: [String]] = [:]

    init() {
        loadSampleData()
    }

    func loadSampleData() {
        let financeLessons = [
            Lesson(title: "Budget Basics",
                   content: "You have $1,200 and four categories: Rent, Food, Transport, Savings. Allocate percentages.",
                   choices: ["Rent 40%, Food 20%","Rent 60%, Food 10%","Rent 30%, Food 40%"],
                   answerIndex: 0,
                   xpReward: 20),
            Lesson(title: "Reading a Paycheck",
                   content: "Spot the take-home pay after taxes and deductions.",
                   choices: ["$1,800","$2,200","$1,600"],
                   answerIndex: 2,
                   xpReward: 15),
            Lesson(title: "Try: Track a day of spending",
                   content: "Go track every purchase you make today and add to app (real-world task).",
                   choices: nil,
                   answerIndex: nil,
                   xpReward: 25)
        ]

        let cookingLessons = [
            Lesson(title: "Pan Basics",
                   content: "What temperature range is good for a nonstick pan?",
                   choices: ["High heat always","Low-medium","Medium-high then low"],
                   answerIndex: 1,
                   xpReward: 10),
            Lesson(title: "Simple Pasta",
                   content: "Steps to cook al dente pasta and make a quick sauce.",
                   choices: nil,
                   answerIndex: nil,
                   xpReward: 20)
        ]
        let laundryLessons = [
            Lesson(title: "Different Textiles",
                   content: "What temperature range is good for a nonstick pan?",
                   choices: ["High heat always","Low-medium","Medium-high then low"],
                   answerIndex: 1,
                   xpReward: 10),
            Lesson(title: "Choosing Detergents & Settings",
                   content: "Steps to cook al dente pasta and make a quick sauce.",
                   choices: nil,
                   answerIndex: nil,
                   xpReward: 20)
        ]

        skills = [
            Skill(title: "Money & Finance", description: "Budgeting, saving, basic taxes.", xp: 0, lessons: financeLessons),
            Skill(title: "Food & Health", description: "Cooking, grocery planning, nutrition.", xp: 0, lessons: cookingLessons),
            Skill(title: "Laundry", description: "Washing, folding, and caring for clothes.", xp: 0, lessons: laundryLessons)
        ]
    }

    func completeLesson(_ lesson: Lesson) {
        guard !completedLessons.contains(lesson.id) else { return }
        xp += lesson.xpReward
        completedLessons.insert(lesson.id)
    }

    func answerMultipleChoice(_ lesson: Lesson, selectedIndex: Int) -> Bool {
        guard let correct = lesson.answerIndex else { return false }
        if selectedIndex == correct {
            completeLesson(lesson)
            return true
        }
        return false
    }

    // MARK: - Quest Logic (multi-quest)
    private var currentQuest: Quest? {
        guard quests.indices.contains(selectedQuestIndex) else { return nil }
        return quests[selectedQuestIndex]
    }

    func startQuest() {
        guard let quest = currentQuest else { return }
        guard !questStarted.contains(quest.id) else { return }
        questStarted.insert(quest.id)
        questProgress[quest.id] = 0
        questCompleted.remove(quest.id)
        questNotes[quest.id] = []
    }

    func addQuestEntry(note: String = "") {
        guard let quest = currentQuest else { return }
        guard questStarted.contains(quest.id), !questCompleted.contains(quest.id) else { return }
        let current = questProgress[quest.id] ?? 0
        let newValue = min(current + 1, quest.goalCount)
        questProgress[quest.id] = newValue
        if !note.isEmpty {
            var notes = questNotes[quest.id] ?? []
            notes.append(note)
            questNotes[quest.id] = notes
        }
        if newValue >= quest.goalCount { questCompleted.insert(quest.id) }
    }

    func removeLastQuestEntry() {
        guard let quest = currentQuest else { return }
        guard questStarted.contains(quest.id), (questProgress[quest.id] ?? 0) > 0 else { return }
        let newValue = max(0, (questProgress[quest.id] ?? 0) - 1)
        questProgress[quest.id] = newValue
        if var notes = questNotes[quest.id], !notes.isEmpty {
            _ = notes.removeLast()
            questNotes[quest.id] = notes
        }
        questCompleted.remove(quest.id)
    }

    func completeQuestIfEligible() {
        guard let quest = currentQuest else { return }
        guard questStarted.contains(quest.id), (questProgress[quest.id] ?? 0) >= quest.goalCount, !questCompleted.contains(quest.id) else { return }
        questCompleted.insert(quest.id)
    }

    func claimQuestReward() {
        guard let quest = currentQuest else { return }
        guard questCompleted.contains(quest.id) else { return }
        xp += quest.xpReward
        // Reset for next cycle for this quest only
        questStarted.remove(quest.id)
        questProgress[quest.id] = 0
        questCompleted.remove(quest.id)
        questNotes[quest.id] = []
    }
}

// MARK: - Views

struct ContentView: View {
    @StateObject private var vm = RiseViewModel()

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(vm)
                .tabItem { Label("Home", systemImage: "house") }

            SkillsListView()
                .environmentObject(vm)
                .tabItem { Label("Skills", systemImage: "leaf") }

            QuestsView()
                .environmentObject(vm)
                .tabItem { Label("Quests", systemImage: "flag") }

            ProgressViewTab()
                .environmentObject(vm)
                .tabItem { Label("Progress", systemImage: "chart.bar") }

            CommunityView()
                .environmentObject(vm)
                .tabItem { Label("Community", systemImage: "person.3") }
        }
    }
}

// MARK: - Home

struct HomeView: View {
    @EnvironmentObject var vm: RiseViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                RiseCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good Morning")
                                .font(RiseDesign.Font.section())

                            Text("Level up a little today")
                                .font(RiseDesign.Font.caption())
                                .foregroundColor(RiseDesign.Colors.mutedText)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("XP \(vm.xp)")
                                .bold()

                            Text("🔥 \(vm.streak) day streak")
                                .font(RiseDesign.Font.caption())
                        }
                    }
                }
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(vm.skills) { skill in
                            NavigationLink(destination: SkillDetailView(skill: skill).environmentObject(vm)) {
                                SkillRow(skill: skill, completedLessonIDs: vm.completedLessons)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                        Text("Rise")
                            .italic()
                            .foregroundStyle(.purple)
                            .font(.system(size: 32, weight: .bold))
                }
            }
        }
    }
}

struct SkillRow: View {
    let skill: Skill
    let completedLessonIDs: Set<UUID>

    private var completedCount: Int {
        let lessonIDs = Set(skill.lessons.map { $0.id })
        return completedLessonIDs.intersection(lessonIDs).count
    }

    var body: some View {
        RiseCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(skill.title)
                        .font(RiseDesign.Font.section())
                        .foregroundColor(RiseDesign.Colors.purple)
                    Spacer()
                    Image(systemName: "bolt.fill")
                        .foregroundColor(RiseDesign.Colors.yellow)
                }

                Text(skill.description)
                    .font(RiseDesign.Font.caption())
                    .foregroundColor(RiseDesign.Colors.mutedText)

                let total = max(1, skill.lessons.count)
                let value = Double(completedCount)
                let totalDouble = Double(total)
                ProgressView(value: value, total: totalDouble)
                    .tint(RiseDesign.Colors.yellow)
            }
        }
    }
}

// MARK: - Skills List

struct SkillsListView: View {
    @EnvironmentObject var vm: RiseViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(vm.skills) { skill in
                    NavigationLink(destination: SkillDetailView(skill: skill).environmentObject(vm)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(skill.title)
                                    .bold()
                                    .foregroundColor(RiseDesign.Colors.purple)
                                Text(skill.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(skill.lessons.count) lessons")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                    }
                    .tint(RiseDesign.Colors.purple)
                }
            }
            .navigationTitle("Skills")
        }
    }
}

// MARK: - Skill Detail & Lesson

struct SkillDetailView: View {
    @EnvironmentObject var vm: RiseViewModel
    let skill: Skill

    var body: some View {
        List {
            ForEach(skill.lessons) { lesson in
                NavigationLink(destination: {
                    switch lesson.title {
                    case "Budget Basics":
                        BudgetBasicsLessonView().environmentObject(vm)
                    case "Reading a Paycheck":
                        ReadingPaycheckLessonView().environmentObject(vm)
                    case "Try: Track a day of spending":
                        TrackSpendingLessonView().environmentObject(vm)
                    case "Pan Basics":
                        PanBasicsLessonView().environmentObject(vm)
                    case "Simple Pasta":
                        SimplePastaLessonView().environmentObject(vm)
                    case "Different Textiles":
                        DifferentTextilesLessonView().environmentObject(vm)
                    case "Choosing Detergents & Settings":
                        ChoosingDetergentsLessonView().environmentObject(vm)
                    default:
                        LessonView(lesson: lesson).environmentObject(vm)
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(lesson.title).bold()
                            Text(lesson.content).font(.caption).foregroundColor(.secondary).lineLimit(1)
                        }
                        Spacer()
                        if vm.completedLessons.contains(lesson.id) {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                        } else {
                            Text("\(lesson.xpReward) XP").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(skill.title)
    }
}

struct LessonView: View {
    @EnvironmentObject var vm: RiseViewModel
    let lesson: Lesson

    var body: some View {
        VStack(spacing: 16) {
            LessonDetailView(lesson: lesson)
            if let choices = lesson.choices {
                ForEach(choices.indices, id: \.self) { idx in
                    // This is a safe unwrap with explicit iteration over choices indices
                    // Here we just show the choice text (for demonstration)
                    Text(choices[idx])
                        .padding(6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                QuizView(lesson: lesson)
            } else {
                RealWorldTaskView(lesson: lesson)
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Quests

struct QuestsView: View {
    @EnvironmentObject var vm: RiseViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Picker to choose a quest
                Picker("Quest", selection: $vm.selectedQuestIndex) {
                    ForEach(vm.quests.indices, id: \.self) { idx in
                        Text(vm.quests[idx].title).tag(idx)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                let quest = vm.quests.indices.contains(vm.selectedQuestIndex) ? vm.quests[vm.selectedQuestIndex] : nil
                let qid = quest?.id
                let progress = qid.flatMap { vm.questProgress[$0] } ?? 0
                let goal = quest?.goalCount ?? 1
                let started = qid.map { vm.questStarted.contains($0) } ?? false
                let completed = qid.map { vm.questCompleted.contains($0) } ?? false

                if let quest = quest {
                    RiseCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weekly Quest")
                                .font(RiseDesign.Font.section())
                            Text(quest.title)
                                .font(.headline)
                                .foregroundColor(RiseDesign.Colors.purple)
                            Text(quest.description)
                                .font(RiseDesign.Font.caption())
                                .foregroundColor(RiseDesign.Colors.mutedText)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Progress: \(progress)/\(goal)")
                                .bold()
                            Spacer()
                            Text("Reward: +\(quest.xpReward) XP")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        ProgressBar(value: Double(goal == 0 ? 0 : progress) / Double(max(goal, 1)))
                            .frame(height: 16)
                    }
                    .padding(.horizontal)

                    // Checklist
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(0..<goal, id: \.self) { index in
                            HStack(spacing: 12) {
                                Image(systemName: index < progress ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(index < progress ? .green : .secondary)
                                Text("Step #\(index + 1)")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Controls
                    VStack(spacing: 12) {
                        if !started {
                            Button {
                                vm.startQuest()
                            } label: {
                                Label("Start Quest", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        } else if completed {
                            Button {
                                vm.claimQuestReward()
                            } label: {
                                Label("Claim Reward (+\(quest.xpReward) XP)", systemImage: "gift.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            HStack {
                                Button {
                                    vm.addQuestEntry()
                                } label: {
                                    Label("Log Step", systemImage: "plus")
                                }
                                .buttonStyle(.borderedProminent)

                                Button(role: .destructive) {
                                    vm.removeLastQuestEntry()
                                } label: {
                                    Label("Undo", systemImage: "arrow.uturn.backward")
                                }
                                .buttonStyle(.bordered)
                            }

                            Button {
                                vm.completeQuestIfEligible()
                            } label: {
                                Label("Mark Complete", systemImage: "checkmark.seal")
                            }
                            .buttonStyle(.bordered)
                            .disabled(progress < goal)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Quests")
        }
    }
}

// MARK: - Progress

struct ProgressViewTab: View {
    @EnvironmentObject var vm: RiseViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("XP: \(vm.xp)").font(.largeTitle).bold()
                ProgressBar(value: Double(vm.xp % 500) / 500.0)
                    .frame(height: 16)
                    .padding()

                List {
                    Section("Completed Lessons") {
                        ForEach(Array(vm.completedLessons), id: \.self) { id in
                            Text("Lesson: \(id.uuidString.prefix(6))...")
                        }
                    }
                    Section("Badges") {
                        if vm.xp > 0 { Text("First Steps Badge") }
                        if vm.xp > 100 { Text("Rising Novice") }
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }
}

struct ProgressBar: View {
    var value: Double // 0..1
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(height: 12)
                    .opacity(0.2)
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: max(0, geo.size.width * CGFloat(value)), height: 12)
                    .animation(.easeInOut, value: value)
            }
        }
        .frame(height: 12)
    }
}

// MARK: - Community

struct CommunityView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Rising Circles")
                Text("Tips & Tricks: How I started budgeting")
                Text("Ask: How do I pick renter's insurance?")
            }
            .navigationTitle("Community")
        }
    }
}

// MARK: - Preview

struct RisePrototype_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


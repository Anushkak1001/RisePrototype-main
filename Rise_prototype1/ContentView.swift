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
    var id: UUID { UUID(uuidString: title.hashString()) ?? UUID() }
    let title: String
    let content: String
    let choices: [String]?
    let answerIndex: Int?
    let xpReward: Int
}

extension String {
    func hashString() -> String {
        let hash = self.hashValue
        return String(format: "%08X-%04X-%04X-%04X-%012X",
                      (hash >> 32) & 0xFFFFFFFF,
                      (hash >> 16) & 0xFFFF,
                      hash & 0xFFFF,
                      (hash >> 48) & 0xFFFF,
                      hash & 0xFFFFFFFFFFFF)
    }
}

struct Quest: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let goalCount: Int
    let xpReward: Int
}

struct XPLog: Identifiable {
    let id = UUID()
    let amount: Int
    let source: String
    let date: Date
}

// MARK: - ViewModel

final class RiseViewModel: ObservableObject {
    @Published var xp: Int = 0
    @Published var streak: Int = 0
    @Published var skills: [Skill] = []
    @Published var completedLessons: Set<UUID> = []
    @Published var xpLogs: [XPLog] = []

    // QUEST SYSTEM
    @Published var questPool: [Quest] = [
        Quest(title: "Cook 3 meals", description: "Make 3 meals at home", goalCount: 3, xpReward: 50),
        Quest(title: "Budget check", description: "Track expenses twice", goalCount: 2, xpReward: 40),
        Quest(title: "Laundry day", description: "Do 2 loads", goalCount: 2, xpReward: 45),
        Quest(title: "Drink water", description: "Drink 5 glasses", goalCount: 5, xpReward: 20),
        Quest(title: "Walk 5k steps", description: "Stay active today", goalCount: 1, xpReward: 30)
    ]

    @Published var activeQuests: [Quest] = []
    @Published var lastQuestRefresh: Date = Date()

    @Published var questProgress: [UUID: Int] = [:]
    @Published var questStarted: Set<UUID> = []
    @Published var questCompleted: Set<UUID> = []

    init() {
        loadSampleData()
        refreshQuestsIfNeeded()
    }

    // MARK: - DATA
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

    // MARK: - XP
    func addXP(amount: Int, source: String) {
        xp += amount
        xpLogs.append(XPLog(amount: amount, source: source, date: Date()))
    }

    func completeLesson(_ lesson: Lesson) {
        guard !completedLessons.contains(lesson.id) else { return }
        completedLessons.insert(lesson.id)
        addXP(amount: lesson.xpReward, source: lesson.title)
    }

    // MARK: - QUEST ROTATION
    func refreshQuestsIfNeeded() {
        let days = Calendar.current.dateComponents([.day], from: lastQuestRefresh, to: Date()).day ?? 0

        if days >= 3 || activeQuests.isEmpty {
            activeQuests = Array(questPool.shuffled().prefix(2))
            lastQuestRefresh = Date()
        }
    }

    // MARK: - QUEST LOGIC
    func startQuest(_ quest: Quest) {
        questStarted.insert(quest.id)
        questProgress[quest.id] = 0
        questCompleted.remove(quest.id)
    }

    func addQuestEntry(_ quest: Quest) {
        guard questStarted.contains(quest.id) else { return }

        let newValue = min((questProgress[quest.id] ?? 0) + 1, quest.goalCount)
        questProgress[quest.id] = newValue

        if newValue >= quest.goalCount {
            questCompleted.insert(quest.id)
        }
    }

    func removeLastQuestEntry(_ quest: Quest) {
        let current = questProgress[quest.id] ?? 0
        questProgress[quest.id] = max(0, current - 1)
        questCompleted.remove(quest.id)
    }

    func claimQuestReward(_ quest: Quest) {
        guard questCompleted.contains(quest.id) else { return }

        addXP(amount: quest.xpReward, source: quest.title)

        questStarted.remove(quest.id)
        questProgress[quest.id] = 0
        questCompleted.remove(quest.id)
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
                    Text("Rise 🚀")
                        .italic()
                        .foregroundStyle(LinearGradient(colors: [.purple, .pink, .blue], startPoint: .leading, endPoint: .trailing))
                        .font(.system(size: 34, weight: .heavy))
                        .shadow(color: .purple.opacity(0.6), radius: 4, x: 2, y: 2)
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
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(vm.activeQuests) { quest in
                        let progress = vm.questProgress[quest.id] ?? 0
                        let started = vm.questStarted.contains(quest.id)
                        let completed = vm.questCompleted.contains(quest.id)

                        RiseCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(quest.title)
                                    .font(.headline)

                                Text(quest.description)
                                    .font(.caption)

                                Text("Progress: \(progress)/\(quest.goalCount)")
                            }

                            ProgressBar(value: Double(progress) / Double(max(quest.goalCount, 1)))

                            if !started {
                                Button("Start") {
                                    vm.startQuest(quest)
                                }
                            } else if completed {
                                Button("Claim XP") {
                                    vm.claimQuestReward(quest)
                                }
                            } else {
                                HStack {
                                    Button("+") {
                                        vm.addQuestEntry(quest)
                                    }
                                    Button("-") {
                                        vm.removeLastQuestEntry(quest)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
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
                        // Flatten all lessons from all skills
                        let allLessons = vm.skills.flatMap { $0.lessons }
                        
                        ForEach(Array(vm.completedLessons), id: \.self) { id in
                            if let lesson = allLessons.first(where: { $0.id == id }) {
                                Text(lesson.title)
                            } else {
                                Text("Unknown Lesson")
                            }
                        }
                    }
                    Section("XP History") {
                        ForEach(vm.xpLogs.reversed()) { log in
                            VStack(alignment: .leading) {
                                Text("+\(log.amount) XP from \(log.source)")
                                    .font(.caption)
                                Text(log.date, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
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
import SwiftUI

// Post model
struct Post: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let website: String?   // optional link
}

struct CommunityView: View {

    // Sample posts
    let posts = [
        Post(title: "How I started budgeting", content: "I began by tracking every expense...", website: nil),
        Post(title: "How do I pick renter's insurance?", content: "Look for coverage limits...", website: "www.amazon.com")
    ]

    var body: some View {
        NavigationView {
            List {
                // Circles section
                Section(header: Text("Circles")) {
                    NavigationLink(destination: CircleDetailView()) {
                        Label("Rising Circles", systemImage: "person.3.fill")
                    }
                }

                // Discussions section
                Section(header: Text("Discussions")) {

                    ForEach(posts) { post in
                        NavigationLink(
                            destination: PostDetail(
                                title: post.title,
                                content: post.content,
                                website: post.website
                            )
                        ) {
                            Text(post.title)
                        }
                    }

                }
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


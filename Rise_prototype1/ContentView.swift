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

    var isQuiz: Bool { choices != nil && answerIndex != nil }
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
                   content: "Overview: A simple way to start is the 50/30/20 guideline. About 50% of take-home goes to needs (housing, groceries, utilities, transport), 30% to wants (eating out, entertainment, subscriptions), and 20% to savings or debt payoff. This is a starting point—adjust to your situation.\n\nQuestion: If you're following 50/30/20, which allocation best matches 'needs' like rent and groceries?",
                   choices: ["Needs ~50%, Wants ~30%, Savings/Debt ~20%","Needs ~60%, Wants ~10%, Savings/Debt ~30%","Needs ~30%, Wants ~40%, Savings/Debt ~30%"],
                   answerIndex: 0,
                   xpReward: 20),
            Lesson(title: "Reading a Paycheck",
                   content: "Overview: Your gross pay is what you earn before deductions. Net pay (take-home) is after taxes and other deductions like benefits and retirement contributions. Always check your pay stub to understand where money goes.\n\nQuestion: If your gross pay is $2,200 and you have taxes and deductions, which amount best represents your net (take-home) pay?",
                   choices: ["$1,800","$2,200","$1,600"],
                   answerIndex: 2,
                   xpReward: 15),
            Lesson(title: "Needs vs Wants",
                   content: "Overview: Needs are essentials that keep you safe and able to work (housing, utilities, basic food, transport). Wants are flexible and can be reduced (streaming, dining out, concerts).\n\nQuestion: Which of the following is typically a 'need'?",
                   choices: ["Streaming subscription","Groceries","Concert tickets"],
                   answerIndex: 1,
                   xpReward: 10),
            Lesson(title: "Emergency Fund 101",
                   content: "Overview: An emergency fund protects you from surprise bills. Start with a starter fund of around $500, then aim for 3–6 months of essential expenses. Keep it in a high-yield savings account for safety and access.\n\nAction: Review your monthly essentials and set a starter goal you can reach this month.",
                   choices: nil,
                   answerIndex: nil,
                   xpReward: 20),
            Lesson(title: "Try: Track a day of spending",
                   content: "Overview: Awareness is step one. Track every purchase for a day (notes app or spreadsheet). Tag each as need or want.\n\nAction: At the end of the day, total your 'wants' and identify one small change for tomorrow.",
                   choices: nil,
                   answerIndex: nil,
                   xpReward: 25)
        ]

        let cookingLessons = [
            Lesson(title: "Pan Basics",
                   content: "Overview: Nonstick pans perform best on low–medium heat. Preheat gently, add a little oil, and avoid metal utensils to preserve the coating.\n\nQuestion: Which heat level is generally best for nonstick cooking?",
                   choices: ["High heat always","Low–medium","Medium-high then low"],
                   answerIndex: 1,
                   xpReward: 10),
            Lesson(title: "Knife Safety",
                   content: "Overview: Use a claw grip to tuck fingertips, keep knives sharp, cut on a stable board, and pay attention to your non-dominant hand.\n\nQuestion: Which grip helps protect your fingers while chopping?",
                   choices: ["Flat palm","Claw grip","Open fingers"],
                   answerIndex: 1,
                   xpReward: 10),
            Lesson(title: "Simple Pasta",
                   content: "Overview: Salt your water until it tastes like the sea, cook to al dente, and reserve a cup of pasta water. Emulsify pasta water with oil or butter to create a silky sauce.\n\nAction: Try making a simple garlic and olive oil pasta, using a splash of pasta water to bring it together.",
                   choices: nil,
                   answerIndex: nil,
                   xpReward: 20),
            Lesson(title: "Meal Prep Basics",
                   content: "Overview: Choose a protein, a grain, and two veggies. Batch-cook, portion into containers, and label with dates for quick, healthy meals.\n\nAction: Plan three balanced meals for the week and write a short shopping list.",
                   choices: nil,
                   answerIndex: nil,
                   xpReward: 20)
        ]

        let laundryLessons = [
            Lesson(title: "Different Textiles",
                   content: "Overview: Delicates prefer cold water and gentle cycles. Turn garments inside out and use mesh bags when needed to reduce abrasion.\n\nQuestion: For delicates, which setting is most appropriate?",
                   choices: ["Hot, heavy","Cold, gentle","Warm, normal"],
                   answerIndex: 1,
                   xpReward: 10),
            Lesson(title: "Choosing Detergents & Settings",
                   content: "Overview: Use HE (high-efficiency) detergent for modern washers and measure according to load size and soil level—more suds doesn't mean cleaner. For lightly soiled or bright colors, prefer cold water to preserve fabric and save energy. Warm helps dissolve detergent and handle moderate soil. Hot is best for whites, towels, and heavily soiled items (if fabric allows). Always follow the garment care label first.\n\nAction: Check one item's care label and set temperature and cycle (gentle/normal/heavy) to match the fabric and soil level.",
                   choices: nil,
                   answerIndex: nil,
                   xpReward: 20),
            Lesson(title: "Stain Removal Basics",
                   content: "Overview: Blot, don't rub. Treat stains ASAP, test on a hidden seam, then wash per fabric label. Heat can set stains, so avoid the dryer until it's gone.\n\nQuestion: What's the safer approach for fresh stains?",
                   choices: ["Rub vigorously","Blot and pre-treat","Ignore until laundry day"],
                   answerIndex: 1,
                   xpReward: 15)
        ]

        let housingLessons = [
            Lesson(title: "Lease Basics",
                   content: "Overview: Read for term, rent increases, fees, and repair responsibilities. Ask questions before signing, and keep a copy for records.\n\nQuestion: Which of the following can limit how much your rent can increase?",
                   choices: ["Early termination fee","Rent control / cap","Late fee"],
                   answerIndex: 1,
                   xpReward: 15),
            Lesson(title: "Move-in Checklist",
                   content: "Overview: Photograph every room, test smoke detectors and appliances, note meter readings, and submit a checklist to your landlord to document condition.\n\nAction: Create a simple checklist for your next move or apartment inspection.",
                   choices: nil,
                   answerIndex: nil,
                   xpReward: 20),
            Lesson(title: "Renter's Insurance",
                   content: "Overview: Renter's insurance covers your belongings and liability. Compare coverage limits and deductibles. Add riders for high-value items.\n\nQuestion: What does renter's insurance primarily protect?",
                   choices: ["The building structure","Your personal belongings and liability","Landlord's property"],
                   answerIndex: 1,
                   xpReward: 15)
        ]

        let transportationLessons = [
            Lesson(title: "Public Transit 101",
                   content: "Overview: Plan your route, load your card, and check schedules or live updates. Offer priority seating and be mindful of exits and personal space.\n\nAction: Look up your local transit app and save your common route.",
                   choices: nil,
                   answerIndex: nil,
                   xpReward: 15),
            Lesson(title: "Bike Safety",
                   content: "Overview: Use lights at night, signal turns, ride with traffic, and wear a properly fitted helmet.\n\nQuestion: Which behavior improves safety and visibility?",
                   choices: ["Ride against traffic","No lights at night","Use hand signals and lights"],
                   answerIndex: 2,
                   xpReward: 10),
            Lesson(title: "Car Costs",
                   content: "Overview: Budget for fuel, insurance, maintenance, registration, and parking. Track total cost of ownership to avoid surprises.\n\nAction: List all monthly car-related costs you can think of and estimate a total.",
                   choices: nil,
                   answerIndex: nil,
                   xpReward: 20)
        ]

        let digitalHygieneLessons = [
            Lesson(title: "Password Hygiene",
                   content: "Overview: Use a password manager and long, unique passphrases. Avoid reuse and enable autofill for convenience and security.\n\nQuestion: Which option is the strongest password approach?",
                   choices: ["petname123","Summer2024","Random passphrase with symbols"],
                   answerIndex: 2,
                   xpReward: 10),
            Lesson(title: "Two-Factor Setup",
                   content: "Overview: Turn on 2FA for email, banking, and social apps. Prefer an authenticator app; keep backup codes somewhere safe.\n\nAction: Enable 2FA on one important account today and store backup codes securely.",
                   choices: nil,
                   answerIndex: nil,
                   xpReward: 20),
            Lesson(title: "Phishing Spotting",
                   content: "Overview: Check the sender address, hover links to preview, and be skeptical of urgency. When in doubt, go directly to the site or app.\n\nQuestion: What's a safer response to a suspicious email?",
                   choices: ["Click to verify immediately","Reply with your password","Inspect sender and links"],
                   answerIndex: 2,
                   xpReward: 15)
        ]

        skills = [
            Skill(title: "Money & Finance", description: "Budgeting, saving, basic taxes.", xp: 0, lessons: financeLessons),
            Skill(title: "Food & Health", description: "Cooking, grocery planning, nutrition.", xp: 0, lessons: cookingLessons),
            Skill(title: "Laundry", description: "Washing, folding, and caring for clothes.", xp: 0, lessons: laundryLessons),
            Skill(title: "Housing & Rent", description: "Leases, move-in, and renter protections.", xp: 0, lessons: housingLessons),
            Skill(title: "Transportation", description: "Public transit, biking, and car basics.", xp: 0, lessons: transportationLessons),
            Skill(title: "Digital Hygiene", description: "Passwords, 2FA, and avoiding scams.", xp: 0, lessons: digitalHygieneLessons)
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome")
                        .font(.largeTitle).bold()
                        .foregroundStyle(LinearGradient(colors: [.purple, .pink, .blue], startPoint: .leading, endPoint: .trailing))
                    Text("Pick a skill to grow today. Short lessons, real progress.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .transition(.opacity)
                
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
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Skills List

struct SkillsListView: View {
    @EnvironmentObject var vm: RiseViewModel

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skills Library")
                            .font(.largeTitle).bold()
                            .foregroundStyle(LinearGradient(colors: [.purple, .pink, .blue], startPoint: .leading, endPoint: .trailing))
                        Text("Explore modules and track your growth.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
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
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(skill.title)
                        .font(.largeTitle).bold()
                        .foregroundStyle(LinearGradient(colors: [.purple, .pink, .blue], startPoint: .leading, endPoint: .trailing))
                    Text(skill.description)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
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
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lesson.title).bold()
                                Text(lesson.isQuiz ? "Quick check to lock in learning" : "Action task to apply skills")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if vm.completedLessons.contains(lesson.id) {
                                Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                            } else {
                                Text("\(lesson.xpReward) XP")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
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
            if lesson.isQuiz, let choices = lesson.choices, let answerIndex = lesson.answerIndex {
                QuizViewGeneric(title: lesson.title, choices: choices, correctIndex: answerIndex) { passed in
                    if passed { vm.completeLesson(lesson) }
                }
            } else {
                RealWorldTaskViewGeneric(title: lesson.title, instructions: lesson.content, xp: lesson.xpReward) {
                    vm.completeLesson(lesson)
                }
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Quests
struct QuestsView: View {
    @EnvironmentObject var vm: RiseViewModel
    @State private var appeared: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Quests")
                            .font(.largeTitle).bold()
                            .foregroundStyle(LinearGradient(colors: [.purple, .pink, .blue], startPoint: .leading, endPoint: .trailing))
                        Text("Complete fun, bite-sized challenges to build real-life skills and earn XP. Come back every few days for fresh quests!")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)

                    ForEach(vm.activeQuests) { quest in
                        let progress = vm.questProgress[quest.id] ?? 0
                        let started = vm.questStarted.contains(quest.id)
                        let completed = vm.questCompleted.contains(quest.id)

                        RiseCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    Text("🎯")
                                        .font(.largeTitle)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(quest.title)
                                            .font(.headline)
                                        Text(quest.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("+\(quest.xpReward) XP")
                                        .font(.caption)
                                        .padding(6)
                                        .background(Capsule().fill(Color.yellow.opacity(0.2)))
                                }

                                ProgressBar(value: Double(progress) / Double(max(quest.goalCount, 1)))
                                    .frame(height: 12)

                                HStack(spacing: 12) {
                                    if !started {
                                        Button {
                                            withAnimation {
                                                vm.startQuest(quest)
                                            }
                                        } label: {
                                            Label("Start", systemImage: "play.circle.fill")
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .scaleEffect(1)
                                        .onTapGesture {
                                            withAnimation {
                                                // scale effect handled by button style animation
                                            }
                                        }
                                    } else if completed {
                                        Button {
                                            withAnimation {
                                                vm.claimQuestReward(quest)
                                            }
                                        } label: {
                                            Label("Claim XP", systemImage: "checkmark.seal.fill")
                                        }
                                        .buttonStyle(.borderedProminent)
                                    } else {
                                        Button {
                                            withAnimation {
                                                vm.addQuestEntry(quest)
                                            }
                                        } label: {
                                            Label("+1", systemImage: "plus.circle.fill")
                                        }
                                        .buttonStyle(.bordered)

                                        Button {
                                            withAnimation {
                                                vm.removeLastQuestEntry(quest)
                                            }
                                        } label: {
                                            Label("Undo", systemImage: "arrow.uturn.backward.circle.fill")
                                        }
                                        .buttonStyle(.bordered)
                                    }

                                    Spacer()

                                    Text("\(progress)/\(quest.goalCount)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05 * Double(progress)), value: appeared)
                    }
                }
                .padding()
                .onAppear {
                    appeared = true
                }
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Progress")
                        .font(.largeTitle).bold()
                        .foregroundStyle(LinearGradient(colors: [.purple, .pink, .blue], startPoint: .leading, endPoint: .trailing))
                    Text("Track XP, badges, and completed lessons.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Text("XP: \(vm.xp)").font(.largeTitle).bold()
                ProgressBar(value: Double(vm.xp % 500) / 500.0)
                    .frame(height: 16)
                    .padding()
                    .animation(.easeInOut(duration: 0.4), value: vm.xp)

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
                        if vm.xp >= 0 { Label("First Steps", systemImage: "figure.walk") }
                        if vm.xp >= 100 { Label("Rising Novice", systemImage: "sun.max") }
                        if vm.xp >= 250 { Label("Skill Builder", systemImage: "hammer") }
                        if vm.xp >= 500 { Label("Habit Hero", systemImage: "star.fill") }
                        if vm.xp >= 1000 { Label("Life Pro", systemImage: "crown") }

                        // Skill completion badges
                        ForEach(vm.skills) { skill in
                            let lessonIDs = Set(skill.lessons.map { $0.id })
                            let completed = vm.completedLessons.intersection(lessonIDs).count
                            if completed == skill.lessons.count && skill.lessons.count > 0 {
                                Label("Completed: \(skill.title)", systemImage: "checkmark.seal")
                            }
                        }
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

// FAQ model
struct FAQ: Identifiable, Hashable {
    let id = UUID()
    var question: String
    var answer: String
}

struct CommunityView: View {
    @State private var faqs: [FAQ] = [
        FAQ(question: "How do I start budgeting?", answer: "Begin by tracking every expense for a week. Categorize into needs and wants, then set a simple 50/30/20 target and adjust to your reality."),
        FAQ(question: "What is a good emergency fund?", answer: "Start with $500 as a buffer. Build toward 3–6 months of essential expenses in a high-yield savings account."),
        FAQ(question: "How do I choose renter's insurance?", answer: "Compare coverage limits and deductibles. Make sure it covers your belongings and liability. Add riders for high-value items if needed."),
        FAQ(question: "Any tips for meal prep?", answer: "Pick a protein, a grain, and two veggies. Batch-cook on one day, portion into containers, and label with dates."),
        FAQ(question: "How can I improve password security?", answer: "Use a password manager and long, unique passphrases. Turn on two-factor authentication for critical accounts."),
        FAQ(question: "What are some laundry basics?", answer: "Sort by color and fabric. Use cold water for delicates and a gentle cycle. Pre-treat stains and avoid heat until stains are gone."),
    ]
    @State private var query: String = ""
    @State private var expandedIDs: Set<UUID> = []

    var filtered: [FAQ] {
        guard !query.isEmpty else { return faqs }
        return faqs.filter { $0.question.localizedCaseInsensitiveContains(query) || $0.answer.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Frequently Asked Questions")
                            .font(.largeTitle).bold()
                            .foregroundStyle(LinearGradient(colors: [.purple, .pink, .blue], startPoint: .leading, endPoint: .trailing))
                        Text("Quick answers to common questions from the community.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }

                Section(header: Label("FAQs", systemImage: "questionmark.circle")) {
                    ForEach(filtered, id: \.self) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Text(item.question)
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    if expandedIDs.contains(item.id) { expandedIDs.remove(item.id) } else { expandedIDs.insert(item.id) }
                                }) {
                                    Image(systemName: expandedIDs.contains(item.id) ? "chevron.up.circle.fill" : "chevron.down.circle")
                                }
                                .buttonStyle(.plain)
                            }

                            if expandedIDs.contains(item.id) {
                                Text(item.answer)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .transition(.opacity)
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
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

// MARK: - Reusable Generic Lesson Views
struct QuizViewGeneric: View {
    let title: String
    let choices: [String]
    let correctIndex: Int
    var onSubmit: (_ passed: Bool) -> Void

    @State private var selectedIndex: Int? = nil
    @State private var showResult: Bool = false
    @State private var passed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(choices.indices, id: \.self) { idx in
                Button(action: { selectedIndex = idx }) {
                    HStack {
                        Text(choices[idx])
                        Spacer()
                        if selectedIndex == idx {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                }
            }
            Button("Submit") {
                guard let sel = selectedIndex else { return }
                passed = (sel == correctIndex)
                showResult = true
                onSubmit(passed)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedIndex == nil)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: title)
        .alert(isPresented: $showResult) {
            Alert(title: Text(passed ? "Nice!" : "Not quite"),
                  message: Text(passed ? "You picked the correct answer." : "Try reviewing the lesson again."),
                  dismissButton: .default(Text("OK")))
        }
    }
}

struct RealWorldTaskViewGeneric: View {
    let title: String
    let instructions: String
    let xp: Int
    var onComplete: () -> Void

    @State private var confirmed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Action Task")
                .font(.headline)
            Text("Follow these steps, then mark complete to earn XP.")
                .font(.caption)
                .foregroundColor(.secondary)
            Button(action: {
                confirmed = true
                onComplete()
            }) {
                HStack {
                    Image(systemName: "checkmark.seal")
                    Text("Mark Complete (+\(xp) XP)")
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .alert(isPresented: $confirmed) {
                Alert(title: Text("Great job!"), message: Text("You earned \(xp) XP"), dismissButton: .default(Text("OK")))
            }
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: title)
    }
}


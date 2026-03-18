// A dedicated view for the "Budget Basics" lesson, with quiz UI and state.
import SwiftUI

struct BudgetBasicsLessonView: View {
    @EnvironmentObject var vm: RiseViewModel
    @State private var selectedIndex: Int? = nil
    @State private var showResult: Bool = false
    @State private var correct: Bool = false

    private let lesson = Lesson(
        title: "Budget Basics",
        content: "You have $1,200 and four categories: Rent, Food, Transport, Savings. Allocate percentages.",
        choices: ["Rent 40%, Food 20%","Rent 60%, Food 10%","Rent 30%, Food 40%"],
        answerIndex: 0,
        xpReward: 20
    )

    var body: some View {
        VStack(spacing: 16) {
            Text(lesson.title).font(.title2).bold()
            ScrollView { Text(lesson.content).padding() }
            if let choices = lesson.choices {
                ForEach(choices.indices, id: \.self) { idx in
                    Button(action: { selectedIndex = idx }) {
                        HStack {
                            Text(choices[idx])
                            Spacer()
                            if selectedIndex == idx {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)).shadow(radius: 1))
                    }
                }
            }
            Button(action: {
                guard let sel = selectedIndex else { return }
                correct = (sel == lesson.answerIndex)
                showResult = true
            }, label: {
                Text("Submit")
            })
            .buttonStyle(.borderedProminent)
            .padding(.top)
            .disabled(selectedIndex == nil || vm.completedLessons.contains(lesson.id))
            Spacer()
        }
        .padding()
        .alert(isPresented: $showResult) {
            Alert(title: Text(correct ? "Nice!" : "Not quite"),
                  message: Text(correct ? "You earned \(lesson.xpReward) XP" : "Try reviewing the lesson again."),
                  dismissButton: .default(Text("OK")))
        }
    }
}

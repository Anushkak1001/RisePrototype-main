// A dedicated view for the "Reading a Paycheck" lesson, with quiz UI and state.
import SwiftUI

struct ReadingPaycheckLessonView: View {
    @EnvironmentObject var vm: RiseViewModel
    @State private var selectedIndex: Int? = nil
    @State private var showResult: Bool = false
    @State private var correct: Bool = false

    private let lesson = Lesson(
        title: "Reading a Paycheck",
        content: "Spot the take-home pay after taxes and deductions.",
        choices: ["$1,800","$2,200","$1,600"],
        answerIndex: 2,
        xpReward: 15
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
            Button("Submit") {
                guard let sel = selectedIndex else { return }
                correct = vm.answerMultipleChoice(lesson, selectedIndex: sel)
                showResult = true
            }
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


// A dedicated view for the "Pan Basics" cooking lesson (multiple choice quiz).
import SwiftUI

struct PanBasicsLessonView: View {
    @State private var selectedIndex: Int? = nil
    @State private var showResult: Bool = false
    @State private var correct: Bool = false

    private let lesson = Lesson(
        title: "Pan Basics",
        content: "What temperature range is good for a nonstick pan?",
        choices: ["High heat always", "Low-medium", "Medium-high then low"],
        answerIndex: 1,
        xpReward: 10
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
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.regularMaterial)
                                .shadow(radius: 1)
                        )
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
                .disabled(selectedIndex == nil)
            }
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


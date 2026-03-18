import SwiftUI

struct QuizView: View {
    let lesson: Lesson
    @EnvironmentObject var vm: RiseViewModel
    @State private var selectedIndex: Int? = nil
    @State private var showResult: Bool = false
    @State private var correct: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            if let choices = lesson.choices {
                ForEach(choices.indices, id: \.self) { idx in
                    Button(action: {
                        selectedIndex = idx
                    }) {
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
            }
        }
        .padding()
        .alert(isPresented: $showResult) {
            Alert(title: Text(correct ? "Nice!" : "Not quite"),
                  message: Text(correct ? "You earned \(lesson.xpReward) XP" : "Try reviewing the lesson again."),
                  dismissButton: .default(Text("OK")))
        }
    }
}

// Note: This view requires Lesson and RiseViewModel types, so they must remain available (e.g., via ContentView or a models file).

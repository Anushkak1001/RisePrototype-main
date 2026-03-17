// A dedicated view for the "Try: Track a day of spending" lesson, with real-world prompt UI.
import SwiftUI

struct TrackSpendingLessonView: View {
    @EnvironmentObject var vm: RiseViewModel
    @Environment(\.presentationMode) var presentationMode
    private let lesson = Lesson(
        title: "Try: Track a day of spending",
        content: "Go track every purchase you make today and add to app (real-world task).",
        choices: nil,
        answerIndex: nil,
        xpReward: 25
    )
    var body: some View {
        VStack(spacing: 16) {
            Text(lesson.title).font(.title2).bold()
            ScrollView { Text(lesson.content).padding() }
            Text("This lesson asks you to complete a real-world task. Tap the button below when you've done it to earn XP.")
                .multilineTextAlignment(.center)
                .padding()
            Button(action: {
                vm.completeLesson(lesson)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text(vm.completedLessons.contains(lesson.id) ? "Completed" : "Mark as Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .disabled(vm.completedLessons.contains(lesson.id))
            Spacer()
        }
        .padding()
    }
}

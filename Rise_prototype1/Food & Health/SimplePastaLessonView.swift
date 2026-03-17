// A dedicated view for the "Simple Pasta" cooking lesson (real-world prompt).
import SwiftUI

struct SimplePastaLessonView: View {
    @EnvironmentObject var vm: RiseViewModel
    @Environment(\.presentationMode) var presentationMode
    private let lesson = Lesson(
        title: "Simple Pasta",
        content: "Steps to cook al dente pasta and make a quick sauce.",
        choices: nil,
        answerIndex: nil,
        xpReward: 20
    )
    var body: some View {
        VStack(spacing: 16) {
            Text(lesson.title).font(.title2).bold()
            ScrollView { Text(lesson.content).padding() }
            Text("This lesson asks you to cook pasta following the instructions. Tap the button below when you've done it to earn XP.")
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

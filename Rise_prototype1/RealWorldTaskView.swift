import SwiftUI

struct RealWorldTaskView: View {
    let lesson: Lesson
    @EnvironmentObject var vm: RiseViewModel
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack(spacing: 12) {
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
        }
    }
}

// Note: This view requires Lesson and RiseViewModel types, so they must remain available (e.g., via ContentView or a models file).

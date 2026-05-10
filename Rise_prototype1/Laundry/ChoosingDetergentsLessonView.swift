// Laundry lesson: "Choosing Detergents & Settings" (real-world prompt)
import SwiftUI

struct ChoosingDetergentsLessonView: View {
    @EnvironmentObject var vm: RiseViewModel
    @Environment(\.presentationMode) var presentationMode
    private let lesson = Lesson(
        title: "Choosing Detergents & Settings",
        content: "Overview: Use HE (high-efficiency) detergent for modern washers and measure according to load size and soil level—more suds doesn't mean cleaner. For lightly soiled or bright colors, prefer cold water to preserve fabric and save energy. Warm helps dissolve detergent and handle moderate soil. Hot is best for whites, towels, and heavily soiled items (if fabric allows). Always follow the garment care label first.\n\nAction: Check one item's care label and set temperature and cycle (gentle/normal/heavy) to match the fabric and soil level.",
        choices: nil,
        answerIndex: nil,
        xpReward: 20
    )
    var body: some View {
        VStack(spacing: 16) {
            Text(lesson.title).font(.title2).bold()
            ScrollView { Text(lesson.content).padding() }
            Text("This lesson guides you to pick the right detergent amount and washer settings for your clothes. Tap the button below when you've done it to earn XP.")
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

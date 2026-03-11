import SwiftUI

struct LessonDetailView: View {
    let lesson: Lesson
    var body: some View {
        VStack(spacing: 8) {
            Text(lesson.title).font(.title2).bold()
            ScrollView {
                Text(lesson.content).padding()
            }
        }
    }
}

// Make sure to import the Lesson model via ContentView, or move the Lesson model to a separate file if needed.

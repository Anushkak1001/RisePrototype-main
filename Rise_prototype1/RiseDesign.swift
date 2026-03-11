//
//  RiseDesign.swift
//  Rise_prototype1
//
//  Created by Anushka Karthikeyan on 1/28/26.
//
import SwiftUI

// MARK: - Rise Design System

enum RiseDesign {

    // MARK: Colors
    enum Colors {
        static let purple = Color(red: 0.45, green: 0.25, blue: 0.85)
        static let purpleDark = Color(red: 0.32, green: 0.18, blue: 0.65)
        static let yellow = Color(red: 1.0, green: 0.85, blue: 0.2)
        static let background = Color(.systemBackground)
        static let card = Color(.secondarySystemBackground)
        static let mutedText = Color.secondary
    }

    // MARK: Gradients
    enum Gradients {
        static let primary = LinearGradient(
            colors: [Colors.purple, Colors.purpleDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let reward = LinearGradient(
            colors: [Colors.yellow, Colors.yellow.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: Typography
    enum Font {
        static func title() -> SwiftUI.Font {
            .system(size: 34, weight: .bold, design: .rounded)
        }

        static func section() -> SwiftUI.Font {
            .system(size: 20, weight: .semibold, design: .rounded)
        }

        static func body() -> SwiftUI.Font {
            .system(size: 16, weight: .regular, design: .rounded)
        }

        static func caption() -> SwiftUI.Font {
            .system(size: 12, weight: .medium, design: .rounded)
        }
    }

    // MARK: Layout
    enum Layout {
        static let cornerRadius: CGFloat = 18
        static let padding: CGFloat = 16
        static let shadowRadius: CGFloat = 6
    }
}
struct RiseCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(RiseDesign.Layout.padding)
            .background(
                RoundedRectangle(cornerRadius: RiseDesign.Layout.cornerRadius)
                    .fill(RiseDesign.Colors.card)
            )
            .shadow(radius: RiseDesign.Layout.shadowRadius)
    }
}
struct XPBar: View {
    let current: Int
    let max: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: Double(current), total: Double(max))
                .tint(RiseDesign.Colors.yellow)
                .scaleEffect(x: 1, y: 2, anchor: .center)

            Text("\(current) / \(max) XP")
                .font(RiseDesign.Font.caption())
                .foregroundColor(RiseDesign.Colors.mutedText)
        }
    }
}
struct RisePrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: RiseDesign.Layout.cornerRadius)
                        .fill(RiseDesign.Colors.yellow)
                )
                .foregroundColor(.black)
        }
    }
}



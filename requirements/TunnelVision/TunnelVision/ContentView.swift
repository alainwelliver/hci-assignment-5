//
//  ContentView.swift
//  TunnelVision
//
//  Started by Alain Welliver on 4/1/26. Completed using AI assistnace with Claude Code's Claude 4.5 Sonnet
//

import SwiftUI

// MARK: - Data Model

enum Direction {
    case straight, bearLeft, bearRight, turnLeft, turnRight, upStairs, downStairs, splitAhead
}

struct NavStep {
    let id: Int
    let direction: Direction
    let label: String
    let estimatedTimeRemaining: String
    let nextTrainArrival: String
    let trainLine: String
    let trainColor: String
}

let navSteps: [NavStep] = [
    NavStep(id: 1, direction: .straight,   label: "Walk Straight",     estimatedTimeRemaining: "~2:43", nextTrainArrival: "4:12", trainLine: "1", trainColor: "#FF3B30"),
    NavStep(id: 2, direction: .bearLeft,   label: "Bear Left",         estimatedTimeRemaining: "~2:15", nextTrainArrival: "3:35", trainLine: "1", trainColor: "#FF3B30"),
    NavStep(id: 3, direction: .splitAhead, label: "Split Ahead",       estimatedTimeRemaining: "~1:45", nextTrainArrival: "3:34", trainLine: "1", trainColor: "#FF3B30"),
    NavStep(id: 4, direction: .straight,   label: "Continue Straight", estimatedTimeRemaining: "~1:10", nextTrainArrival: "3:32", trainLine: "1", trainColor: "#FF3B30"),
    NavStep(id: 5, direction: .upStairs,   label: "Go Up the Stairs",  estimatedTimeRemaining: "~0:30", nextTrainArrival: "2:51", trainLine: "1", trainColor: "#FF3B30"),
]

// MARK: - Color Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Direction Arrow View

struct DirectionArrowView: View {
    let direction: Direction

    private let green = Color(hex: "#17c964")

    var body: some View {
        switch direction {
        case .straight:
            tripleArrows(systemName: "chevron.up")
        case .bearLeft:
            tripleArrows(systemName: "arrow.up.left")
        case .bearRight:
            tripleArrows(systemName: "arrow.up.right")
        case .turnLeft:
            tripleArrows(systemName: "arrow.turn.up.left")
        case .turnRight:
            tripleArrows(systemName: "arrow.turn.up.right")
        case .upStairs:
            stairsArrow(up: true)
        case .downStairs:
            stairsArrow(up: false)
        case .splitAhead:
            splitArrow()
        }
    }

    @ViewBuilder
    private func tripleArrows(systemName: String) -> some View {
        VStack(spacing: -8) {
            Image(systemName: systemName)
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(green)
            Image(systemName: systemName)
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(green.opacity(0.55))
            Image(systemName: systemName)
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(green.opacity(0.25))
        }
    }

    @ViewBuilder
    private func stairsArrow(up: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: up ? "arrow.up" : "arrow.down")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(green)
            Image(systemName: "staircase")
                .font(.system(size: 64, weight: .semibold))
                .foregroundColor(green)
                .scaleEffect(x: 1, y: up ? 1 : -1)
        }
    }

    @ViewBuilder
    private func splitArrow() -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 24) {
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(green)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(green)
            }
            Image(systemName: "arrow.up")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(green.opacity(0.5))
        }
    }
}

// MARK: - Train Arrival Pill

struct TrainArrivalPill: View {
    let step: NavStep

    var body: some View {
        HStack(spacing: 6) {
            Text("Next")
                .font(.system(size: 15))
                .foregroundColor(.primary)
            ZStack {
                Circle()
                    .fill(Color(hex: step.trainColor))
                    .frame(width: 26, height: 26)
                Text(step.trainLine)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            Text("train arriving in \(step.nextTrainArrival) min")
                .font(.system(size: 15))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Nav Button

struct NavButton: View {
    let title: String
    let action: () -> Void
    let filled: Bool

    private let green = Color(hex: "#17c964")

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(filled ? .white : green)
                .background(
                    Capsule()
                        .fill(filled ? green : Color.clear)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(green, lineWidth: 2)
                )
        }
    }
}

// MARK: - Arrival View

struct ArrivalView: View {
    let onStartOver: () -> Void
    private let green = Color(hex: "#17c964")

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(green)
            Text("You've Arrived!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            Spacer()
            Button(action: onStartOver) {
                Text("Start Over")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Capsule().fill(green))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var currentIndex = 0
    @State private var arrived = false

    private let green = Color(hex: "#17c964")
    private var step: NavStep { navSteps[currentIndex] }
    private var isFirst: Bool { currentIndex == 0 }
    private var isLast: Bool { currentIndex == navSteps.count - 1 }

    var body: some View {
        if arrived {
            ArrivalView {
                currentIndex = 0
                arrived = false
            }
        } else {
            VStack(spacing: 0) {
                // Top bar
                TrainArrivalPill(step: step)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Spacer()

                // Direction arrows
                DirectionArrowView(direction: step.direction)
                    .frame(height: 200)
                    .animation(.easeInOut(duration: 0.25), value: currentIndex)

                Spacer().frame(height: 24)

                // Direction label
                Text(step.label)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Spacer().frame(height: 12)

                // Estimated time remaining
                Text("Estimated Time Remaining: \(step.estimatedTimeRemaining)")
                    .font(.system(size: 14))
                    .foregroundColor(green)

                Spacer().frame(height: 8)

                // Step indicator
                Text("Step \(currentIndex + 1) of \(navSteps.count)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Spacer()

                // Navigation buttons
                HStack(spacing: 16) {
                    NavButton(title: "< Back", action: {
                        if !isFirst { currentIndex -= 1 }
                    }, filled: false)
                    .opacity(isFirst ? 0 : 1)
                    .disabled(isFirst)

                    NavButton(title: isLast ? "Arrived" : "Next >", action: {
                        if isLast {
                            arrived = true
                        } else {
                            currentIndex += 1
                        }
                    }, filled: true)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .animation(.easeInOut(duration: 0.2), value: currentIndex)
        }
    }
}

#Preview {
    ContentView()
}

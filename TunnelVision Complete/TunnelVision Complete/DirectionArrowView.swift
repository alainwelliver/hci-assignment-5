// AI Attribution: Generated with Claude Opus 4.6

import SwiftUI

/// Triple-stack direction arrows (matches 2D: three identical glyphs, fading opacity).
/// Use `rotationDegrees` and `stabilizedOffset` for the same live motion as AR mode.
struct DirectionArrowView: View {
    let direction: Direction
    var tint: Color = Color(hex: "#17c964")
    var rotationDegrees: Double = 0
    var stabilizedOffset: CGSize = .zero
    var arrowShadow: Bool = false
    var useFadingStackOpacity: Bool = true

    var body: some View {
        mainContent
            .offset(stabilizedOffset)
            .rotationEffect(.degrees(rotationDegrees))
            .animation(.easeOut(duration: 0.12), value: rotationDegrees)
            .animation(.easeOut(duration: 0.1), value: stabilizedOffset)
    }

    @ViewBuilder
    private var mainContent: some View {
        switch direction {
        case .straight:
            tripleStack(systemName: "chevron.up")
        case .bearLeft:
            tripleStack(systemName: "arrow.up.left")
        case .bearRight:
            tripleStack(systemName: "arrow.up.right")
        case .turnLeft:
            tripleStack(systemName: "arrow.turn.up.left")
        case .turnRight:
            tripleStack(systemName: "arrow.turn.up.right")
        case .upStairs:
            stairsArrow(up: true)
        case .downStairs:
            stairsArrow(up: false)
        case .splitAhead:
            splitArrow()
        }
    }

    @ViewBuilder
    private func tripleStack(systemName: String) -> some View {
        let second = useFadingStackOpacity ? 0.55 : 1.0
        let third = useFadingStackOpacity ? 0.25 : 1.0
        VStack(spacing: -8) {
            tripleLayer(systemName, opacity: 1.0)
            tripleLayer(systemName, opacity: second)
            tripleLayer(systemName, opacity: third)
        }
    }

    @ViewBuilder
    private func tripleLayer(_ systemName: String, opacity: Double) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 72, weight: .bold))
            .foregroundStyle(tint.opacity(opacity))
            .shadow(color: arrowShadow ? tint.opacity(0.45) : .clear, radius: arrowShadow ? 12 : 0)
            .contentTransition(.symbolEffect(.replace))
    }

    @ViewBuilder
    private func stairsArrow(up: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: up ? "arrow.up" : "arrow.down")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(tint)
            Image(systemName: "staircase")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(tint)
                .scaleEffect(x: 1, y: up ? 1 : -1)
        }
    }

    @ViewBuilder
    private func splitArrow() -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 24) {
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(tint)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(tint)
            }
            Image(systemName: "arrow.up")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(tint.opacity(0.5))
        }
    }
}

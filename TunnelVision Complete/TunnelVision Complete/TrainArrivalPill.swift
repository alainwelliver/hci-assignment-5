import SwiftUI

struct TrainArrivalPill: View {
    @EnvironmentObject var transitVM: TransitViewModel

    var body: some View {
        if transitVM.isLoading {
            ProgressView()
                .padding(.vertical, 10)
        } else {
            HStack(spacing: 6) {
                if let nextTrain = transitVM.nextTrains.first {
                    if transitVM.dataSource == .schedule {
                        Text("The next")
                            .font(.system(size: 15))
                            .foregroundColor(.primary)

                        routeBadge(size: 26, fontSize: 13)

                        Text("train is scheduled in \(scheduledMinutes(for: nextTrain)) min")
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                    } else {
                        Text("Next")
                            .font(.system(size: 15))
                            .foregroundColor(.primary)

                        routeBadge(size: 26, fontSize: 13)

                        if nextTrain.isDelayed {
                            Text("delayed · \(nextTrain.timeRemainingString(from: transitVM.currentTime))")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "#f5a524"))
                        } else {
                            Text("train arriving in \(nextTrain.timeRemainingString(from: transitVM.currentTime))")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "#17c964"))
                        }
                    }
                } else {
                    inlineRouteText(transitVM.emptyStateMessage,
                                    font: .system(size: 14),
                                    color: .secondary)
                }
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

    private func scheduledMinutes(for train: Train) -> Int {
        let interval = train.arrivalTime.timeIntervalSince(transitVM.currentTime)
        return max(1, Int((interval / 60).rounded()))
    }

    private func routeBadge(size: CGFloat, fontSize: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "#2185D5"))
                .frame(width: size, height: size)
            Text("L")
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private func inlineRouteText(_ message: String, font: Font, color: Color) -> some View {
        let parts = message.components(separatedBy: " L ")
        if parts.count > 1 {
            Text(parts[0] + " ")
                .font(font)
                .foregroundColor(color)
            routeBadge(size: 26, fontSize: 13)
            Text(" " + parts.dropFirst().joined(separator: " L "))
                .font(font)
                .foregroundColor(color)
        } else {
            Text(message)
                .font(font)
                .foregroundColor(color)
        }
    }
}

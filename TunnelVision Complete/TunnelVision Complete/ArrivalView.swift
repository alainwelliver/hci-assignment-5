// AI Attribution: Generated with Claude Opus 4.6

import SwiftUI

struct ArrivalView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel

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

            if navigationVM.stepCount > 0 {
                Text("\(navigationVM.stepCount) steps taken")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                navigationVM.reset()
            }) {
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
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

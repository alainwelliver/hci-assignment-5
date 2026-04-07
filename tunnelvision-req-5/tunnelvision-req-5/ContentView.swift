import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TransitViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#f4f4f5").ignoresSafeArea()

            VStack {
                if viewModel.isLoading {
                    ProgressView("Fetching MTA Data...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let nextTrain = viewModel.nextTrains.first {
                    
                    //card on top
                    HStack(spacing: 8) {
                        Text("Next")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#6b7280")) // Gray text
                        
                        //the "1" train shown
                        Text(nextTrain.routeName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color(hex: "#ee352e")) // MTA Red
                            .clipShape(Circle())
                        
                        //the countdown test
                        if nextTrain.isDelayed {
                            Text("delayed. arriving in \(nextTrain.timeRemainingString(from: viewModel.currentTime))")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#f5a524")) //iof delayed --> yellow
                        } else {
                            Text("train arriving in \(nextTrain.timeRemainingString(from: viewModel.currentTime))")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#17c964")) 
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "#006FEE").opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.top, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                } else {
                    Text("No upcoming trains.")
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            
        }
        .alert("Train Missed!", isPresented: $viewModel.showMissedAlert) {
            Button("Dismiss", role: .cancel) { }
        } message: {
            Text("The \(viewModel.missedTrainName) train just departed without you.")
        }
        .task {
            await viewModel.loadData()
        }
        .animation(.easeInOut, value: viewModel.nextTrains.count)
    }
}

// alain color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}

#Preview {
    ContentView()
}
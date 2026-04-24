import SwiftUI

struct HelloStylesView: View {
    //labels of colors with codes
    let heroColors: [(name: String, hex: String)] = [
        ("Success", "#17c964"),
        ("Primary", "#006FEE"),
        ("Danger", "#f31260"),
        ("Warning", "#f5a524"),
        ("Default", "#d4d4d8"),
        ("Secondary", "#7828c8")
    ]
    
    //font sizes
    let fontSizes: [CGFloat] = [12, 16, 20, 24]
    
    var body: some View {
        //if content is too much
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                
                Text("Style Guide")
                    .font(.system(size: 32, weight: .bold))
                
                //Color Pallette section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hero UI Colors")
                        .font(.headline)
                    
                    // arange horizontally
                    HStack(spacing: 15) {
                        ForEach(heroColors, id: \.name) { colorItem in
                            VStack {
                                Circle()
                                    .fill(Color(hex: colorItem.hex)) //using Alains Hex decoder
                                    .frame(width: 40, height: 40)
                                    .shadow(radius: 2)
                            }
                        }
                    }
                }
                
                //Typography section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Typography")
                        .font(.headline)
                    
                    ForEach(fontSizes, id: \.self) { size in
                        HStack(spacing: 20) {
                            Text("Regular \(Int(size))px")
                                .font(.system(size: size, weight: .regular))
                            
                            Text("Semi-Bold \(Int(size))px")
                                .font(.system(size: size, weight: .semibold))
                        }
                    }
                }
                
                //Icons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sample Icons")
                        .font(.headline)
                    
                    HStack(spacing: 24) {
                        Image(systemName: "house")
                        Image(systemName: "magnifyingglass")
                        Image(systemName: "bell")
                        Image(systemName: "gearshape")
                        Image(systemName: "person")
                    }
                    .font(.system(size: 24)) // size for icons
                    .foregroundColor(Color(hex: "#006FEE"))
                }
            }
            .padding(24) 
        }
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
    HelloStylesView()
}

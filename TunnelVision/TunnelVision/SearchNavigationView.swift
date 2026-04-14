import SwiftUI

// MARK: - DEMO Mock Data
// =====================================================================

struct Station: Identifiable, Equatable {
    let id = UUID()
    let name: String
}

struct RouteStep: Identifiable {
    let id = UUID()
    let instruction: String
    let subtitle: String?
}

// change these to actual stations
let demoStations = [
    Station(name: "Penn Station - Platform 1"),
    Station(name: "50th Street - Rockefeller Center"),
    Station(name: "Times Square - 42nd St"),
    Station(name: "AGH Lobby"),
    Station(name: "HCI Classroom")
]

// generate timeline based on selection
func generateDemoRoute(from start: String, to destination: String) -> [RouteStep] {
    return [
        RouteStep(instruction: start, subtitle: nil),
        
        // can change this middle transfer step to match your pedometer route
        RouteStep(instruction: "Navigate this transfer", subtitle: "Follow AR arrows \n~15 mins walking distance"),
        
        RouteStep(instruction: destination, subtitle: nil)
    ]
}
// =====================================================================


// MARK: - Main View
struct SearchNavigationView: View {
    
    // hold texts that user types
    @State private var startText = ""
    @State private var destText = ""
    
    // hold confirmed stations
    @State private var startStation: Station? = nil
    @State private var destStation: Station? = nil
    
    // tacks which box is being typed in
    enum FocusField {
        case start
        case destination
    }
    @FocusState private var activeField: FocusField?
    
    var body: some View {
        VStack(spacing: 0) {
            
            // header section of searhc bars
            VStack(alignment: .leading, spacing: 12) {
                
                // from field
                HStack(spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#006FEE"))
                    
                    TextField("Where are you starting?", text: $startText)
                        .focused($activeField, equals: .start)
                        .onChange(of: startText) { _ in
                            // when user edits text, clear confirmed station to force re selection
                            if startStation != nil && startText != startStation?.name {
                                startStation = nil
                            }
                        }
                    
                    if !startText.isEmpty && activeField == .start {
                        Button(action: { startText = ""; startStation = nil }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(activeField == .start ? Color.blue.opacity(0.05) : Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(activeField == .start ? Color(hex: "#006FEE") : Color.gray.opacity(0.3), lineWidth: 1))
                
                // to field
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#f31260"))
                    
                    TextField("Where to?", text: $destText)
                        .focused($activeField, equals: .destination)
                        .onChange(of: destText) { _ in
                            if destStation != nil && destText != destStation?.name {
                                destStation = nil
                            }
                        }
                    
                    if !destText.isEmpty && activeField == .destination {
                        Button(action: { destText = ""; destStation = nil }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(activeField == .destination ? Color.red.opacity(0.05) : Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(activeField == .destination ? Color(hex: "#f31260") : Color.gray.opacity(0.3), lineWidth: 1))
                
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            //content area
            VStack {
                // if text field actie and dont have stations confirmed
                if activeField != nil {
                    searchResultsView
                }
                // if both stations selected and no text box being typed in
                else if let start = startStation, let dest = destStation {
                    routeCardView(start: start.name, dest: dest.name)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                //empty state
                else {
                    Spacer()
                }
            }
            .padding(.top, 10)
            
            Spacer()
            
            //bottom tab bar
            Divider()
            HStack {
                tabIcon(icon: "house", label: "Home", isActive: true)
                Spacer()
                tabIcon(icon: "arrow.triangle.swap", label: "Nav", isActive: false)
                Spacer()
                tabIcon(icon: "gearshape", label: "Settings", isActive: false)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(Color(hex: "#fcfcfc").ignoresSafeArea())
        .animation(.spring(), value: activeField)
        .animation(.spring(), value: startStation)
        .animation(.spring(), value: destStation)
    
        .onAppear {
            activeField = .start
        }
    }
    
    // MARK: - Subviews
    
    //reusable dropdown list that changes based on which text field is active
    private var searchResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                //determine which text to filter by based on the active field
                let query = activeField == .start ? startText : destText
                let results = demoStations.filter { query.isEmpty || $0.name.lowercased().contains(query.lowercased()) }
                
                if results.isEmpty {
                    Text("No stations found.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(results) { station in
                        Button(action: {
                            if activeField == .start {
                                startText = station.name
                                startStation = station
                                //jump directly to the destination field
                                activeField = .destination
                            } else {
                                destText = station.name
                                destStation = station
                                //hide keyboard to show the route card
                                activeField = nil
                            }
                        }) {
                            HStack {
                                Image(systemName: activeField == .start ? "circle.fill" : "mappin.and.ellipse")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 10))
                                Text(station.name)
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                        }
                        Divider().padding(.horizontal)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    //the visual timeline
    private func routeCardView(start: String, dest: String) -> some View {
        let currentRoute = generateDemoRoute(from: start, to: dest)
        
        return VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(currentRoute.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 0) {
                            Circle()
                                .stroke(Color(hex: "#f31260"), lineWidth: 2)
                                .background(Circle().fill(Color.white))
                                .frame(width: 16, height: 16)
                            
                            if index < currentRoute.count - 1 {
                                Rectangle()
                                    .fill(Color(hex: "#f31260"))
                                    .frame(width: 2)
                                    .frame(minHeight: 40)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if index == 1 {
                                Text(step.instruction)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "#006FEE"))
                                    .cornerRadius(12)
                            } else {
                                Text(step.instruction)
                                    .font(.system(size: 14, weight: .bold))
                            }
                            
                            if let subtitle = step.subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.top, -2)
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            
            Button(action: {
                print("Start AR Navigation tapped! Route: \(start) -> \(dest)")
            }) {
                HStack {
                    Image(systemName: "map")
                    Text("Start Transfer Navigation")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(Color(hex: "#17c964"))
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#17c964"), lineWidth: 2))
            }
        }
        .padding(.horizontal)
    }
    
    private func tabIcon(icon: String, label: String, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(isActive ? .black : .gray)
    }
}

#Preview {
    SearchNavigationView()
}

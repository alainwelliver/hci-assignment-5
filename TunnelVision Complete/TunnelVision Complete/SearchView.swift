// AI Attribution: Generated with Claude Opus 4.6

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel

    @State private var startText = ""
    @State private var destText = ""

    @State private var startStation: Station? = nil
    @State private var destStation: Station? = nil

    @State private var selectedRouteOption: RouteOption? = nil

    enum FocusField {
        case start
        case destination
    }
    @FocusState private var activeField: FocusField?

    private let green = Color(hex: "#17c964")
    private let blue = Color(hex: "#006FEE")
    private let red = Color(hex: "#f31260")

    var body: some View {
        VStack(spacing: 0) {

            // Back to landing
            HStack {
                Button(action: { navigationVM.backToLanding() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Home")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#555566"))
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Header: search bars
            VStack(alignment: .leading, spacing: 12) {

                // From field
                HStack(spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(blue)

                    TextField("Where are you starting?", text: $startText, prompt: Text("Where are you starting?").foregroundColor(.gray))
                        .foregroundColor(.black)
                        .focused($activeField, equals: .start)
                        .onChange(of: startText) { _ in
                            if startStation != nil && startText != startStation?.name {
                                startStation = nil
                                selectedRouteOption = nil
                            }
                        }

                    if !startText.isEmpty && activeField == .start {
                        Button(action: { startText = ""; startStation = nil; selectedRouteOption = nil }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(activeField == .start ? Color.blue.opacity(0.05) : Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(activeField == .start ? blue : Color.gray.opacity(0.3), lineWidth: 1))

                // To field
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12))
                        .foregroundColor(red)

                    TextField("Where to?", text: $destText, prompt: Text("Where to?").foregroundColor(.gray))
                        .foregroundColor(.black)
                        .focused($activeField, equals: .destination)
                        .onChange(of: destText) { _ in
                            if destStation != nil && destText != destStation?.name {
                                destStation = nil
                                selectedRouteOption = nil
                            }
                        }

                    if !destText.isEmpty && activeField == .destination {
                        Button(action: { destText = ""; destStation = nil; selectedRouteOption = nil }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(activeField == .destination ? Color.red.opacity(0.05) : Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(activeField == .destination ? red : Color.gray.opacity(0.3), lineWidth: 1))
            }
            .padding(.horizontal)
            .padding(.top, 20)

            // Content area
            VStack {
                if activeField != nil {
                    searchResultsView
                } else if let start = startStation, let dest = destStation {
                    routeOptionsView(start: start.name, dest: dest.name)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Spacer()
                }
            }
            .padding(.top, 10)

            Spacer()
        }
        .background(Color(hex: "#fcfcfc").ignoresSafeArea())
        .animation(.spring(), value: activeField)
        .animation(.spring(), value: startStation)
        .animation(.spring(), value: destStation)
        .onAppear {
            if let ps = navigationVM.prefillStart {
                startText = ps.name
                startStation = ps
                navigationVM.prefillStart = nil
            }
            if let pd = navigationVM.prefillDest {
                destText = pd.name
                destStation = pd
                navigationVM.prefillDest = nil
            }
            if navigationVM.focusFromFieldOnAppear {
                navigationVM.focusFromFieldOnAppear = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    activeField = .start
                }
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                let query = activeField == .start ? startText : destText
                let pool = activeField == .start
                    ? demoStations.filter { originStationNames.contains($0.name) }
                    : demoStations.filter { destinationStationNames.contains($0.name) }
                let results = pool.filter { query.isEmpty || $0.name.lowercased().contains(query.lowercased()) }

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
                                selectedRouteOption = nil
                                activeField = .destination
                            } else {
                                destText = station.name
                                destStation = station
                                selectedRouteOption = nil
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

    // MARK: - Route Options

    private func routeOptionsView(start: String, dest: String) -> some View {
        let options = generateDemoRouteOptions(from: start, to: dest)

        return ScrollView {
            VStack(spacing: 16) {
                Text("Route Options")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#555566"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                if options.isEmpty {
                    routeUnavailableCard(start: start, dest: dest)
                }

                ForEach(options) { option in
                    routeOptionCard(option: option)
                }

                if let chosen = selectedRouteOption {
                    Button(action: { beginNavigation(with: chosen) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                            Text("Start Navigation")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(green)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
            .animation(.spring(), value: selectedRouteOption?.label)
        }
    }

    private func routeOptionCard(option: RouteOption) -> some View {
        // Compare by label since RouteOption regenerates UUIDs on each render.
        let isSelected = selectedRouteOption?.label == option.label
        // Demo constraint: only "Fewer Turns" is selectable.
        let isEnabled = option.label == "Fewer Turns"

        return Button(action: {
            guard isEnabled else { return }
            selectedRouteOption = option
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Card header row
                HStack(spacing: 10) {
                    Text(option.label)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(option.badgeColor)
                        .cornerRadius(8)

                    Text(option.summaryLine)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#3a3a4a"))

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? green : Color.gray.opacity(0.4))
                        .font(.system(size: 20))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, isSelected ? 8 : 14)

                // Expanded step timeline (only for selected)
                if isSelected {
                    Divider().padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(option.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 14) {
                                VStack(spacing: 0) {
                                    Circle()
                                        .stroke(red, lineWidth: 2)
                                        .background(Circle().fill(Color.white))
                                        .frame(width: 14, height: 14)

                                    if index < option.steps.count - 1 {
                                        Rectangle()
                                            .fill(red)
                                            .frame(width: 2)
                                            .frame(minHeight: 56)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.instruction)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "#1a1a2e"))

                                    if let subtitle = step.subtitle {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundColor(Color(hex: "#666677"))
                                    }
                                }
                                .padding(.top, -2)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: isSelected ? green.opacity(0.18) : Color.black.opacity(0.05), radius: isSelected ? 10 : 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? green : Color.clear, lineWidth: 1.5)
            )
            .opacity(isEnabled ? 1.0 : 0.55)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Route Unavailable

    private func routeUnavailableCard(start: String, dest: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color(hex: "#f5a524"))
                    .font(.system(size: 18))
                Text("Route not available in demo")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#1a1a2e"))
                Spacer()
            }
            Text("This prototype doesn't have a mapped route from “\(start)” to “\(dest)” yet. Try a different pairing to see the demo.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#555566"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "#f5a524").opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Begin Navigation

    private func beginNavigation(with option: RouteOption) {
        guard let start = startStation, let dest = destStation else { return }
        navigationVM.startStation = start
        navigationVM.destStation = dest
        navigationVM.startNavigation()
    }
}

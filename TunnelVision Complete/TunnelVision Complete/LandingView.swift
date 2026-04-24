// AI Attribution: Generated with Claude Opus 4.6

import SwiftUI

struct LandingView: View {
    @EnvironmentObject var navigationVM: NavigationViewModel

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var filteredStations: [Station] {
        let destinations = demoStations.filter { destinationStationNames.contains($0.name) }
        if searchText.isEmpty { return destinations }
        return destinations.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#fcfcfc").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if !isSearchFocused {
                    logoSection
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                searchBarSection
                    .padding(.top, isSearchFocused ? 60 : 28)

                manualRouteCTA
                    .padding(.top, 14)

                if isSearchFocused {
                    searchResultsList
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isSearchFocused)
        .onTapGesture {
            if isSearchFocused && searchText.isEmpty {
                isSearchFocused = false
            }
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 12) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)

            Text("TunnelVision")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#1a1a2e"))

            Text("Subway Transfer Navigator")
                .font(.subheadline)
                .foregroundColor(Color(hex: "#555566"))
        }
    }

    // MARK: - Search Bar

    private var searchBarSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSearchFocused ? Color(hex: "#17c964") : .gray)

            TextField(
                "Where do you wanna go?",
                text: $searchText,
                prompt: Text("Where do you wanna go?")
                    .foregroundColor(.gray.opacity(0.7))
            )
            .foregroundColor(.primary)
            .font(.system(size: 17))
            .focused($isSearchFocused)
            .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(isSearchFocused ? 0.10 : 0.06), radius: isSearchFocused ? 12 : 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSearchFocused ? Color(hex: "#17c964").opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
    }

    // MARK: - Manual CTA

    private var manualRouteCTA: some View {
        Button {
            navigationVM.openManualSearch()
        } label: {
            HStack(spacing: 6) {
                Text("Or set your own route")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#555566"))
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#17c964"))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(0.6))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Results

    private var searchResultsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if filteredStations.isEmpty {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        Text("No stations found")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(filteredStations) { station in
                        Button {
                            navigationVM.openSearchWithDestination(station)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(hex: "#f31260"))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(station.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(hex: "#1a1a2e"))

                                    Text("From \(originForDestination[station.name] ?? "Unknown")")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "#555566"))
                                }

                                Spacer()

                                Image(systemName: "arrow.right.circle")
                                    .foregroundColor(Color(hex: "#17c964"))
                                    .font(.system(size: 18))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }

                        if station.id != filteredStations.last?.id {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 12)
        .frame(maxHeight: 340)
    }

}

#Preview {
    LandingView()
        .environmentObject(NavigationViewModel())
}

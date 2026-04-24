import Foundation
import Combine

@MainActor
class TransitViewModel: ObservableObject {
    @Published var nextTrains: [Train] = []
    @Published var isLoading = true
    @Published var currentTime = Date()
    @Published var statusMessage: String?
    @Published var dataSource: TransitDataSource = .realtime

    private let apiService = TransitAPIService()
    private var timer: Timer?
    private var lastSuccessfulRefresh: Date?
    private let refreshInterval: TimeInterval = 30

    func loadData() async {
        await refreshTrains(showLoading: true)
        startTimer()
    }

    var emptyStateMessage: String {
        statusMessage ?? "No upcoming trains"
    }

    private func refreshNeeded(now: Date) -> Bool {
        guard let lastSuccessfulRefresh else { return true }
        return now.timeIntervalSince(lastSuccessfulRefresh) >= refreshInterval
    }

    private func refreshTrains(showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }

        do {
            let result = try await apiService.fetchNextTrainsResult(now: Date())
            nextTrains = result.trains.sorted(by: { $0.arrivalTime < $1.arrivalTime })
            dataSource = result.source
            statusMessage = nil
            lastSuccessfulRefresh = Date()
        } catch {
            nextTrains = []
            dataSource = .realtime
            statusMessage = "SEPTA realtime AND schedule data for the L is temporarily unavailable."
        }

        isLoading = false
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }

    private func tick() {
        currentTime = Date()

        nextTrains.removeAll { $0.arrivalTime < currentTime }

        if refreshNeeded(now: currentTime) {
            Task { [weak self] in
                await self?.refreshTrains(showLoading: false)
            }
        }
    }
}

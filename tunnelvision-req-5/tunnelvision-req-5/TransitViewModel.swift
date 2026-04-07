import Foundation
import Combine

@MainActor
class TransitViewModel: ObservableObject {
    @Published var nextTrains: [Train] = []
    @Published var isLoading = true
    
    //publish the current time so the UI redreaws for the ticks
    @Published var currentTime = Date()
    @Published var showMissedAlert = false
    @Published var missedTrainName = ""
    
    private let apiService = TransitAPIService()
    private var timer: Timer?
    
    func loadData() async {
        isLoading = true
        do {
            let trains = try await apiService.fetchNextTrains()
            self.nextTrains = trains.sorted(by: { $0.arrivalTime < $1.arrivalTime })
            self.isLoading = false
            startTimer()
        } catch {
            print("Failed to load mock data")
            self.isLoading = false
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        
        // every 1 sec
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }
    
    private func tick() {
        currentTime = Date()
        
        //if train hits 0
        let missedTrains = nextTrains.filter { $0.arrivalTime < currentTime }
        
        // trigger alert to let user know
        if let justMissed = missedTrains.first {
            missedTrainName = justMissed.routeName
            showMissedAlert = true
        }
        
        //them remove it
        nextTrains.removeAll { $0.arrivalTime < currentTime }
    }
}
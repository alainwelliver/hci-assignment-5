import Foundation

class TransitAPIService {
    func fetchNextTrains() async throws -> [Train] {
        // to simulate a 1 sec delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let now = Date()
        
        // 10% chance the second train is delayed --> tto simulate
        let randomDelayChance = Int.random(in: 1...10)
        let isSecondTrainDelayed = randomDelayChance <= 8
                
        return [
            //train 1: Arrives in 15 seconds (we will miss it)
            Train(routeName: "1", destination: "South Ferry", arrivalTime: now.addingTimeInterval(15), isDelayed: false),
            
            // train 2: Arrives in ~3.5 minutes --> ,might be delayed
            Train(routeName: "1", destination: "South Ferry", arrivalTime: now.addingTimeInterval(215), isDelayed: isSecondTrainDelayed),
            
            //train 3: arrives in ~12 minutes
            Train(routeName: "1", destination: "South Ferry", arrivalTime: now.addingTimeInterval(720), isDelayed: false)
        ]
    }
}
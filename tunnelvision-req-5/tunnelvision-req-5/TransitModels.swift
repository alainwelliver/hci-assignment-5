import Foundation

struct Train: Identifiable {
    let id = UUID()
    let routeName: String
    let destination: String
    var arrivalTime: Date
    var isDelayed: Bool
    
    // calcs difference between the current time and arrival time
    func timeRemainingString(from currentTime: Date) -> String {
        let timeDifference = arrivalTime.timeIntervalSince(currentTime)
        
        if timeDifference <= 0 {
            return "0:00 min"
        }
        
        let minutes = Int(timeDifference) / 60
        let seconds = Int(timeDifference) % 60
        
        return String(format: "%d:%02d min", minutes, seconds)
    }
}
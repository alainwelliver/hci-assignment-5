import Foundation

/// Loads the bundled GTFS-static schedule for SEPTA's Market-Frankford Line ("L1")
/// and provides the next scheduled arrival for a given stop. Used as a fallback when
/// the GTFS-realtime feed has no L data (SEPTA has been known to publish nothing for
/// the L for stretches; Google Maps mirrors the same behavior by showing scheduled
/// times only).
final class MFLScheduleService {
    static let shared = MFLScheduleService()

    private struct Service {
        let days: [Bool]      // length 7, index 0 = Monday (matches GTFS calendar.txt)
        let start: Int        // YYYYMMDD as Int
        let end: Int
    }

    private struct StopArrival {
        let secondsFromServiceMidnight: Int
        let headsign: String
    }

    private struct Bundle {
        let services: [String: Service]
        // service_id -> set of YYYYMMDD ints where it is added (type 1) or removed (type 2)
        let added: [String: Set<Int>]
        let removed: [String: Set<Int>]
        // stop_id -> service_id -> sorted arrivals
        let stopTimes: [String: [String: [StopArrival]]]
    }

    private let bundle: Bundle?
    private let calendar: Calendar

    init(bundleProvider: () -> Data? = MFLScheduleService.defaultBundleData) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        self.calendar = calendar
        self.bundle = MFLScheduleService.parse(bundleProvider())
    }

    /// Returns the next scheduled `Train` arriving at `stopID` strictly after `now`,
    /// searching today's active services and (for late-night service that crosses
    /// midnight) yesterday's active services. Returns `nil` if no entry can be found.
    func nextScheduledTrain(forStopID stopID: String, now: Date) -> Train? {
        guard let bundle, let stops = bundle.stopTimes[stopID] else { return nil }

        let nowComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        guard
            let todayMidnight = calendar.date(from: DateComponents(
                year: nowComponents.year,
                month: nowComponents.month,
                day: nowComponents.day
            )),
            let yesterdayMidnight = calendar.date(byAdding: .day, value: -1, to: todayMidnight)
        else {
            return nil
        }

        let secondsSinceMidnight = (nowComponents.hour ?? 0) * 3600
            + (nowComponents.minute ?? 0) * 60
            + (nowComponents.second ?? 0)

        var best: (Date, String)?

        // Today's services: any arrival with t > secondsSinceMidnight.
        for serviceID in activeServiceIDs(on: todayMidnight, bundle: bundle) {
            guard let arrivals = stops[serviceID] else { continue }
            if let arrival = firstArrival(in: arrivals, strictlyAfterSeconds: secondsSinceMidnight) {
                let date = todayMidnight.addingTimeInterval(TimeInterval(arrival.secondsFromServiceMidnight))
                if best == nil || date < best!.0 {
                    best = (date, arrival.headsign)
                }
            }
        }

        // Yesterday's services that extend past midnight (t >= 86400).
        for serviceID in activeServiceIDs(on: yesterdayMidnight, bundle: bundle) {
            guard let arrivals = stops[serviceID] else { continue }
            let threshold = secondsSinceMidnight + 86_400
            if let arrival = firstArrival(in: arrivals, strictlyAfterSeconds: threshold) {
                let date = yesterdayMidnight.addingTimeInterval(TimeInterval(arrival.secondsFromServiceMidnight))
                if best == nil || date < best!.0 {
                    best = (date, arrival.headsign)
                }
            }
        }

        guard let (arrivalDate, headsign) = best else { return nil }
        return Train(
            routeName: "L",
            destination: headsign.isEmpty ? "Frankford Transit Center" : headsign,
            arrivalTime: arrivalDate,
            isDelayed: false
        )
    }

    // MARK: - Active services

    private func activeServiceIDs(on midnight: Date, bundle: Bundle) -> [String] {
        let comps = calendar.dateComponents([.year, .month, .day, .weekday], from: midnight)
        guard let year = comps.year, let month = comps.month, let day = comps.day, let weekday = comps.weekday else {
            return []
        }
        let yyyymmdd = year * 10_000 + month * 100 + day
        // GTFS days are Mon..Sun (index 0..6). Calendar.weekday is Sun=1..Sat=7.
        let mondayIndex = (weekday + 5) % 7

        var result: [String] = []
        for (serviceID, service) in bundle.services {
            let inRange = yyyymmdd >= service.start && yyyymmdd <= service.end
            let runsToday = inRange && service.days[mondayIndex]
            let removed = bundle.removed[serviceID]?.contains(yyyymmdd) ?? false
            let added = bundle.added[serviceID]?.contains(yyyymmdd) ?? false
            if (runsToday && !removed) || added {
                result.append(serviceID)
            }
        }
        return result
    }

    private func firstArrival(in arrivals: [StopArrival], strictlyAfterSeconds threshold: Int) -> StopArrival? {
        // Arrivals are sorted ascending by `secondsFromServiceMidnight`; binary-search.
        var low = 0
        var high = arrivals.count
        while low < high {
            let mid = (low + high) / 2
            if arrivals[mid].secondsFromServiceMidnight <= threshold {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return low < arrivals.count ? arrivals[low] : nil
    }

    // MARK: - Loading & parsing

    private static func defaultBundleData() -> Data? {
        guard let url = Foundation.Bundle.main.url(forResource: "mfl_schedule", withExtension: "json") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    private static func parse(_ data: Data?) -> Bundle? {
        guard let data,
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        var services: [String: Service] = [:]
        if let rawServices = raw["services"] as? [String: [String: Any]] {
            for (id, entry) in rawServices {
                guard let days = entry["days"] as? [Bool],
                      days.count == 7,
                      let startStr = entry["start"] as? String,
                      let endStr = entry["end"] as? String,
                      let start = Int(startStr),
                      let end = Int(endStr) else {
                    continue
                }
                services[id] = Service(days: days, start: start, end: end)
            }
        }

        var added: [String: Set<Int>] = [:]
        var removed: [String: Set<Int>] = [:]
        if let rawExceptions = raw["exceptions"] as? [[String: Any]] {
            for entry in rawExceptions {
                guard let serviceID = entry["service"] as? String,
                      let dateStr = entry["date"] as? String,
                      let date = Int(dateStr),
                      let type = entry["type"] as? Int else {
                    continue
                }
                if type == 1 {
                    added[serviceID, default: []].insert(date)
                } else if type == 2 {
                    removed[serviceID, default: []].insert(date)
                }
            }
        }

        var stopTimes: [String: [String: [StopArrival]]] = [:]
        if let rawStops = raw["stopTimes"] as? [String: [String: [[String: Any]]]] {
            for (stopID, perService) in rawStops {
                var bucket: [String: [StopArrival]] = [:]
                for (serviceID, arrivals) in perService {
                    var parsed: [StopArrival] = []
                    parsed.reserveCapacity(arrivals.count)
                    for entry in arrivals {
                        guard let t = entry["t"] as? Int else { continue }
                        let headsign = (entry["headsign"] as? String) ?? ""
                        parsed.append(StopArrival(secondsFromServiceMidnight: t, headsign: headsign))
                    }
                    if !parsed.isEmpty {
                        bucket[serviceID] = parsed.sorted { $0.secondsFromServiceMidnight < $1.secondsFromServiceMidnight }
                    }
                }
                if !bucket.isEmpty {
                    stopTimes[stopID] = bucket
                }
            }
        }

        guard !services.isEmpty, !stopTimes.isEmpty else { return nil }
        return Bundle(services: services, added: added, removed: removed, stopTimes: stopTimes)
    }
}

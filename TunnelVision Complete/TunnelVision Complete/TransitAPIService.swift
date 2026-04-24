// AI Attribution: Generated with Claude Opus 4.6

import Foundation
import CoreLocation

enum TransitServiceError: LocalizedError {
    case invalidResponse
    case noRealtimeRouteData
    case noUpcomingArrivals
    case scheduleUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse, .noRealtimeRouteData, .noUpcomingArrivals, .scheduleUnavailable:
            return "SEPTA realtime AND schedule data for the L is temporarily unavailable."
        }
    }
}

enum TransitDataSource {
    case realtime
    case schedule
}

struct TrainsResult {
    let trains: [Train]
    let source: TransitDataSource
}

struct MFLStationStop {
    let stopID: String
    let name: String
    let coordinate: CLLocationCoordinate2D
}

final class TransitAPIService {
    private let tripUpdatesURL = URL(string: "https://www3.septa.org/gtfsrt/septa-pa-us/Trip/print.php")!
    private let mflRouteID = "L1"
    private let fallbackStopID = "2453" // 34th St
    private let fallbackDestination = "69th St Transit Center"

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        return URLSession(configuration: config)
    }()

    private let locationProvider = RealtimeLocationProvider()
    private let scheduleService: MFLScheduleService

    init(scheduleService: MFLScheduleService = .shared) {
        self.scheduleService = scheduleService
    }

    /// Returns the next L trains plus an indicator of whether the data came from
    /// SEPTA's GTFS-realtime feed or the bundled GTFS-static schedule fallback.
    /// Throws `TransitServiceError.scheduleUnavailable` only when both sources fail.
    func fetchNextTrainsResult(now: Date = Date()) async throws -> TrainsResult {
        let nearestStop = await resolveNearestStop()

        if let realtimeTrains = try? await fetchRealtimeTrains(nearestStop: nearestStop, now: now),
           !realtimeTrains.isEmpty {
            return TrainsResult(trains: realtimeTrains, source: .realtime)
        }

        if let scheduled = scheduleService.nextScheduledTrain(forStopID: nearestStop.stopID, now: now) {
            return TrainsResult(trains: [scheduled], source: .schedule)
        }
        if let scheduled = scheduleService.nextScheduledTrain(forStopID: fallbackStopID, now: now) {
            return TrainsResult(trains: [scheduled], source: .schedule)
        }

        throw TransitServiceError.scheduleUnavailable
    }

    private func fetchRealtimeTrains(nearestStop: MFLStationStop, now: Date) async throws -> [Train] {
        let text = try await fetchRealtimeTripText()
        guard text.contains("route_id: \"\(mflRouteID)\"") else {
            throw TransitServiceError.noRealtimeRouteData
        }
        return parseMFLArrivals(
            from: text,
            matchingStopID: nearestStop.stopID,
            fallbackStopID: fallbackStopID,
            now: now
        )
    }

    private func resolveNearestStop() async -> MFLStationStop {
        let currentLocation = await locationProvider.requestLocationIfPermitted()
        guard let currentLocation else {
            return Self.mflStops.first(where: { $0.stopID == fallbackStopID }) ?? Self.mflStops[0]
        }

        let closest = Self.mflStops.min { lhs, rhs in
            let lhsDistance = currentLocation.distance(from: CLLocation(latitude: lhs.coordinate.latitude, longitude: lhs.coordinate.longitude))
            let rhsDistance = currentLocation.distance(from: CLLocation(latitude: rhs.coordinate.latitude, longitude: rhs.coordinate.longitude))
            return lhsDistance < rhsDistance
        }

        return closest ?? (Self.mflStops.first(where: { $0.stopID == fallbackStopID }) ?? Self.mflStops[0])
    }

    private func fetchRealtimeTripText() async throws -> String {
        var request = URLRequest(url: tripUpdatesURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw TransitServiceError.invalidResponse
        }
        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
            throw TransitServiceError.invalidResponse
        }
        return text
    }

    private func parseMFLArrivals(from responseText: String, matchingStopID: String, fallbackStopID: String, now: Date) -> [Train] {
        let entities = Self.extractBlocks(named: "entity", from: responseText)
        let relevantStopID = determineBestStopID(
            entities: entities,
            preferredStopIDs: relatedStopIDs(for: matchingStopID),
            fallbackStopIDs: relatedStopIDs(for: fallbackStopID)
        )

        var arrivals: [Train] = []
        let nowTimestamp = Int(now.timeIntervalSince1970)

        for entity in entities where entity.contains("trip_update {") && entity.contains("route_id: \"\(mflRouteID)\"") {
            let destination = Self.capturedValue(in: entity, pattern: #"trip_headsign: "([^"]+)""#) ?? fallbackDestination
            let stopUpdates = Self.extractBlocks(named: "stop_time_update", from: entity)

            for stopUpdate in stopUpdates {
                guard Self.capturedValue(in: stopUpdate, pattern: #"stop_id: "([^"]+)""#) == relevantStopID else {
                    continue
                }

                guard
                    let arrivalTimestampString = Self.capturedValue(in: stopUpdate, pattern: #"arrival \{\s*time: (\d+)"#),
                    let arrivalTimestamp = Int(arrivalTimestampString),
                    arrivalTimestamp > nowTimestamp
                else {
                    continue
                }

                let delay = Int(Self.capturedValue(in: stopUpdate, pattern: #"delay: (-?\d+)"#) ?? "0") ?? 0
                arrivals.append(
                    Train(
                        routeName: "L",
                        destination: destination,
                        arrivalTime: Date(timeIntervalSince1970: TimeInterval(arrivalTimestamp)),
                        isDelayed: delay >= 120
                    )
                )
            }
        }

        return arrivals.sorted { $0.arrivalTime < $1.arrivalTime }
    }

    private func determineBestStopID(entities: [String], preferredStopIDs: Set<String>, fallbackStopIDs: Set<String>) -> String {
        let availableStopIDs = Set(
            entities
                .filter { $0.contains("route_id: \"\(mflRouteID)\"") }
                .flatMap { entity in
                    Self.extractBlocks(named: "stop_time_update", from: entity)
                        .compactMap { Self.capturedValue(in: $0, pattern: #"stop_id: "([^"]+)""#) }
                }
        )

        if let preferredMatch = preferredStopIDs.first(where: { availableStopIDs.contains($0) }) {
            return preferredMatch
        }
        if let fallbackMatch = fallbackStopIDs.first(where: { availableStopIDs.contains($0) }) {
            return fallbackMatch
        }
        return availableStopIDs.first ?? fallbackStopID
    }

    private func relatedStopIDs(for stopID: String) -> Set<String> {
        guard let seed = Self.mflStops.first(where: { $0.stopID == stopID }) else {
            return [stopID]
        }
        let sameStation = Self.mflStops
            .filter { $0.name.caseInsensitiveCompare(seed.name) == .orderedSame }
            .map(\.stopID)
        if sameStation.isEmpty {
            return [stopID]
        }
        return Set(sameStation)
    }

    private static func extractBlocks(named blockName: String, from text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var blocks: [String] = []
        var collecting = false
        var depth = 0
        var currentLines: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if !collecting, trimmed == "\(blockName) {" {
                collecting = true
                depth = 1
                currentLines = [line]
                continue
            }

            guard collecting else { continue }
            currentLines.append(line)

            depth += trimmed.filter { $0 == "{" }.count
            depth -= trimmed.filter { $0 == "}" }.count

            if depth == 0 {
                blocks.append(currentLines.joined(separator: "\n"))
                collecting = false
                currentLines = []
            }
        }

        return blocks
    }

    private static func capturedValue(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard
            let match = regex.firstMatch(in: text, options: [], range: range),
            match.numberOfRanges >= 2,
            let valueRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }
        return String(text[valueRange])
    }

    // Stops from SEPTA GTFS static feed for route L1.
    private static let mflStops: [MFLStationStop] = [
        .init(stopID: "1392", name: "15th St/City Hall", coordinate: .init(latitude: 39.952573, longitude: -75.165286)),
        .init(stopID: "2456", name: "11th St", coordinate: .init(latitude: 39.951693, longitude: -75.158322)),
        .init(stopID: "2455", name: "13th St", coordinate: .init(latitude: 39.952065, longitude: -75.161450)),
        .init(stopID: "428", name: "2nd St", coordinate: .init(latitude: 39.949795, longitude: -75.143758)),
        .init(stopID: "2453", name: "34th St", coordinate: .init(latitude: 39.955830, longitude: -75.191480)),
        .init(stopID: "32177", name: "34th St", coordinate: .init(latitude: 39.955901, longitude: -75.191480)),
        .init(stopID: "2452", name: "40th St", coordinate: .init(latitude: 39.957117, longitude: -75.201963)),
        .init(stopID: "2451", name: "46th St", coordinate: .init(latitude: 39.958619, longitude: -75.214028)),
        .init(stopID: "2450", name: "52nd St", coordinate: .init(latitude: 39.959976, longitude: -75.224889)),
        .init(stopID: "2449", name: "56th St", coordinate: .init(latitude: 39.960962, longitude: -75.232859)),
        .init(stopID: "2458", name: "5th St/Independence Hall", coordinate: .init(latitude: 39.950530, longitude: -75.148939)),
        .init(stopID: "2448", name: "60th St", coordinate: .init(latitude: 39.961956, longitude: -75.240757)),
        .init(stopID: "2447", name: "63rd St", coordinate: .init(latitude: 39.962714, longitude: -75.246767)),
        .init(stopID: "416", name: "69th St Transit Center", coordinate: .init(latitude: 39.962338, longitude: -75.258555)),
        .init(stopID: "2457", name: "8th-Market", coordinate: .init(latitude: 39.951102, longitude: -75.153589)),
        .init(stopID: "217", name: "Arrott Transit Center", coordinate: .init(latitude: 40.016564, longitude: -75.083802)),
        .init(stopID: "2460", name: "Berks", coordinate: .init(latitude: 39.978626, longitude: -75.133448)),
        .init(stopID: "2464", name: "Church", coordinate: .init(latitude: 40.010901, longitude: -75.088651)),
        .init(stopID: "21532", name: "Drexel Station at 30th St", coordinate: .init(latitude: 39.954814, longitude: -75.183276)),
        .init(stopID: "838", name: "Erie-Torresdale", coordinate: .init(latitude: 40.005825, longitude: -75.096404)),
        .init(stopID: "61", name: "Frankford Transit Center", coordinate: .init(latitude: 40.022929, longitude: -75.077861)),
        .init(stopID: "353", name: "Front-Girard", coordinate: .init(latitude: 39.968877, longitude: -75.136146)),
        .init(stopID: "2462", name: "Huntingdon", coordinate: .init(latitude: 39.988803, longitude: -75.127274)),
        .init(stopID: "60", name: "Kensington-Allegheny", coordinate: .init(latitude: 39.996471, longitude: -75.113440)),
        .init(stopID: "2446", name: "Millbourne", coordinate: .init(latitude: 39.964320, longitude: -75.252243)),
        .init(stopID: "797", name: "Somerset", coordinate: .init(latitude: 39.991424, longitude: -75.122489)),
        .init(stopID: "2459", name: "Spring Garden", coordinate: .init(latitude: 39.960533, longitude: -75.140337)),
        .init(stopID: "2463", name: "Tioga", coordinate: .init(latitude: 40.000291, longitude: -75.106439)),
        .init(stopID: "2461", name: "York-Dauphin", coordinate: .init(latitude: 39.985512, longitude: -75.131942)),
    ]
}

private final class RealtimeLocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    func requestLocationIfPermitted() async -> CLLocation? {
        guard Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil else {
            return nil
        }

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            default:
                continuation.resume(returning: nil)
                self.continuation = nil
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            continuation?.resume(returning: nil)
            continuation = nil
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.first)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }
}

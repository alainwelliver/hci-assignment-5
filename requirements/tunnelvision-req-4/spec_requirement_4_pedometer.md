# Requirement 4: Pedometer-Based Indoor Positioning — Implementation Prototype Spec

## What This Proves

That the app can read the iPhone's step counter and automatically advance through a predefined sequence of navigation waypoints as the user physically walks, transitioning between waypoints at approximately the right physical locations.

## Platform & Framework

- Swift / SwiftUI
- Target: iPhone (must run on a real device; CMPedometer does not work in the simulator)
- Minimum iOS 17

## Permissions Required

- Add `NSMotionUsageDescription` to Info.plist with the string: "TunnelVision needs motion data to track your walking progress through the station."

## Data Model

```swift
struct Waypoint {
    let id: Int
    let name: String           // e.g. "Entrance Hall"
    let instruction: String    // e.g. "Walk straight past the ticket machines"
    let stepThreshold: Int     // cumulative steps to reach this waypoint
}
```

Hardcoded route (calibrate these to a real AGH route before filming):

```swift
let route: [Waypoint] = [
    Waypoint(id: 1, name: "Start: AGH Lobby",        instruction: "Begin walking toward the main corridor",  stepThreshold: 0),
    Waypoint(id: 2, name: "Main Corridor",            instruction: "Continue straight past the elevators",    stepThreshold: 30),
    Waypoint(id: 3, name: "Corridor Junction",        instruction: "Bear left at the junction",               stepThreshold: 65),
    Waypoint(id: 4, name: "Exit Hallway",             instruction: "Walk toward the exit doors",              stepThreshold: 100),
    Waypoint(id: 5, name: "Arrived: 34th St Exit",    instruction: "You have arrived.",                       stepThreshold: 130),
]
```

## Screen Layout (Single Screen)

Top section:
- Step counter label: "Steps: 47" (updates live from CMPedometer)

Middle section (the main content area):
- Current waypoint name in large text (e.g. "Main Corridor")
- Current instruction in smaller text below (e.g. "Continue straight past the elevators")
- Progress text: "Waypoint 2 of 5"

Bottom section:
- A simple progress bar showing how far through the total route (by step count) the user is
- Next waypoint label: "Next: Corridor Junction in ~18 steps"

## Behavior

1. On app launch, request motion permission and start CMPedometer updates using `startUpdates(from: Date())`.
2. Display the live cumulative step count on screen.
3. Compare cumulative steps against the route array. When steps >= the next waypoint's stepThreshold, transition to that waypoint (update the displayed name, instruction, progress text, and progress bar).
4. When the final waypoint is reached, show a green checkmark or "Arrived!" state and stop pedometer updates.
5. Include a "Reset" button that resets the step counter and returns to waypoint 1 (for re-demo purposes).

## What NOT to Build

- No map, no AR, no camera.
- No networking or API calls.
- No navigation between multiple screens. This is one screen.
- No connection to requirement 6. This is standalone.
- No styling beyond basic readability (system fonts are fine, though using Inter + the green #17c964 for the progress bar and arrival state would be a nice touch if easy).

## Evidence to Capture

A short video (under 30 seconds) filmed by a teammate showing:
- The phone screen visible as you walk a route in AGH
- The step count incrementing
- The waypoint transitioning automatically as you walk
- The arrival state at the end

Screen-record the phone simultaneously if possible for a cleaner backup.

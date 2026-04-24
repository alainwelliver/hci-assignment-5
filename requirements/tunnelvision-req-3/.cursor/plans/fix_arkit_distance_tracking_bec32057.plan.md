---
name: Fix ARKit distance tracking
overview: Fix the distance never updating (CADisplayLink can't fire because TunnelRouteNavigator doesn't inherit from NSObject) and reverse the demo route direction.
todos:
  - id: nsobj
    content: Add NSObject inheritance + super.init() to TunnelRouteNavigator so CADisplayLink works
    status: completed
  - id: route
    content: Reverse demo route bearings from (0, 270, 0) to (180, 90, 180)
    status: completed
isProject: false
---

# Fix ARKit Distance Tracking and Route Direction

## Bug: Distance never updates

The root cause is in [TunnelRouteNavigator.swift](tunnelvision-req-3/tunnelvision-req-3/TunnelRouteNavigator.swift) line 108:

```swift
@MainActor
final class TunnelRouteNavigator: ObservableObject {
```

This class uses `CADisplayLink(target: self, selector: #selector(tick))` to poll ARKit displacement every frame. But `CADisplayLink` requires the target to be an `NSObject` subclass, and `#selector` / `@objc` also require `NSObject`. Without it, the display link silently never fires, so `tick()` never runs, so `consumeDisplacement()` is never called, and distance stays frozen.

**Fix:** Add `NSObject` inheritance to `TunnelRouteNavigator` and add `super.init()` to the initializer.

## Route direction

The current demo route (`DemoRoutes.lShapedTunnel`) heads **north** (bearing 0) then turns **west** (bearing 270). If the user is facing/walking the opposite direction, the route never makes progress.

**Fix:** Reverse the bearings to go **south** (180) then **east** (90), so the route goes in the opposite direction. This matches wherever the user was walking during testing.

## Route starting location

To answer the user's question: yes, the route effectively starts at your current position when the app launches. The hardcoded lat/lon coordinates are only used to compute the compass bearing between waypoints -- since ARKit measures actual displacement in meters (not GPS), the absolute coordinates don't matter. You always start at "waypoint 0" and walk toward "waypoint 1."

## Changes

All changes are in [TunnelRouteNavigator.swift](tunnelvision-req-3/tunnelvision-req-3/TunnelRouteNavigator.swift):

- Line 108: Change `final class TunnelRouteNavigator: ObservableObject` to `final class TunnelRouteNavigator: NSObject, ObservableObject`
- In `init(route:)`: Add `super.init()` call after setting stored properties
- In `DemoRoutes.lShapedTunnel`: Flip bearings from (0, 270, 0) to (180, 90, 180)

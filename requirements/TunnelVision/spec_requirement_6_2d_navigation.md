# Requirement 6: Step-by-Step 2D Navigation Mode — Implementation Prototype Spec

## What This Proves

That the app can display a sequence of directional instruction cards with walking directions, and that the user can progress through them by tapping forward or backward. This is the non-AR fallback navigation mode.

## Platform & Framework

- Swift / SwiftUI
- Target: iPhone (can run in the simulator since no hardware sensors are needed)
- Minimum iOS 17

## Design Reference

Based on the TunnelVision hi-fi Figma screens (Nav 1, 2, 4, 5 in the 2D mode), incorporating heuristic evaluation feedback.

## Data Model

```swift
enum Direction {
    case straight, bearLeft, bearRight, turnLeft, turnRight, upStairs, downStairs, splitAhead
}

struct NavStep {
    let id: Int
    let direction: Direction
    let label: String              // e.g. "Bear Left"
    let estimatedTimeRemaining: String  // e.g. "~2:43"
    let nextTrainArrival: String        // e.g. "4:12"
    let trainLine: String               // e.g. "1"
    let trainColor: String              // hex color for the line badge, e.g. "#FF3B30" for the 1 train
}
```

Hardcoded route:

```swift
let navSteps: [NavStep] = [
    NavStep(id: 1, direction: .straight,    label: "Walk Straight",      estimatedTimeRemaining: "~2:43", nextTrainArrival: "4:12", trainLine: "1", trainColor: "#FF3B30"),
    NavStep(id: 2, direction: .bearLeft,    label: "Bear Left",          estimatedTimeRemaining: "~2:15", nextTrainArrival: "3:35", trainLine: "1", trainColor: "#FF3B30"),
    NavStep(id: 3, direction: .splitAhead,  label: "Split Ahead",        estimatedTimeRemaining: "~1:45", nextTrainArrival: "3:34", trainLine: "1", trainColor: "#FF3B30"),
    NavStep(id: 4, direction: .straight,    label: "Continue Straight",  estimatedTimeRemaining: "~1:10", nextTrainArrival: "3:32", trainLine: "1", trainColor: "#FF3B30"),
    NavStep(id: 5, direction: .upStairs,    label: "Go Up the Stairs",   estimatedTimeRemaining: "~0:30", nextTrainArrival: "2:51", trainLine: "1", trainColor: "#FF3B30"),
]
```

## Screen Layout (Single Screen)

Reference the hi-fi Nav screens for visual intent. The layout from top to bottom:

### Top Bar
- Pill-shaped banner: "Next [colored circle with train line number] train arriving in [time] min"
- Background: white/light with subtle shadow or border
- The colored circle matches trainColor. Text inside it is the trainLine number.

### Center Area (main content)
- Large green (#17c964) directional chevron arrows indicating the direction
  - .straight = arrows pointing up (^^^)
  - .bearLeft = arrows angled up-left
  - .bearRight = arrows angled up-right
  - .turnLeft = arrows pointing left
  - .turnRight = arrows pointing right
  - .upStairs = arrows pointing up with a stair icon or zigzag
  - .downStairs = arrows pointing down with a stair icon or zigzag
  - .splitAhead = arrows that fork (a Y shape)
- Use SF Symbols or simple drawn chevrons. Doesn't need to be pixel-perfect to the Figma. Just needs to clearly communicate direction.

### Direction Label
- Below the arrows, large text: the step's label (e.g. "Bear Left")
- Font: system bold, ~28pt (or Inter semibold if easy to set up)

### Info Row
- Green text: "Estimated Time Remaining: [time]"
- Font: ~14pt

### Step Indicator (addresses heuristic feedback: recognition vs recall)
- Text: "Step 2 of 5"
- Centered below the info row
- This was missing in the original hi-fi and was called out in the heuristic eval

### Navigation Buttons (addresses heuristic feedback: user control and freedom)
- Two buttons side by side:
  - "< Back" button (disabled/hidden on step 1)
  - "Next >" button (changes to "Arrived" on the last step)
- These replace the tap-anywhere-to-advance from the Figma prototype
- Style: outlined or filled buttons in green (#17c964)

### Bottom (optional)
- "Activate AR Navigation" button in green, outlined. For this prototype, it can just be a non-functional placeholder, or omit it entirely. It's not what we're proving here.
- You can also omit the bottom tab bar (Home/Nav/Settings) since this is a standalone prototype, not the full app.

### Arrival State
- When the user taps "Next" on the last step, show a completion screen:
  - Green checkmark icon
  - "You've Arrived!" text
  - A "Start Over" button to reset the demo

## Behavior

1. App launches directly into step 1 of the navigation sequence.
2. Tapping "Next" advances to the next step. The arrows, label, time remaining, train info, and step indicator all update.
3. Tapping "Back" goes to the previous step (hidden/disabled on step 1).
4. On the final step, "Next" becomes "Arrived" and tapping it shows the completion state.
5. "Start Over" resets to step 1.

## What NOT to Build

- No pedometer integration. Progression is tap-only.
- No AR camera. The "Activate AR Navigation" button can be a placeholder or omitted.
- No search screen, no itinerary screen. Just the navigation card screen.
- No networking or API calls. All data is hardcoded.
- No bottom tab bar needed. Single screen prototype.
- No map or route overview.

## Styling Notes

- If it's easy to import Inter font, use it. Otherwise system font is fine.
- Primary green: #17c964
- Use SF Symbols for arrows if custom chevrons are too complex. For example:
  - chevron.up for straight
  - chevron.left for turn left
  - arrow.up.left for bear left
  - etc.
- The train line colored circle is a small filled circle with white text inside it.

## Evidence to Capture

A screen recording (under 20 seconds) showing:
- The app on step 1
- Tapping "Next" through all 5 steps, showing the arrows and labels changing
- Tapping "Back" at least once to show backward navigation works
- Reaching the "You've Arrived!" completion state

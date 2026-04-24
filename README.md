# TunnelVision
By Alain, Tomas, and Ben. Built for Penn's CIS 4120: HCI course.

## How to run:
* Clone the repo
* Open `TunnelVision Complete` as a project in Xcode
* Select a **physical iPhone** as the run destination (a real camera feed is required for this prototype; Simulator is not sufficient for a meaningful demo).
* Build and run (play button). When prompted, allow **Camera** and **Motion** access.
* Tunnel safely!!

## Where to find/run each technical implementation prototype (for A5)
First navigate to the `requirements` folder.

### Technical Requirement 1: "Hello World" App
#### How to find:
* Navigate to the `requirements/tunnelvision-req-1` folder in this repo.
* Main implementation file is `HelloWorldView.swift` which renders the one-screen greeting.

#### How to run:
* Open `requirements/tunnelvision-req-1/requirements/tunnelvision-req-1.xcodeproj` in Xcode.
* Select an **iOS Simulator** as the run destination.
* Build and run (play button). You should see the "Hello World" text rendered cleanly on the center of the screen.

### Technical Requirement 2: "Hello Styles" (Style Guide)
#### How to find:
* Navigate to the `requirements/tunnelvision-req-2` folder in this repo.
* Main implementation file is `HelloStylesView.swift`  which programmatically renders our Hero UI color hexes, typography fallbacks, and SF Symbol icons.

#### How to run:
* Open `requirements/tunnelvision-req-2/requirements/tunnelvision-req-2.xcodeproj` in Xcode.
* Select an **iOS Simulator** as the run destination.
* Build and run (play button). The simulator will display a scrollable view of the full TunnelVision style guide.

### Technical Requirement 3: AR Camera Overlay (2D HUD on Live Camera)
#### How to find:
* Navigate to the `requirements/tunnelvision-req-3` folder in this repo.
* Main implementation files are under `requirements/tunnelvision-req-3/requirements/tunnelvision-req-3/`: `ARNavigationView.swift` (overlay UI), `CameraSession.swift` and `CameraPreview.swift` (live rear camera via AVFoundation), and `DeviceMotionOverlay.swift` (device motion for a world-stabilized direction cue). `ContentView.swift` hosts the root view.

#### How to run:
* Open `requirements/tunnelvision-req-3/requirements/tunnelvision-req-3.xcodeproj` in Xcode.
* Select a **physical iPhone** as the run destination (a real camera feed is required for this prototype; Simulator is not sufficient for a meaningful demo).
* Build and run (play button). When prompted, allow **Camera** and **Motion** access.
* You should see the live camera feed with green directional arrows and floating info cards (train / time). The direction cluster uses counter-rotation and counter-parallax relative to device motion so it stays visually steadier than the feed; the top train banner and bottom cards stay fixed in screen space.

### Technical Requirement 5: Real-time Transit Data API (Mocked for UI Testing)
#### How to find:
* Navigate to the `requirements/tunnelvision-req-5` folder in this repo.
* Main implementation files are `TransitModels.swift` (data structures), `TransitAPIService.swift` (mock API simulating network latency and random delays), `TransitViewModel.swift` (handles the 1-second ticking clock and missed train state), and `ContentView.swift` (the pill-shaped UI card).

#### How to run:
* Open `requirements/tunnelvision-req-5/requirements/tunnelvision-req-5.xcodeproj` in Xcode.
* Select an **iOS Simulator** as the run destination.
* Build and run (play button). 
* You will initially see a loading spinner to simulate network fetch. Once loaded, the "Next train" pill appears at the top of the screen. If you leave the simulator running for 15 seconds, you can watch the timer tick down to 0:00, trigger a native iOS alert that the train departed, and automatically animate the next delayed (delayed by 80% chance to show it) train into the UI.

### Technical Requirement 6: Step-by-Step 2D Navigation Mode
#### How to find:
* Navigate to the `requirements/TunnelVision` folder in this repo (yes, it should be labeled "TunnelVision, Requirement 6" or something, but Alain forgot to do this for this particular requirement)
* The code for this requirement's implementation is under `requirements/TunnelVision/TunnelVision/ContentView.swift`
#### How to run:
* Open the `requirements/TunnelVision/TunnelVision` folder as a "Project" in XCode, and then build by pressing the play arrow in XCode's top left navbar. This should open an iOS simulator which allows you to click through this requirement's prototype

### Technical Requirement 4: Pedometer-Based Indoor Positioning
#### How to find:
* Navigate to the "requirements/tunnelvision-req-4" folder 
* The code for this requirement's implementation is under requirements/tunnelvision-req-4/requirements/tunnelvision-req-4/ContentView.swift as well as requirements/tunnelvision-req-4/requirements/tunnelvision-req-4/PedometerViewModel.swift
#### How to run:
* Open the /requirements/tunnelvision-req-4/requirements/tunnelvision-req-4 folder as a "Project" in XCode, and then build by pressing the play arrow in XCode's top left navbar. Make sure the device to build on that you select is a real iPhone (the iOS simulator doesn't have a pedometer). To do this you will need to:
1. Enable Developer Mode on your iPhone
2. Allow your own personal Apple ID's developer profile on your phone (VPNs and profiles)
3. When the app asks for it, allow health and fitness data to be used by the app
4. build the app onto your phone
5. try walking around and seeing the step count increase and the directions change accordingly!

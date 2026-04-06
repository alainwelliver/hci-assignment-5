# hci-assignment-5
CIS 4120 HCI Assignment 5 - Alain, Tomas, and Ben

## Where to find/run each technical implementation prototype:
### Technical Requirement 3: AR Camera Overlay (2D HUD on Live Camera)
#### How to find:
* Navigate to the `tunnelvision-req-3` folder in this repo.
* Main implementation files are under `tunnelvision-req-3/tunnelvision-req-3/`: `ARNavigationView.swift` (overlay UI), `CameraSession.swift` and `CameraPreview.swift` (live rear camera via AVFoundation), and `DeviceMotionOverlay.swift` (device motion for a world-stabilized direction cue). `ContentView.swift` hosts the root view.

#### How to run:
* Open `tunnelvision-req-3/tunnelvision-req-3.xcodeproj` in Xcode.
* Select a **physical iPhone** as the run destination (a real camera feed is required for this prototype; Simulator is not sufficient for a meaningful demo).
* Build and run (play button). When prompted, allow **Camera** and **Motion** access.
* You should see the live camera feed with green directional arrows and floating info cards (train / time). The direction cluster uses counter-rotation and counter-parallax relative to device motion so it stays visually steadier than the feed; the top train banner and bottom cards stay fixed in screen space.

### Technical Requirement 6: Step-by-Step 2D Navigation Mode
#### How to find:
* Navigate to the "TunnelVision" folder (yes, it should be labeled "TunnelVision, Requirement 6" or something, but Alain forgot to do this for this particular requirement)
* The code for this requirement's implementation is under /hci-assignment-5/TunnelVision/TunnelVision/ContentView.swift
#### How to run:
* Open the /TunnelVision/TunnelVision folder as a "Project" in XCode, and then build by pressing the play arrow in XCode's top left navbar. This should open an iOS simulator which allows you to click through this requirement's prototype

### Technical Requirement 4: Pedometer-Based Indoor Positioning
#### How to find:
* Navigate to the "tunnelvision-req-4" folder 
* The code for this requirement's implementation is under tunnelvision-req-4/tunnelvision-req-4/ContentView.swift as well as tunnelvision-req-4/tunnelvision-req-4/PedometerViewModel.swift
#### How to run:
* Open the /tunnelvision-req-4/tunnelvision-req-4 folder as a "Project" in XCode, and then build by pressing the play arrow in XCode's top left navbar. Make sure the device to build on that you select is a real iPhone (the iOS simulator doesn't have a pedometer). To do this you will need to:
1. Enable Developer Mode on your iPhone
2. Allow your own personal Apple ID's developer profile on your phone (VPNs and profiles)
3. When the app asks for it, allow health and fitness data to be used by the app
4. build the app onto your phone
5. try walking around and seeing the step count increase and the directions change accordingly!

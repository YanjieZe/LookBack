<p align="center">
  <img src="Assets/lookback-logo-v1.png" width="144" alt="LookBack logo">
</p>
<h1 align="center">LookBack · 回望</h1>
<p align="center">Look away. Your screen blurs. Look back. Carry on.</p>
<p align="center"><a href="README.zh-CN.md">简体中文</a> · macOS 14+ · Swift / AppKit · MIT</p>

LookBack is a native Mac app that uses **AirPods head tracking** to blur your screen when you turn away. It runs in its own window, with a Dock icon and controls for connection, calibration, sensitivity, and timing.

**No camera. No account. No cloud processing.** It estimates head orientation, not eye gaze.

## Features

- Blur across connected displays when you turn left, right, up, or down; clear the screen when you return.
- One-click calibration to define your forward-facing pose.
- Adjustable trigger angle (**15–60°**) and delay (**0.2–2 seconds**).
- Live head angles, motion permission, headphone connection status, and received sample count.
- Two-second blur preview, pause/resume, and a one-minute break.
- Close **×** to hide the window and keep tracking. Click the Dock icon to reopen. **⌘Q** quits and removes the overlay.
- The control window stays readable above the blur, and the overlay does not intercept mouse input.

## Requirements

- macOS 14 Sonoma or later.
- Head-tracking-capable AirPods, such as AirPods Pro, AirPods 3/4, or AirPods Max.
- AirPods worn and connected to **this Mac**.
- Motion & Fitness permission for LookBack.
- To build: Apple Command Line Tools and a Swift compiler supporting the macOS 14 APIs. Full Xcode and third-party packages are not required.

## Build and install

Install the Command Line Tools if needed:

```sh
xcode-select --install
```

Clone the repository, then build:

```sh
git clone https://github.com/YanjieZe/LookBack.git
cd LookBack
./build.sh
open /Applications/LookBack.app
```

The build installs or updates **`/Applications/LookBack.app`**. Quit any running copy with **⌘Q** before installing an update. The name and install location stay fixed so updates do not create duplicate apps in search. Compilation intermediates live in `.build.noindex/`.

The local build uses ad-hoc signing and is not notarized. Rebuilding can cause macOS to request Motion & Fitness permission again. Writing to `/Applications` requires appropriate filesystem permissions.

To compile without replacing your installed app, or run the trigger tests:

```sh
./build.sh --check
./test.sh
```

## First run

1. Wear your AirPods and connect them to the Mac.
2. Click **连接 AirPods** (Connect AirPods) and allow Motion & Fitness access.
3. Wait for the sample count to increase and the angles to update.
4. Face the screen and click **校准当前朝向** (Calibrate).
5. Turn your head away, then look back.

The interface is currently in Simplified Chinese. By default, a turn greater than **15°** for **0.6 seconds** activates the overlay. Returning below **7°** for **0.25 seconds** clears it. This margin prevents flickering near the threshold.

Recalibrate after moving your chair or reconnecting your headphones. Settings and calibration are currently session-only. **Esc**, while the app is focused, pauses detection for one minute. Pausing leaves motion collection running; quitting stops it.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Connected, but **0 samples** | Bluetooth audio connection alone does not confirm motion streaming. Put both earbuds in the case, close it for about 10 seconds, wear them again, reconnect to the Mac, then click reconnect. |
| Calibration is disabled | Wait for fresh motion samples. Calibration requires a sample from within the last second. |
| Permission denied | Enable LookBack under System Settings → Privacy & Security → Motion & Fitness, then reconnect or relaunch. |
| Data stops unexpectedly | Check whether AirPods switched to your iPhone or another device. Return the connection to your Mac. |
| Too many accidental blurs | Increase the trigger angle or delay, then recalibrate while facing the screen. |
| Dimming instead of blur | The WindowServer blur function may be unavailable or fail on your macOS version. LookBack falls back to dimming. |
| Cannot find the window | Click the LookBack Dock icon or open `/Applications/LookBack.app`. Closing the window hides it. |

If motion data stops for more than about two seconds, LookBack clears the overlay. A new connection requires calibration again.

## Privacy and limitations

- The app uses CoreMotion headphone orientation data. It does not request camera, microphone, or screen-recording access.
- There are no app network requests, analytics, accounts, or stored motion recordings. The sample counter is held in memory; operational connection events are written to the local system log.
- Head direction is not eye gaze or proof of attention. This is a convenience tool, not a privacy screen or screen lock.
- Live blur relies on the **undocumented `CGSSetWindowBackgroundBlurRadius` WindowServer function**, inherited from HeadOrbit. OS updates may break it; this implementation is not suitable for direct Mac App Store submission.
- AirPods streaming reliability can vary. Multiple displays, Spaces, and exclusive fullscreen configurations may need additional testing.

## Development

```text
Sources/
  main.swift          AppKit window, controls, overlay, and app lifecycle
  HeadTracker.swift   CoreMotion session, permissions, reconnect handling
  HeadPose.swift      Calibrated orientation model
  AudioRoute.swift    Bluetooth audio device detection
  DwellTrigger.swift  Dwell and hysteresis state machine
  WindowBlur.swift    WindowServer blur adapter
Tests/main.swift      Trigger behavior tests
Resources/AppIcon.icns
Assets/               Logo source and generation notes
```

Build and trigger tests have passed locally on Apple Silicon. AirPods streaming, calibration, and turn-away behavior have also been exercised with a real device. The automated tests cover the trigger state machine; they do not simulate Bluetooth hardware or validate WindowServer rendering.

Contributions are welcome when the repository is shared. For bugs, include your macOS version, AirPods model, displayed permission/connection state, sample count behavior, and reproduction steps. Do not include credentials or unredacted personal logs. Before submitting changes, run `./build.sh --check` and `./test.sh`.

## Credits and license

LookBack builds on [HeadOrbit by Cogria-AI](https://github.com/Cogria-AI/HeadOrbit), based on commit `344eaf95db628e1947ae90894960d436af55f117`. Its motion tracking, pose, audio route, dwell trigger, and blur adapter code are reused or adapted under MIT. The original notice is preserved in [HeadOrbit-LICENSE](HeadOrbit-LICENSE).

LookBack's additions include the standalone AppKit interface, Dock lifecycle, diagnostics, connection handling changes, and application branding. The logo was created with an AI image-generation tool; the [prompt and asset notes](Assets/logo-notes.md) are included.

Released under the [MIT License](LICENSE). Repository visibility is managed separately: this repository is initially private.

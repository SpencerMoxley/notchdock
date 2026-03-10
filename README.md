# NotchDock

A macOS menu-bar app that turns the MacBook Pro notch into a Dynamic Island-style panel. Hover over the notch and it expands smoothly — showing your current track, playback controls, and a scratch pad.

![NotchDock preview](preview.png)

---

## Features

- **Dynamic Island animation** — the panel morphs fluidly from the notch pill to a full expanded view using a spring-driven custom shape
- **Now Playing** — live track title, artist, album art, and playback controls (prev / play-pause / next) via the private MediaRemote framework
- **Scratch pad** — a lightweight notes field that lives next to the player
- **File Tray** — drop files into the Tray tab for quick access
- **Bezel blend** — the panel's top edge is nudged behind the physical display bezel so it looks like a natural extension of the screen hardware
- **Menu-bar safe** — transparent areas of the panel are click-through, so menu-bar items are always reachable

---

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel MacBook Pro with a notch

---

## Building

No package manager or external dependencies required.

```bash
git clone https://github.com/SpencerMoxley/notchdock.git
cd notchdock

xcodebuild -scheme NotchDock -configuration Debug build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

open ~/Library/Developer/Xcode/DerivedData/NotchDock-*/Build/Products/Debug/NotchDock.app
```

Or open `NotchDock.xcodeproj` in Xcode and hit Run.

---

## How it works

| Component | Role |
|-----------|------|
| `NotchWindowController` | Borderless `NSWindow` fixed at 480×182 pt, nudged 7 pt above the screen edge. `PassthroughView` wrapper makes non-pill areas click-through when collapsed. |
| `NotchExpansionShape` | `Shape & Animatable` — interpolates width, height, and corner radii from a 162×32 pill to the full panel each animation frame. |
| `NotchContainerView` | Root SwiftUI view. Owns `MediaManager`, clips everything with `NotchExpansionShape`, drives the spring animation. |
| `MediaManager` | Loads the private `MediaRemote.framework` at runtime to read Now Playing info and send playback commands. |
| `ExpandedView` | Tab bar (Music / Tray) + side-by-side `MediaView` and `NotesView`. |

---

## Notes

- Uses the **private MediaRemote framework** for Now Playing data. This is the same mechanism used by the Control Center and Lock Screen — no extra permissions are needed, but Apple could change the API in a future OS release.
- The app is intentionally **unsigned** for local development. To distribute it you would need a Developer ID certificate and notarisation.

---

## License

MIT

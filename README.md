# Clarity

A native macOS menu-bar utility for focused, distraction-free task management.

Clarity lives in your menu bar and opens a compact, glass popover where you can
capture tasks, schedule gentle "nudges," and run a Pomodoro timer — without ever
opening a full application window.

Built entirely with SwiftUI, SwiftData, and App Intents on the current macOS SDK.

## Features

- **Menu-bar first** — no Dock icon, no normal window. Click the menu bar icon to
  open the popover; click outside to dismiss.
- **Native glass** — the popover uses the system's native material (Liquid Glass on
  macOS 26, standard popover vibrancy on earlier versions), so it blurs and tints
  whatever is behind it and adapts to light/dark/automatic appearance.
- **Tasks** — create, complete, and delete tasks. SwiftData persistence keeps your
  list intact across launches.
- **Nudges** — attach a repeating reminder interval (15 min, 30 min, 60 min, or 2 h)
  to any task. Reminders are scheduled, rescheduled, and cancelled automatically.
- **Smart ordering** — active tasks first, completed tasks second, newest first within
  each group.
- **Pomodoro** — Focus 25 / Short Break 5 / Long Break 15 with Start, Pause, Reset,
  accurate wall-clock timing, background accuracy, completion notifications, and
  automatic session transitions.
- **Siri & Shortcuts** — create tasks hands-free with the *Add Task to Clarity* App
  Intent and App Shortcut.

## Requirements

- macOS 14.0 or later (Liquid Glass appears automatically on macOS 26)
- Xcode 16 or later (the project was built and verified with Xcode 26)

## Installation

### Homebrew

```bash
brew tap purvanshh/clarity
brew install --cask clarity
```

### Allow the app to run (required — unsigned build)

Clarity is distributed as an **ad-hoc signed** (unsigned) app because it isn't
backed by an Apple Developer certificate. macOS Gatekeeper quarantines downloaded
apps, so on first launch you may see *"Clarity can't be opened because Apple cannot
check it for malicious software."*

Remove the quarantine attribute and launch it:

```bash
xattr -cr /Applications/Clarity.app
open -a Clarity
```

> `xattr -cr` strips the `com.apple.quarantine` attribute that macOS adds to every
> downloaded file. It's a one-time step per download — you don't need to repeat it
> unless you reinstall a fresh copy.

To launch straight from the build folder (development), use the same command with
the path to your `.app`:

```bash
xattr -cr "$(pwd)/DerivedData/Build/Products/Debug/Clarity.app"
open "$(pwd)/DerivedData/Build/Products/Debug/Clarity.app"
```

## Getting Started

1. Clone the repository.
2. Open `Clarity.xcodeproj` in Xcode.
3. Select the **Clarity** scheme and press **Run** (`⌘R`).

The app installs itself as a menu-bar accessory. No window opens at launch; click
the checkmark icon in the menu bar to reveal the popover.

### Build from the command line

```bash
xcodebuild -project Clarity.xcodeproj \
  -scheme Clarity \
  -configuration Debug \
  -derivedDataPath ./DerivedData \
  build
```

## Usage

| Action | How |
| --- | --- |
| Add a task | `+` button, or `⌘N` |
| Complete / reopen a task | Click the circle, or right-click the task |
| Change a nudge | Right-click the task → *Change Nudge* |
| Delete a task | Right-click the task → *Delete* |
| Switch views | Segmented control in the footer, `⌘1` / `⌘2` |
| Pomodoro controls | Space to start/pause, `⇧⌘R` to reset |
| Quit | Power button in the footer |

### Siri

> "Add a task to Clarity"
> "Create a task in Clarity"

You can also pass a nudge interval so the task starts reminding you immediately.

## Architecture

```
Clarity/
├── App/               # Entry point, app state, menu commands
├── Components/        # Reusable UI (native glass surface)
├── Intents/           # Siri / App Intents (AddTaskIntent)
├── Models/            # SwiftData models and value types
├── Services/          # Persistence, notifications, reminders, Pomodoro
└── Views/
    ├── Tasks/         # Task list, row, and inline composer
    └── Pomodoro/      # Timer and controls
```

Key decisions:

- **SwiftData** is the single persistence layer (`ClarityTask`), shared by the UI
  and the Siri intent through `ClarityPersistence.makeContainer()`.
- **Menu bar** is implemented with `MenuBarExtra` (`.window` style) plus `LSUIElement`
  and the `.accessory` activation policy — no `NSStatusItem` hacks, no normal window.
- **Glass** relies on the system's native material. The popover window is *not*
  manually cleared or overlaid with a custom `NSVisualEffectView`; inner surfaces use
  SwiftUI materials (`GlassSurface`).
- **Concurrency-safe SwiftData** — task ordering avoids sorting `isCompleted`
  through `@Query`/`SortDescriptor` (which triggers `Bool` `Comparable` and
  `KeyPath` `Sendable` diagnostics under strict concurrency). Instead, tasks are
  queried by `createdAt` and partitioned in-memory.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is provided as-is for personal and educational use.

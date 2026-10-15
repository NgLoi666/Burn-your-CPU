# LiquidNotes

A small, standalone SwiftUI notes app used to demonstrate two things:

1. **iOS 26 UI / orientation handling** — the `Info.plist` keys that control
   Liquid Glass compatibility, orientation support, and Assistive Access.
2. **Producing an unsigned `.ipa`** — building an archive with signing disabled
   and repackaging `Payload/` into an `.ipa` from the command line.

It is intentionally trivial (a list of local notes) so the interesting parts are
the plist configuration and the packaging workflow.

> Not affiliated with any jailbreak, exploit, or payload project.

## Requirements

- macOS with **Xcode 26** (iOS 26 SDK).
- The `iOS 26.0` deployment target (change `IPHONEOS_DEPLOYMENT_TARGET` /
  `project.yml` if you need to build for older OSes — the app also compiles for
  iOS 17+).
- Optional: [XcodeGen](https://github.com/yonaskolb/XcodeGen)
  (`brew install xcodegen`) if you prefer to regenerate the project from
  `project.yml`.

## Layout

```
LiquidNotes/
├── LiquidNotes.xcodeproj/          # Hand-written project (no XcodeGen required)
│   └── xcshareddata/xcschemes/     # Shared scheme so `xcodebuild -scheme` works headlessly
├── LiquidNotes/
│   ├── LiquidNotesApp.swift        # @main, wires up AppDelegate + NoteStore
│   ├── AppDelegate.swift           # supportedInterfaceOrientationsFor
│   ├── OrientationController.swift # Runtime orientation lock (@Observable)
│   ├── ContentView.swift           # Note list
│   ├── NoteEditorView.swift        # Add/edit a note
│   ├── SettingsView.swift          # Orientation toggle + iOS 26 key readout
│   ├── Note.swift                  # Model
│   ├── NoteStore.swift             # JSON-backed storage
│   ├── Info.plist                  # iOS 26 UI / orientation keys
│   └── Assets.xcassets/
├── project.yml                     # Alternative XcodeGen spec
├── .github/workflows/build.yaml     # CI: build + upload the unsigned IPA
└── scripts/build_unsigned_ipa.sh   # Unsigned IPA builder
```

## iOS 26 UI / orientation keys

All of the following live in `LiquidNotes/Info.plist`.

| Key | Value here | Purpose |
| --- | --- | --- |
| `UISupportedInterfaceOrientations` | Portrait, Landscape L/R | Default orientations on iPhone. |
| `UISupportedInterfaceOrientations~ipad` | all four | Default orientations on iPad. |
| `UIDesignRequiresCompatibility` | `NO` | `NO` adopts the **iOS 26 Liquid Glass** design. Set `YES` to keep the pre-26 appearance. |
| `UISupportsFullScreenInAssistiveAccess` | `YES` | iOS 17+: allow full-screen use in Assistive Access. |

### Runtime orientation locking

`Info.plist` only sets the *default* set of orientations. To change them while
the app is running, implement
`application(_:supportedInterfaceOrientationsFor:)` on the app delegate (see
`AppDelegate.swift`) and return a dynamic mask. `OrientationController` holds
that mask and exposes a "Lock orientation" toggle in **Settings**. When the
toggle changes, the controller calls:

```swift
scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
```

Notes:

- `requestGeometryUpdate` can fail if the device is physically held in an
  orientation the mask forbids; that is expected and non-fatal.
- `UIViewController.attemptRotationToDeviceOrientation()` is deprecated since
  iOS 16 — prefer `setNeedsUpdateOfSupportedInterfaceOrientations()`.
- On iPadOS 26 there is no separate orientation lock in the same sense as
  iPhone; apps that participate in the window-based model resize rather than
  rotate. This demo keeps `TARGETED_DEVICE_FAMILY = "1,2"` and declares all four
  iPad orientations.
- `UIRequiresFullScreen` is deprecated and intentionally omitted.

## Build & run (Xcode)

1. Open `LiquidNotes.xcodeproj` in Xcode 26.
2. Select the `LiquidNotes` scheme and a simulator or device.
3. Run (⌘R).

To generate the project from `project.yml` instead:

```bash
brew install xcodegen
xcodegen generate    # writes LiquidNotes.xcodeproj
```

(Use one source of truth: editing the hand-written `.xcodeproj` and then running
`xcodegen generate` will overwrite it.)

## Build an unsigned IPA

On macOS with Xcode installed:

```bash
chmod +x scripts/build_unsigned_ipa.sh
scripts/build_unsigned_ipa.sh            # scheme= LiquidNotes, config=Release
```

This runs, in effect:

```bash
xcodebuild \
  -project LiquidNotes.xcodeproj \
  -scheme LiquidNotes \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/LiquidNotes.xcarchive \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  clean archive

mkdir -p build/export/Payload
cp -R build/LiquidNotes.xcarchive/Products/Applications/LiquidNotes.app build/export/Payload/
(cd build/export && zip -qry ../LiquidNotes-unsigned.ipa Payload)
```

Output: `build/LiquidNotes-unsigned.ipa`.

### Build in CI (GitHub Actions)

`.github/workflows/build.yaml` does the same thing on a macOS runner and uploads
the result as a build artifact.

- **Triggers:** pushes/PRs that touch the app, project, or `scripts/`, plus a
  manual **Run workflow** button.
- **Manual inputs:** `configuration` (`Release`/`Debug`) and
  `deployment_target` (defaults to `26.0`).
- **Runner:** `macos-15`, with `maxim-lobanov/setup-xcode` selecting the latest
  stable Xcode. If the selected Xcode does not ship the iOS 26 SDK, lower the
  `deployment_target` input (e.g. to `17.0`) or switch the runner label.
- **Artifact:** `LiquidNotes-unsigned-<run number>`, retained 14 days. Download
  it from the run's **Artifacts** section.

The workflow sets `IPHONEOS_DEPLOYMENT_TARGET` in the job environment, which the
build script forwards to `xcodebuild`.

### What "unsigned" means here

The archive is produced with code signing disabled, so the `.app` inside the IPA
has no valid signature. Such an IPA:

- **cannot be installed on a device as-is** — iOS requires a valid signature;
- is useful as a build artifact you then **re-sign** with your own certificate,
  e.g. Xcode (Product ▸ Archive ▸ Distribute), AltStore, Sideloadly, or
  `codesign` + `ldid`;
- is fine for inspecting the bundle contents (`unzip -l`).

## Limitations

- The project was authored on Windows; it has **not** been compiled with
  `xcodebuild` here. The Swift is straightforward SwiftUI, but expect to fix the
  occasional minor compiler complaint on first build.
- `IPHONEOS_DEPLOYMENT_TARGET = 26.0` requires the iOS 26 SDK. For older SDKs,
  lower it to 17.0 (the `@Observable` and `ContentUnavailableView` APIs need
  iOS 17+).
- The asset catalog ships without an actual app icon image, which produces a
  warning (not an error) at archive time.
- An unsigned IPA is not a distribution format; distribution requires a real
  signing identity and provisioning profile.

## License

MIT — this is a demo app; use it however you like.

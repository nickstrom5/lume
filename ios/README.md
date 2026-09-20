# Lume for iPhone (and iPhone Duo)

Native SwiftUI. Same product as [lumenow.app](https://lumenow.app): one photo, a glow score, sixty seconds.

Bundle ID: `app.lumenow.lume`  
Team: your paid Apple Developer account  
Minimum: iOS 27 · build with **Xcode 27.1 beta** (Duo SDK)

---

## While Xcode_27.1_beta.zip finishes

Do App Store Connect. Exact clicks: [CONNECT.md](CONNECT.md)

---

## After the zip lands (iMac)

1. Open the `.xip` (or unzip). Drag **Xcode 27.1 beta** into Applications. Keep the old Xcode.
2. Open **Xcode 27.1 beta** (not the old one). Install additional components. Accept the license.
3. **Xcode → Settings → Accounts** → your Apple ID → the paid team (not Personal Team).
4. **Window → Devices and Simulators → Simulators → +**
   - Device: **iPhone Duo**
   - OS: **iOS 27.1**
   - Create
5. Also keep an **iPhone 18 Pro** sim for the single-screen layout.

Then create the project (once):

1. File → New → Project → **iOS → App**
2. Product Name: `Lume`
3. Team: paid team
4. Organization Identifier: `app.lumenow`
5. Bundle Identifier must be `app.lumenow.lume`
6. Interface: **SwiftUI** · Language: **Swift** · Storage: **None**
7. Save next to this `ios/` folder, or save then replace the generated Swift with the files in `Lume/`

Delete the stock `ContentView.swift`. Add every `.swift` file in `Lume/` to the target. Add `Lume.storekit`. Add `Resources/still.jpg`, `scan-a.jpg`, `scan-b.jpg` (target membership on). Drop `Resources/icon-1024.png` onto AppIcon.

**Signing:** automatically, team = paid team.

**Info tab**

| Key | Value |
|---|---|
| Privacy — Camera Usage Description | `Lume uses the camera to read your glow score. Photos stay on this device.` |
| App Uses Non-Exempt Encryption | `NO` |

**Signing & Capabilities:** In-App Purchase (StoreKit). Push later.

**Scheme → Run:** iPhone 18 Pro first. Then iPhone Duo. Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration → `Lume.storekit` until live products exist.

Play. Sample path: **See a sample reading**. Duo: face left, ritual right.

---

## What this build does

- Onboarding (goal, concerns, skin, routine, sleep, age)
- Front camera scan + on-device score (glow / evenness / texture / calm)
- Sample photos if the sim has no camera
- Reveal → paywall (StoreKit 2, 7-day trial)
- Today / Scan / Ritual / Trend
- **ArrangementView** on iOS 27.1: primary = face, secondary = ritual. Collapses to one pane on a regular iPhone.
- `onHingeChange`: tent pose keeps the ritual on the lower half
- Restore purchases, delete my data, seed-for-review (hidden, 7 taps on the wordmark)

Not in v1: push reminder, share-card PNG export, live App Store screenshot slots for Duo (Apple said later this year — regular iPhone shots are enough).

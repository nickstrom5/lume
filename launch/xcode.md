# Xcode 27.1 beta is downloading. Do this now.

You have the paid Apple Developer team. The Duo SDK is the 1.9 GB zip (`Xcode_27.1_beta.xip`, build 27A9269). Needs **macOS Tahoe 26.6** on Apple silicon.

Native source is in `ios/` — SwiftUI Lume, bundle `app.lumenow.lume`.

---

## Right now (zip still going)

App Store Connect. Open [CONNECT.md](../ios/CONNECT.md) and create:

1. App ID `app.lumenow.lume`
2. New iOS app named Lume
3. Subscription group **Lume Plus**
   - `app.lumenow.lume.plus.yearly` · $39.99 · 7-day free trial
   - `app.lumenow.lume.plus.weekly` · $7.99 · 7-day free trial

Do not submit a binary yet.

---

## When the zip finishes

1. Double-click `Xcode_27.1_beta.xip`. Wait for it to expand (~same size again).
2. Drag **Xcode 27.1 beta** into Applications. Keep the old Xcode.
3. Open **Xcode 27.1 beta**. Install additional components. Accept the license.
4. Settings → Accounts → paid team (not Personal Team).
5. Window → Devices and Simulators → Simulators → **+**
   - Device type: **iPhone Duo**
   - OS: **iOS 27.1**
   - Create
6. Also create **iPhone 18 Pro** if it is missing.

If Duo is not in the device list, the 27.1 components did not finish. Xcode → Settings → Components → iOS 27.1.

---

## New project (once)

File → New → Project → iOS → App

| Field | Value |
|---|---|
| Product Name | Lume |
| Team | paid team |
| Organization Identifier | `app.lumenow` |
| Bundle ID | `app.lumenow.lume` |
| Interface | SwiftUI |
| Storage | None |
| Language | Swift |

Delete `ContentView.swift`. Add every file in `ios/Lume/` to the target (the `.swift` files, `PrivacyInfo.xcprivacy`, `Assets.xcassets`, `Resources/*.jpg`). Add `ios/Lume.storekit`.

Info tab:

- Privacy — Camera Usage Description: `Lume uses the camera to read your glow score. Photos stay on this device.`
- App Uses Non-Exempt Encryption: `NO`

Signing: Automatic, paid team. Capability: In-App Purchase.

Scheme → Run → Options → StoreKit Configuration → `Lume.storekit`

Run on **iPhone 18 Pro** first. Then **iPhone Duo**. Sample path: **See a sample reading**. Seven taps on the wordmark seeds review state for screenshots.

---

## After it boots

Product → Archive → Distribute App → App Store Connect → Upload.

Internal TestFlight to yourself. Screenshots from the 18 Pro sim (6.7") using seeded state: Today, Scan, Ritual, Trend.

Paste here: Welcome window on 27.1, **or** Duo sim exists, **or** first Run succeeded, **or** the compiler error if ArrangementView’s API shifted.

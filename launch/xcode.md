# Xcode is downloaded. Do this on the iMac tonight.

You do not need Lume’s source yet. First launch + Apple ID + the $99 enrollment are the wait. The wrap happens after the team ID exists.

Bundle ID when we make the real project: `app.lumenow.lume`
Camera string: `Lume uses the camera to read your glow score. Photos stay on this device.`

---

## 1. First launch (do not skip this)

1. Open **Xcode** from Applications. Not a leftover installer window.
2. If it asks to install **additional required components**, click **Install**. This can take 10–40 minutes. Leave the Mac open.
3. Accept the license.
4. If a platforms sheet appears: keep **iOS**. Install. You do not need watchOS, tvOS, or visionOS.

Done when the Welcome window appears: “Create a new Xcode project / Clone git repository / Open existing”.

## 2. iOS 26 simulator

1. **Xcode → Settings → Components** (sometimes still labelled Platforms).
2. Next to **iOS 26.x**, click **Get** if it isn’t already installed.
3. **Window → Devices and Simulators → Simulators**. You should see an iPhone 16 or 17 on iOS 26.

If the list is empty: **+** → Device Type **iPhone 16** (or 17) → OS **iOS 26** → Create.

## 3. Apple ID in Xcode

1. **Xcode → Settings → Accounts**
2. **+** → **Apple ID**
3. Sign in with the same Apple ID you will enroll as a developer.

Until the $99 program is approved, the team will say **Personal Team**. That’s enough to run on a simulator. A physical iPhone and TestFlight need the paid program.

## 4. Smoke test (proves the Mac is ready)

1. Welcome window → **Create a new Xcode project**
2. **iOS → App** → Next
3. Product Name: `LumeSmoke`  
   Team: your Apple ID  
   Organization Identifier: `app.lumenow`  
   Bundle ID becomes `app.lumenow.LumeSmoke`  
   Interface: **SwiftUI**  
   Storage: **None**  
   Language: **Swift**
4. Save it on the Desktop. Throw it away later.
5. Top bar: pick an **iPhone 16 / 17** simulator. Press **Play**.

You should get a blank white app. If the sim boots, Xcode is done.

Camera in the simulator is a fake feed. Glow scans need a **physical iPhone** later. The sim is still required for screenshots and layout.

## 5. Enroll in Apple Developer (start this tonight — it can sit for 24–48 hours)

On the **iPhone**, with the same Apple ID:

1. App Store → install **Apple Developer**
2. Open it → **Account** → **Enroll**
3. Entity: **Individual** (not Company, unless you already have an LLC and D-U-N-S)
4. Legal name must match the ID Apple has on that Apple ID
5. Pay **$99 USD** for one year

Apple emails when the account is active. Then App Store Connect unlocks at https://appstoreconnect.apple.com

Do not create the real Lume app record until that email arrives.

## 6. What you wait for vs what we do

| You | Us, after the team ID exists |
|---|---|
| Components + iOS 26 sim | Capacitor wrap of Lume (`app.lumenow.lume`) |
| Apple ID in Xcode | Camera permission string |
| Developer enrollment ($99) | Yearly $39.99 + weekly $7.99 + 7-day trial |
| Smoke-test sim boots | TestFlight, screenshots, submit |

Paste here when: the Welcome window is up, **or** the sim booted, **or** Apple’s enrollment email arrived.

# App Store Connect — do this while the 1.9 GB zip downloads

Open [appstoreconnect.apple.com](https://appstoreconnect.apple.com) signed into the **paid** Apple ID.

## 1. App ID

[developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers/list)

- **+** → App IDs → App → Continue
- Description: `Lume`
- Bundle ID: **Explicit** → `app.lumenow.lume`
- Capabilities: none required for v1 (IAP is automatic on a paid team)
- Register

If `app.lumenow.lume` already exists from the smoke test, use that. Do **not** create a second ID.

## 2. New app record

Apps → **+** → New App

| Field | Value |
|---|---|
| Platforms | iOS |
| Name | `Lume` |
| Primary language | English (U.S.) |
| Bundle ID | `app.lumenow.lume` |
| SKU | `lume-ios` |
| User access | Full Access |

## 3. Listing (App Information + Version)

Paste from `launch/listing.md`. Short version:

- Name: `Lume: Daily Glow Coach`
- Subtitle: `One photo. Sixty seconds.`
- Category: Health & Fitness · Lifestyle
- Age: 12+
- Privacy policy: `https://lumenow.app/privacy.html`
- Support: `https://lumenow.app/support.html`
- Marketing: `https://lumenow.app`
- Copyright: `2026 Nick Soderstrom`

Description, keywords, promo, review notes: `launch/listing.md`.

## 4. Subscriptions (the money)

Monetization → Subscriptions → **Create Subscription Group**

- Group name: `Lume Plus`
- App name localization: `Lume Plus`

Two auto-renewing products:

| | Yearly | Weekly |
|---|---|---|
| Product ID | `app.lumenow.lume.plus.yearly` | `app.lumenow.lume.plus.weekly` |
| Reference name | Lume Plus Yearly | Lume Plus Weekly |
| Duration | 1 Year | 1 Week |
| Price | $39.99 (USA) | $7.99 (USA) |
| Intro offer | 7-day free, new subscribers, once | 7-day free, new subscribers, once |

Localization (both): Display name `Lume Plus`. Description `Daily glow coach. One photo, a score, a sixty-second ritual.`

Submit the group for review with the first binary. Products stay **Ready to Submit** until then.

## 5. App Privacy

App Privacy → Get Started

- Data collected: **Photos or Videos** (App Functionality, not linked, not used for tracking). Note: used to take the scan; the image stays on device.
- Product Interaction (App Functionality, not linked, not tracking): streak, ritual checkmarks, scores on-device.
- No tracking. No third-party analytics in v1.

## 6. Stop. Wait for Xcode.

Do **not** upload a binary yet. Do **not** submit for review. Identifiers + listing + products are enough until the Duo sim boots Lume.

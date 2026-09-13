# SayThis

Native iPhone English dictionary: look up a word, see IPA + a simple respelling, hear US or UK speech.

Lookups use [Datamuse](https://www.datamuse.com/api/) (no API key). Playback is on-device `AVSpeechSynthesizer`.

Same TestFlight path as [Shift](https://github.com/lefthandmagic/shift) and [Fitbit Health Sync](https://github.com/lefthandmagic/fitbit-health-sync): `xcodegen` + GitHub Action **iOS Release Upload** → App Store Connect.

## Generate Xcode project

```bash
brew install xcodegen
xcodegen generate
open SayThis.xcodeproj
```

Signing: team `DNQVHANQBU`, bundle `com.praveenmurugesan.SayThis`.

## TestFlight

Internal only (Praveen). Do not add testers, groups, or a Public Link.

Create the App Store Connect **app record once** in the web UI (API keys cannot CREATE apps):

- https://appstoreconnect.apple.com → My Apps → **+** → iOS
- Name: **SayThis** (if taken, use **SayThis Dictionary**; the phone icon can still say SayThis)
- Bundle ID: `com.praveenmurugesan.SayThis`
- SKU: `saythis-001`

Then upload with the same secrets as Fitbit Health Sync:

GitHub → **lefthandmagic/fitbit-health-sync** → Actions → **SayThis TestFlight** → Run workflow (`upload_to_testflight = true`).

Or from this repo after copying those secrets: Actions → **iOS Release Upload**.

Secrets (already on `fitbit-health-sync`):

- `APPSTORE_KEY_ID`
- `APPSTORE_ISSUER_ID`
- `APPSTORE_PRIVATE_KEY`
- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `KEYCHAIN_PASSWORD`

No `BUILD_PROVISION_PROFILE_BASE64` — the workflow generates the SayThis profile with `sigh`.

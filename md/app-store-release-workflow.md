# App Store Release Workflow

This file records the release path used for `极简日历-倒数日-日程提醒与桌面小组件` after the first complete App Store Connect upload.

## Goal

Ship a privacy-friendly iOS calendar app to 39 App Store locales with localized app names, metadata, screenshots, support/privacy URLs, a valid binary build, and a clean GitHub record.

## Locale Scope

The launch locale set is:

`ar-SA, ca, cs, da, de-DE, el, en-AU, en-CA, en-GB, en-US, es-ES, es-MX, fi, fr-CA, fr-FR, he, hi, hr, hu, id, it, ja, ko, ms, nl-NL, no, pl, pt-BR, pt-PT, ro, ru, sk, sv, th, tr, uk, vi, zh-Hans, zh-Hant`

Expected store assets:

- 39 metadata folders under `fastlane/metadata`.
- 39 localized app names through `InfoPlist.strings`.
- 390 screenshot PNGs under `fastlane/screenshots`, 5 iPhone plus 5 iPad per locale.

## One-Time Setup

1. Configure bundle ids:
   - App: `com.daniao.jijiancalendar`
   - Widget: `com.daniao.jijiancalendar.widget`
2. Configure capabilities:
   - App Groups if used by widgets.
   - iCloud container: `iCloud.com.daniao.jijiancalendar`.
   - Notifications, EventKit, App Intents, and Widget extension entitlements.
3. Configure signing:
   - Team: `QFZ87PFLK4`
   - Automatic signing is acceptable for this solo release workflow.
4. Keep the App Store Connect `.p8` outside the repo:
   - Current local path: `/Users/ll/Desktop/AuthKey_JD5G4LG5XN.p8`
   - Never commit the private key body.

## Generate Assets

1. Generate or update localized strings and metadata.
2. Generate app icon assets.
3. Generate screenshots with the simulator screenshot workflow.
4. Validate:

```sh
node scripts/validate_metadata.mjs
```

Expected result:

```text
Metadata OK for 39 locales.
```

Also check screenshot counts:

```sh
find fastlane/screenshots -mindepth 1 -maxdepth 1 -type d | wc -l
find fastlane/screenshots -name '*.png' | wc -l
```

Expected counts are `39` and `390`.

## Lessons Learned

- Finish localization before screenshots. Store metadata, app display names, in-app strings, privacy/support pages, and screenshot text all need to agree before capture.
- Treat App Store Connect as eventually consistent. Screenshot upload and build processing can show transient server errors or delays; trust the final Fastlane success marker and API verification rather than the first temporary warning.
- Verify online state after every upload. Local files can be correct while App Store Connect still has empty URLs, missing fields, or an old selected build.
- Keep credentials out of the repo. The `.p8` file path, key id, and issuer id are enough for repeatable automation; the private key body and review contact details stay local or in environment variables.
- Separate upload from submission. Metadata, screenshots, URLs, age rating, privacy answers, and valid build selection can all be prepared without submitting for review.

## GitHub Support And Privacy URLs

The App Store requires public support and privacy URLs. For this app they are stored in:

- `md/privacy.md`
- `md/support.md`

Each locale must include:

- `fastlane/metadata/<locale>/privacy_url.txt`
- `fastlane/metadata/<locale>/support_url.txt`

Current URL pattern:

```text
https://github.com/jok9580955/jijian-calendar-ios/blob/codex/app-store-localization-upload/md/privacy.md
https://github.com/jok9580955/jijian-calendar-ios/blob/codex/app-store-localization-upload/md/support.md
```

Commit and push URL changes before uploading metadata so App Store Connect points at public pages.

## Upload Metadata

Use `fastlane ios upmeta`. For a first-version app, include review contact environment variables so Fastlane can create App Review information and avoid the `No data` review-detail failure.

```sh
APP_REVIEW_FIRST_NAME=lei \
APP_REVIEW_LAST_NAME=liu \
APP_REVIEW_PHONE='<review phone>' \
APP_REVIEW_EMAIL='<review email>' \
APP_REVIEW_NOTES='本 App 为离线隐私友好的日历、倒数日、日程提醒和桌面小组件工具，无需登录，无需演示账号。' \
FASTLANE_SKIP_UPDATE_CHECK=1 \
FASTLANE_DISABLE_COLORS=1 \
fastlane ios upmeta
```

Completion gate:

- Fastlane exits successfully.
- App Store Connect API confirms 39 version localizations and 39 app-info localizations.
- `name`, `subtitle`, `description`, `keywords`, `privacy_url`, and `support_url` are non-empty online.

Important Apple limits:

- `subtitle.txt` max 30 characters.
- `keywords.txt` max 100 characters.
- `promotional_text.txt` max 170 characters.

## Upload Screenshots

Run:

```sh
FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_DISABLE_COLORS=1 fastlane ios uppic
```

Completion gate:

- Fastlane prints `Successfully uploaded screenshots to App Store Connect`.
- API verification shows each locale has:
  - `APP_IPHONE_67: 5`
  - `APP_IPAD_PRO_3GEN_129: 5`

Known Apple behavior:

- App Store Connect can return transient screenshot-processing `500` errors.
- Let Fastlane retry while it is still making progress.
- A missing screenshot warning can recover on retry; judge by the final success marker and API counts.

## Build And Upload Binary

Archive:

```sh
rm -rf .build/AppStoreArchive.xcarchive .build/AppStoreExport
xcodebuild \
  -project '极简日历-倒数日-日程提醒与桌面小组件.xcodeproj' \
  -scheme '极简日历-倒数日-日程提醒与桌面小组件' \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath .build/AppStoreArchive.xcarchive \
  -allowProvisioningUpdates \
  -authenticationKeyPath '/Users/ll/Desktop/AuthKey_JD5G4LG5XN.p8' \
  -authenticationKeyID 'JD5G4LG5XN' \
  -authenticationKeyIssuerID 'f68594d0-23a9-480d-8f1d-6c84b40bf664' \
  archive
```

Upload:

```sh
xcodebuild \
  -exportArchive \
  -archivePath .build/AppStoreArchive.xcarchive \
  -exportPath .build/AppStoreExport \
  -exportOptionsPlist scripts/export_options_app_store.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath '/Users/ll/Desktop/AuthKey_JD5G4LG5XN.p8' \
  -authenticationKeyID 'JD5G4LG5XN' \
  -authenticationKeyIssuerID 'f68594d0-23a9-480d-8f1d-6c84b40bf664'
```

Completion gate:

- Archive prints `** ARCHIVE SUCCEEDED **`.
- Upload prints `Upload succeeded` and `** EXPORT SUCCEEDED **`.
- API verification shows the intended build in `VALID` processing state.

If upload fails because the bundle version was already used:

1. Increment `CURRENT_PROJECT_VERSION` only.
2. Keep `MARKETING_VERSION` unchanged unless the App Store version changes.
3. Re-archive and re-upload.
4. Select the newest `VALID` build on the App Store version.

For this release, build `1` already existed, so build `2` was uploaded and selected.

## App Store Connect Final Fields

Before adding for review, confirm:

- Privacy policy URL exists in App Privacy and all app-info localizations.
- Support URL exists in all version localizations.
- Copyright is set to `© 2026 lei liu`.
- Content rights are set to `DOES_NOT_USE_THIRD_PARTY_CONTENT`.
- Age rating answers are complete and evaluate to `4+`.
- Latest valid build is selected.
- Screenshots are present for iPhone and iPad.

App Privacy:

- Intended answer is "Data Not Collected".
- The config is committed in `fastlane/app_privacy_details.json`.
- Fastlane's privacy upload action requires Apple ID password or `FASTLANE_SESSION`; the `.p8` API key is not enough.
- If no Apple ID session is available, fill it manually in App Store Connect.

## API Verification Snippets

Verify metadata and URLs:

```sh
PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/Cellar/fastlane/2.233.1/libexec/bin:${HOME}/.local/share/fastlane/4.0.0/bin:$PATH" \
FASTLANE_INSTALLED_VIA_HOMEBREW=true \
GEM_HOME="${HOME}/.local/share/fastlane/4.0.0" \
GEM_PATH="${HOME}/.local/share/fastlane/4.0.0:/opt/homebrew/Cellar/fastlane/2.233.1/libexec" \
ruby - <<'RUBY'
require "spaceship"
token = Spaceship::ConnectAPI::Token.create(
  key_id: "JD5G4LG5XN",
  issuer_id: "f68594d0-23a9-480d-8f1d-6c84b40bf664",
  filepath: "/Users/ll/Desktop/AuthKey_JD5G4LG5XN.p8"
)
Spaceship::ConnectAPI.token = token
app = Spaceship::ConnectAPI::App.find("com.daniao.jijiancalendar")
version = app.get_edit_app_store_version
info = app.fetch_edit_app_info
puts "version=#{version.version_string} state=#{version.app_store_state}"
puts "version_locales=#{version.get_app_store_version_localizations.length}"
puts "app_info_locales=#{info.get_app_info_localizations.length}"
RUBY
```

Verify build and review blockers:

```sh
PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/Cellar/fastlane/2.233.1/libexec/bin:${HOME}/.local/share/fastlane/4.0.0/bin:$PATH" \
FASTLANE_INSTALLED_VIA_HOMEBREW=true \
GEM_HOME="${HOME}/.local/share/fastlane/4.0.0" \
GEM_PATH="${HOME}/.local/share/fastlane/4.0.0:/opt/homebrew/Cellar/fastlane/2.233.1/libexec" \
ruby - <<'RUBY'
require "spaceship"
token = Spaceship::ConnectAPI::Token.create(
  key_id: "JD5G4LG5XN",
  issuer_id: "f68594d0-23a9-480d-8f1d-6c84b40bf664",
  filepath: "/Users/ll/Desktop/AuthKey_JD5G4LG5XN.p8"
)
Spaceship::ConnectAPI.token = token
app = Spaceship::ConnectAPI::App.find("com.daniao.jijiancalendar")
version = app.get_edit_app_store_version
info = app.fetch_edit_app_info
age = info.fetch_age_rating_declaration
version_locs = version.get_app_store_version_localizations
info_locs = info.get_app_info_localizations
puts "content_rights=#{app.content_rights_declaration}"
puts "copyright=#{version.copyright}"
puts "selected_build=#{version.build&.version}:#{version.build&.processing_state}"
puts "age_rating=#{info.app_store_age_rating}"
puts "support_missing=#{version_locs.select { |l| l.instance_variable_get(:@support_url).to_s.strip.empty? }.map(&:locale).sort.join(',')}"
puts "privacy_missing=#{info_locs.select { |l| l.instance_variable_get(:@privacy_policy_url).to_s.strip.empty? }.map(&:locale).sort.join(',')}"
RUBY
```

## Submission Boundary

Uploading metadata, screenshots, support/privacy URLs, and binary builds does not mean submit for review.

Only submit after the user explicitly says to submit for review.

## Lessons Learned

- Online verification matters. Local files can be correct while App Store Connect has stale or missing fields.
- Fastlane metadata upload for a brand-new app may need review contact data from environment variables.
- App Store Connect screenshot processing can show scary `500` errors and still recover.
- Keep private keys out of the repo; commit only paths or workflow instructions.
- GitHub-hosted support and privacy pages are a practical lightweight option for solo apps.
- App Privacy details are special: current Fastlane support uses Apple ID login, not only App Store Connect API key auth.
- Build processing is asynchronous; wait for `VALID` before selecting or judging the upload.
- If Apple rejects a reused build number, bump `CURRENT_PROJECT_VERSION`, not the marketing version.

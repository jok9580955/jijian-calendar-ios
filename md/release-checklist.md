# Release Checklist

- For the full next-app sequence, follow `md/next-app-upload-steps.md`.
- Confirm Apple Developer capabilities for `com.daniao.jijiancalendar` and `com.daniao.jijiancalendar.widget`.
- Create the iCloud container `iCloud.com.daniao.jijiancalendar`.
- Confirm `fastlane/Fastfile` uses the App Store Connect API key path only, never the private key body.
- Run `node scripts/validate_metadata.mjs` before every metadata or screenshot upload.
- Confirm 39 metadata locales exist and each has `name.txt`, `subtitle.txt`, `keywords.txt`, `description.txt`, `privacy_url.txt`, and `support_url.txt`.
- Confirm screenshot count is 390 PNGs, 5 iPhone and 5 iPad screenshots per locale.
- Upload metadata with `fastlane ios upmeta`, including review contact env vars for first-version apps.
- Upload screenshots with `fastlane ios uppic`; allow Apple 500 retries if Fastlane later recovers and exits successfully.
- Verify online metadata, URLs, screenshot counts, selected build, and build processing state with App Store Connect API.
- Build archive with `xcodebuild archive`; export/upload with `scripts/export_options_app_store.plist`.
- If Apple says the bundle version was already used, increment only `CURRENT_PROJECT_VERSION`, rebuild, and upload again.
- Fill App Privacy as "Data Not Collected". `fastlane/app_privacy_details.json` documents the intended answer, but automatic upload requires an Apple ID password or `FASTLANE_SESSION`.
- Set content rights to "does not use third-party content", copyright to `© 2026 lei liu`, age rating to 4+, and select the latest valid build.
- Do not submit for review unless explicitly requested.

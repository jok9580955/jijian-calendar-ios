# Release Checklist

- Confirm Apple Developer capabilities for `com.daniao.jijiancalendar` and `com.daniao.jijiancalendar.widget`.
- Create the iCloud container `iCloud.com.daniao.jijiancalendar`.
- Replace `support@example.com` in support materials.
- Run `node scripts/validate_metadata.mjs`.
- Generate localized screenshots per locale before uploading screenshots.
- Upload metadata with `bundle exec fastlane ios upmeta`.
- Build and upload the binary only after App Store Connect app record, pricing, privacy nutrition labels, and screenshots are ready.

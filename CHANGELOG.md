# 1.0.2

- Remove all hardcoded branding — player is now fully neutral by default (no text, no watermark).
  Brand text, watermark, and top-bar visibility are opt-in via `NirmaanYoutubeHtmlConfig`.
- Update `youtube_explode_dart` constraint to `^3.1.0` (fixes pub.dev dependency score).
- Fix dartdoc angle-bracket warnings in `NirmaanPlayerIcon`.
- Fix unnecessary braces in string interpolations (mobile/macOS and Windows offline player).
- Fix homepage URL in `pubspec.yaml`.

# 1.0.1

- Added a complete runnable example application.
- Improved README documentation and setup instructions.
- Added macOS support files for the example app.
- Cleaned generated Flutter files from the repository.
- Updated package publishing configuration.
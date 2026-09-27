# SwiftFinder Phase 10

Implemented the requested product completion pass.

## Flutter
- Centralized SwiftFinder colors in `lib/config/colors.dart` with complete light/dark palettes.
- Reworked `lib/config/theme.dart` with consistent Material 3 surfaces, inputs, cards, buttons, borders, and typography behavior.
- Added `image_picker` and `file_picker`.
- Added authenticated multipart uploads in `ApiService`.
- Lost/found reports can upload up to 6 item images.
- Reports now include approximate time and contact preference.
- Report editing, status changes (found/returned/closed), and deletion are available to the owner.
- Claim submission supports an optional image/document attachment.
- Profile photo upload is supported.
- Forgot-password request and reset-token flow are available from the auth screen.
- Contact Poster now opens the returned conversation directly in ChatScreen.
- Notification icon changes between empty/active bell states and shows unread count.
- AuthProvider uses the typed `FinderUser` model.

## Laravel
- Added multipart profile photo endpoint.
- Added multipart claim supporting-file handling.
- Item update accepts additional uploaded images.
- Item resource exposes approximate time and poster photo URL.
- Added password reset request/reset endpoints.
- Added a named password reset web route that displays the reset token for use in the Flutter app.

## Notes
- Run `php artisan storage:link` so uploaded public files are reachable.
- Configure Laravel mail settings for password-reset emails.
- Set `APP_URL` correctly in production.
- Flutter dependencies must be fetched with `flutter pub get`.

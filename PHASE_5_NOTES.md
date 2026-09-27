# SwiftFinder Phase 5

## Flutter
- Added activity provider for My Reports, My Claims and Conversations.
- Added claim and conversation/message models.
- Added Activity screen with Reports / Claims / Messages tabs.
- Added claim review screen for report owners.
- Added conversations list and chat screen.
- Added Review claims action to owned item details.
- Added activity shortcut to the signed-in Home app bar.

## Laravel
- Added `GET /api/v1/my-claims` for authenticated users to retrieve claims they submitted.
- The endpoint returns claim data with an `ItemResource` representation of the related item.

## Existing APIs used
- `GET /my-items`
- `GET /my-claims`
- `GET /items/{item}/claims`
- `PATCH /claims/{claim}`
- `GET /conversations`
- `GET /conversations/{conversation}/messages`
- `POST /conversations/{conversation}/messages`
- `DELETE /conversations/{conversation}/messages/{message}`

Run `flutter pub get`, `flutter analyze`, and `flutter run` after replacing the Flutter project. The Flutter SDK was not available in the build environment, so Flutter compilation could not be executed here.

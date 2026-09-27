# SwiftFinder Deployment

## Laravel API on Render

Deploy the Laravel project to Render using its included `render.yaml` or the Dockerfile directly. Configure `APP_URL` to the public Render URL and set `CORS_ALLOWED_ORIGINS` to the exact GitHub Pages origin that will host the Flutter app.

## Flutter Web locally

```bash
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:8000/api/v1
```

## Flutter Web production

Build against the deployed API URL:

```bash
flutter build web --release --dart-define=API_URL=https://YOUR-RENDER-SERVICE.onrender.com/api/v1
```

For a GitHub Pages **project site** (for example `https://USER.github.io/REPOSITORY/`), build with the repository base path:

```bash
flutter build web --release \
  --base-href /REPOSITORY/ \
  --dart-define=API_URL=https://YOUR-RENDER-SERVICE.onrender.com/api/v1
```

For a GitHub Pages user/organization site served at the domain root, use `/` as the base href.

Publish the resulting `build/web` directory to the Pages site.

### API_URL is compile-time configuration

`API_URL` is a Dart compile-time define. Changing a GitHub repository secret or environment variable does not change an already-built app; rebuild the Flutter Web app after changing the API URL.

## Final production checks

- Confirm `APP_DEBUG=false` on Render.
- Confirm `APP_KEY` is generated and stable.
- Confirm `DB_CONNECTION=pgsql`.
- Set `CORS_ALLOWED_ORIGINS` to the actual Pages origin.
- Run `php artisan migrate --force` through the deployment entrypoint.
- Run `php artisan storage:link` for public uploads.
- Verify `/up` returns a healthy response.
- Verify register/login from the deployed Flutter app.
- Verify an authenticated API request from the deployed Flutter app.

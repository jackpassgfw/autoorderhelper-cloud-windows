# Auto Order Helper — Flutter Desktop Client

Scaffold for the desktop client that talks to the Auto Order Helper Cloud backend using JWT auth.

## Run (Desktop)

```bash
cd flutter-desktop-client/app
# Dev (default)
flutter run -d windows --dart-define=APP_ENV=dev
# Prod
flutter run -d windows --dart-define=APP_ENV=prod
```

`APP_ENV` chooses the base URL:
- dev: `http://127.0.0.1:8000`
- prod: `https://autoorderhelper.evergreenhealthlife.com`

## Project Structure

- `lib/config/environment.dart` — environment resolution and base URLs.
- `lib/core/api_client.dart` — Dio client with JWT injection and 401 handling.
- `lib/features/auth/` — login UI and session state.
- `lib/features/shell/` — navigation shell with rail and logout.
- `lib/features/*` — placeholder pages for Customers, Auto Orders, Business Centers, Previews, Settings.
- `lib/router/app_router.dart` — GoRouter setup with auth redirects.

## Next Steps

- Implement API-backed CRUD and preview flows per `openspec/changes/flutter-desktop-client/specs/desktop-client/spec.md`.
- Add tests (`flutter test`) and keep `flutter analyze` clean.

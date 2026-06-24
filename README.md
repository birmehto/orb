# Orb

Floating bubble overlay for Android — quick clipboard search and copy.

## Features

- System-wide bubble that stays visible above other apps after minimizing
- Drag anywhere with position persistence across reboots
- Single-tap popup with **Search** (Google) and **Copy** actions
- Material 3 with light and dark theme support
- Android 10–15, handles permissions and battery optimization across manufacturers

## Permissions

| Permission | Purpose |
|---|---|
| `SYSTEM_ALERT_WINDOW` | Draw bubble above other apps |
| `POST_NOTIFICATIONS` | Foreground service (Android 13+) |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Prevent OS from killing the service |

## Quick Start

```sh
flutter pub get
flutter build apk --debug   # or --release
```

1. Open the app and grant the **Display Overlay** permission.
2. Grant **Notifications** if prompted (Android 13+).
3. Toggle **Enable Bubble** and minimize the app.
4. **Tap** the bubble → Search / Copy. **Drag** to reposition.

## License

MIT

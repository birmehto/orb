# Lay

Floating bubble overlay for Android — quick clipboard search and copy, inspired by Facebook Chat Heads.

## Features

- **System-wide floating bubble** — stays visible on top of other apps after the app is minimized
- **Drag anywhere** — smooth position tracking with persistence across reboots
- **Search** — reads clipboard text and opens Google Search with it
- **Copy** — recopies the current clipboard text with success feedback
- **Material 3** — light and dark theme support
- **Manufacturer aware** — battery optimization and auto-start guidance for Samsung, Xiaomi, OnePlus, Vivo, Oppo, Realme, Pixel, Motorola

## Requirements

- Android 10 (API 29) through Android 15
- Flutter 3.x
- Kotlin 2.3+

## Architecture

```
Flutter (UI + State)
  │
  ├── Riverpod providers     — permission state, service status
  ├── PlatformService        — MethodChannel wrapper (singleton)
  └── HomeScreen             — settings UI with permission cards
        │
        ▼
MethodChannel (com.lay/bubble)
        │
        ▼
Android (Kotlin)
  ├── MainActivity           — handles Flutter ↔ native communication
  ├── BubbleService          — foreground service (START_STICKY)
  └── BubbleOverlayManager   — WindowManager overlay, drag, popup menu
```

## Permissions

| Permission | Purpose |
|---|---|
| `SYSTEM_ALERT_WINDOW` | Draw bubble above other apps |
| `POST_NOTIFICATIONS` | Foreground service (Android 13+) |
| `FOREGROUND_SERVICE` | Keep bubble alive when app is backgrounded |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Prevent OS from killing the service |

## Building

```sh
flutter pub get
flutter build apk --debug    # or --release
```

## Usage

1. Open the app
2. Grant the **Display Overlay** permission
3. Grant the **Notifications** permission (Android 13+)
4. Toggle **Enable Bubble** on
5. Minimize the app — the bubble appears
6. **Tap** the bubble → popup with Search / Copy
7. **Drag** the bubble to reposition

## MethodChannel API

All calls go through the `com.lay/bubble` channel.

| Method | Direction | Description |
|---|---|---|
| `startService` | Flutter → Android | Start foreground service + show bubble |
| `stopService` | Flutter → Android | Stop service + remove bubble |
| `isServiceRunning` | Flutter → Android | Check if service is alive |
| `checkOverlayPermission` | Flutter → Android | Check SYSTEM_ALERT_WINDOW |
| `requestOverlayPermission` | Flutter → Android | Open overlay permission settings |
| `checkNotificationPermission` | Flutter → Android | Check POST_NOTIFICATIONS |
| `requestNotificationPermission` | Flutter → Android | Open notification permission prompt |
| `checkBatteryOptimization` | Flutter → Android | Check if battery optimization is disabled |
| `requestBatteryOptimization` | Flutter → Android | Open battery optimization settings |
| `openAutoStartSettings` | Flutter → Android | Open manufacturer auto-start settings |

## Project Structure

```
lib/
  main.dart                          # Entry point + MethodChannel listener
  app.dart                           # MaterialApp with light/dark themes
  core/
    constants.dart                   # Channel names, app constants
    theme.dart                       # ThemeData definitions
  services/
    platform_service.dart            # MethodChannel wrapper
  features/home/
    providers/home_providers.dart    # Riverpod providers
    screens/home_screen.dart         # Settings UI
    widgets/permission_card.dart     # Reusable permission card

android/app/src/main/
  kotlin/com/example/lay/
    MainActivity.kt                  # Flutter activity + channel handler
    BubbleService.kt                 # Foreground service
    BubbleOverlayManager.kt          # Overlay logic (bubble, drag, popup)
  res/values/
    colors.xml                       # Light theme colors
  res/values-night/
    colors.xml                       # Dark theme colors
```

## License

MIT

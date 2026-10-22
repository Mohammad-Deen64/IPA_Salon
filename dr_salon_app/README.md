# Dr Salon

Flutter customer and owner app for Android and iOS. It talks to the local FastAPI service in `D:\FYP_Stuff\ai_backend`. The verified face-shape model and feature extractor are not modified.

## Platforms

- **Android** — build and run from this Windows PC (`flutter run` or Android Studio).
- **iOS** — project files are in `ios/`. Compile on a Mac with Xcode (`flutter run` or `flutter build ios`). This Windows machine cannot produce an iPhone binary.

## Run the API

Use Anaconda Python so the saved Random Forest loads with scikit-learn 1.9.1.
Bind `0.0.0.0` so a phone on the same Wi-Fi can reach the PC:

```powershell
& C:\Users\moham\anaconda3\python.exe -m uvicorn main:app --app-dir D:\FYP_Stuff\ai_backend --host 0.0.0.0 --port 8000
```

Allow port 8000 through Windows Firewall if a physical phone cannot connect.

## Run the app

```powershell
cd D:\FYP_Stuff\dr_salon_app
flutter run
```

| Client | API URL |
|---|---|
| Android emulator | `http://10.0.2.2:8000` (default) |
| Physical Android phone over USB | `http://127.0.0.1:8000` after `adb reverse` |
| iOS Simulator (on a Mac) | `http://127.0.0.1:8000` |
| Physical iPhone | `http://YOUR_PC_LAN_IP:8000` via `--dart-define` |

For a USB Android phone:

```powershell
adb reverse tcp:8000 tcp:8000
flutter run
```

Or run `.\run_android_usb.ps1`. Optional override:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

Demo logins (password `Demo1234!`):
- `customer@demo.com`
- `owner@demo.com`

The map uses OpenStreetMap tiles via `flutter_map`. Nearby results come from `GET /salons/nearby`. If location is denied, the list and map still show all salons and do not label them as nearby.

Bookings and accounts persist in `D:\FYP_Stuff\ai_backend\dr_salon.db`.

## Tests

```powershell
cd D:\FYP_Stuff\dr_salon_app
flutter analyze
flutter test
```

`test/ai_style_api_test.dart` needs the API running. The other Flutter tests do not.

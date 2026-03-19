# Tram Alger - Flutter Mobile App

Real-time ETA prediction for Algiers Tramway Line 1.

## Setup

1. **Install Flutter SDK** (3.0+)
   ```bash
   flutter doctor
   ```

2. **Get dependencies**
   ```bash
   cd tram_alger_app
   flutter pub get
   ```

3. **Run on device/emulator**
   ```bash
   flutter run
   ```

4. **Build APK**
   ```bash
   flutter build apk --release
   ```

## Features

- View all 32 stations for outbound/inbound directions
- Real-time ETA predictions using GPS or schedule
- Arabic station names support
- Source indicator (GPS vs Schedule)
- Pull-to-refresh

## API

- Base URL: https://tram-alger-production.up.railway.app
- Outbound route_id: 4
- Inbound route_id: 5

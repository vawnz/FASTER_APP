# FASTER (First-Aid Service Team Emergency Response)

FASTER (First-Aid Service Team Emergency Response) Application is an SOS Application exclusive for stakeholders within the vicinity of CvSU-CCC--where contact with the campus' medical team is certain and immediate.

---

## Features

- **Instant Signal Delivery**: Immediate distress signal sent with room and floor localization.
- **Interactive Map Layout**: Hit-testing interactive map for campus facilities.
- **Live-FAST Monitoring**: Real-time distress queue, details, and emergency history logging.
- **Cross-Platform**: Works seamlessly across macOS, Windows, Android, and iOS.
- **Dual Viewpoint**: Dedicated portals for Students and FAST Medical Officers.

---

## Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.13.3 or newer)
- Dart SDK (included with Flutter)
- Android Studio / Xcode / Visual Studio (depending on target platform)

### 2. Setup & Installation
Clone the repository and install dependencies:
```bash
git clone https://github.com/vawnz/FASTER_APP.git
cd FASTER_APP
flutter pub get
```

### 3. Environment Configuration (Optional Supabase Sync)
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Add your Supabase URL and public **`anon`** key (from **Supabase Dashboard > Project Settings > API**):
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key
```
> **Security Notice**: Never use the `service_role` or `secret` key in client applications. The `.env` file is excluded from git tracking to prevent credential leaks.

### 4. Supabase Database Migration
To set up or repair the required tables in your Supabase database, run the SQL script found in:
[`supabase_schema.sql`](./supabase_schema.sql)
in your **Supabase Dashboard > SQL Editor**.

---

## Demo & Testing Credentials

| Role | Username / Student ID | Password | Access Level |
| :--- | :--- | :--- | :--- |
| **FAST Officer (Admin)** | `admin00` | `admin1234` | HQ Real-Time Heatmap & Dispatch |
| **Student (Demo)** | `202601234` or `testaccount` | Any password | Student SOS & Campus Map |
| **New Student** | *Sign Up via App* | *Your Password* | Saved in Local / Remote Session |

---

## Running the Application

To run the application on your connected device or emulator:
```bash
flutter run
```

To run automated widget and unit tests:
```bash
flutter test
```

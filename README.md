# 🐂 MuzzleID: Cattle Biometric Identification

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-%23039BE5.svg?style=for-the-badge&logo=Firebase&logoColor=white)](https://firebase.google.com/)
[![Isar](https://img.shields.io/badge/Database-Isar-blue.svg?style=for-the-badge)](https://isar.dev/)

MuzzleID is a cutting-edge biometric collection and identification system designed specifically for livestock. It leverages advanced imaging and offline-first synchronization to ensure accurate cattle identification even in the most remote field conditions.

## ✨ Key Features

- **📸 Biometric Capture**: Optimized camera interface for capturing high-resolution muzzle patterns.
- **🚀 Offline-First Architecture**: Uses Isar/Hive for local data persistence, allowing field workers to operate without an active internet connection.
- **🔄 Robust Sync Engine**: Automatically queues and uploads biometric data once connectivity is restored.
- **🔗 Mesh Networking Ready**: Integration with local mesh protocols for peer-to-peer data sharing in low-connectivity areas.
- **🛡️ Secure Enrollment**: Multi-step verification process for cattle registration and identity management.

## 🏗️ Project Structure

```text
lib/
├── core/           # Core configurations, themes, and utilities
├── features/       # Feature-based modules (Auth, Enrollment, Sync, etc.)
│   ├── enrollment/ # Muzzle capture and submission logic
│   ├── sync/       # Background synchronization and task management
│   └── auth/       # User authentication and session management
└── shared/         # Reusable widgets and services (Isar, Mesh, etc.)
```

## 🛠️ Getting Started

### Prerequisites

- Flutter SDK (Latest Stable)
- Android Studio / VS Code
- Firebase Project Setup

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/s4ki3f/Muzzle_id.git
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 🤖 Collaborator & Android Testing Guide

This application is designed to be **offline-first**. This means your collaborator can immediately build, run, and optimize the application on a physical Android device without needing a Firebase project setup or configuration files.

### 🔌 1. Running & Testing Offline (No Firebase Needed)
The biometric capture, real-time image checks (blur & brightness), local Hive database queue, and user interface can be fully tested offline.
1. **Enable Developer Options** on the physical Android device:
   * Go to **Settings > About Phone** and tap **Build Number** 7 times.
   * Go back to **Settings > System > Developer Options** and enable **USB Debugging**.
2. **Connect the device** to the development machine via USB.
3. Run `flutter devices` to ensure the device is recognized.
4. Execute the application on the device:
   * ```bash
     flutter run
     ```
*Note: Any captured biometric enrollments will gracefully queue up in the local database (`uploadQueue`) instead of failing or crashing the app, as Firebase initialization errors are caught safely.*

### 📸 2. Simulating Muzzle Patterns for Camera Testing
Because cattle biometrics require capturing fine muzzle details, testing the custom camera UI on a real animal is not always possible in an office setup:
* **Recommendation**: Print out high-resolution muzzle patterns or display them on a secondary high-contrast screen.
* Point the Android device camera at the pattern to test:
  * **Real-time blur estimation** (adjusting distance to keep details sharp).
  * **Real-time brightness checks** (testing under shadows/overexposed lighting).
  * **Automatic frame collection & queuing**.

### 🔥 3. (Optional) Plugging in a Custom Firebase Backend
If your collaborator wants to test the background synchronization and Firestore/Storage uploads:
1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2. Add an **Android App** to the project.
   * **Package Name**: `com.example.muzzle_id` (must match the package defined in `/android/app/build.gradle.kts`).
3. Download the generated `google-services.json` file.
4. Place `google-services.json` in the `/android/app/` directory of this project.
5. Apply the Google Services Gradle plugins:
   * **Project build.gradle (`/android/build.gradle.kts`)**:
     Add the Google services dependency under plugins:
     ```kotlin
     plugins {
         // ... existing plugins
         id("com.google.gms.google-services") version "4.4.1" apply false
     }
     ```
   * **App build.gradle (`/android/app/build.gradle.kts`)**:
     Apply the plugin at the top of the file:
     ```kotlin
     plugins {
         // ... existing plugins
         id("com.google.gms.google-services")
     }
     ```
6. The app will now automatically initialize and sync uploads to your custom Firebase console when internet connectivity is active.

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Developed with ❤️ for the livestock industry.*


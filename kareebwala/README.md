# 📍 KareebWala - Local Service Finder

**KareebWala** is a comprehensive Flutter application designed to connect local service providers (Mechanics, Electricians, Plumbers) with clients in real-time. It features live tracking, role-based authentication, and offline support using a hybrid database approach.

## 🚀 Features

### 👤 For Clients (Users)
* **Role-Based Login:** Secure authentication via Email or Google Sign-In.
* **Live Map Interface:** View current location and nearby service availability using Google Maps.
* **Service Request:** Book specific services (Mechanic, Electrician, etc.) with price estimation.
* **Real-Time Tracking:** Live updates on the provider's status (Accepted, Arriving, Completed).
* **Emergency SOS:** Quick access button for urgent situations.
* **Offline History:** "My Bookings" data is cached locally using **SQLite**, allowing access even without internet.
* **Smart Onboarding:** Intro slides for first-time users (managed via Shared Preferences).

### 🛠 For Providers (Workers)
* **Dedicated Dashboard:** View new job requests in real-time.
* **Distance Calculation:** See exactly how far the client is before accepting a job.
* **Job Management:** Accept or Ignore requests instantly.
* **Active Job Tracking:** Manage ongoing jobs and mark them as completed.

---

## 🏗 Tech Stack & Architecture

This project follows a **Feature-First Clean Architecture** to ensure scalability and maintainability.

### **Core Technologies:**
* **Frontend:** Flutter (Dart)
* **Backend:** Firebase (Auth, Cloud Firestore)
* **Local Database:** SQLite (`sqflite`) & Shared Preferences
* **State Management:** Flutter Riverpod
* **Maps & Location:** Google Maps Flutter, Geolocator, Geocoding

### **Key Libraries:**
* `cloud_firestore`: For real-time data syncing.
* `firebase_auth`: For secure user authentication.
* `sqflite`: For offline data persistence.
* `shared_preferences`: For storing app settings/onboarding state.
* `url_launcher`: For making phone calls within the app.

---

## 📂 Project Structure

```text
lib/
│
├── main.dart            # Application Entry Point
├── firebase_options.dart # Firebase Configuration
│
├── core/                # Global utilities
│   └── services/
│       └── local_storage_service.dart  (SQLite + SharedPrefs Logic)
│
└── features/            # Feature-based modules
    ├── auth/            # Login, Signup, Profile Logic
    ├── home_map/        # Client Map & Location Logic
    ├── booking/         # Request, Tracking & History Logic
    ├── provider/        # Provider Dashboard Logic
    └── onboarding/      # Intro Screens

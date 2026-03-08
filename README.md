# Kigali Locate

A Flutter mobile app that helps Kigali residents discover and navigate to essential public services and lifestyle locations — hospitals, police stations, libraries, restaurants, cafés, parks, and more.

**GitHub:** https://github.com/Ebi-Tech/kigali_locate
**Demo Video:** https://youtu.be/lZVCudjab7o

## Features

- **Firebase Authentication** — Email/password signup + login, email verification enforced before access
- **Firestore CRUD** — Create, read, update, and delete service/place listings in real time
- **Directory** — Browse all listings with live search and category filtering
- **My Listings** — Manage your own listings; swipe to delete or tap the edit icon
- **Map View** — All listings plotted on an embedded map with category colour-coded markers; tap a marker to navigate to the detail page
- **Detail Page** — Full listing info, embedded map with marker, launch turn-by-turn directions via Google Maps, and a star-rating / review system
- **Settings** — User profile display, email verification status, notification toggle (stored in SharedPreferences), and sign-out

## Map Library — Why OpenStreetMap instead of Google Maps

The assignment specifies an embedded Google Map. During development, `google_maps_flutter` was evaluated but not adopted for the following reason:

Google Maps Platform requires an active billing account (credit/debit card) on Google Cloud Console before an API key will function, even within the free monthly usage tier. Enabling billing on a personal account purely for an academic project was not a justifiable requirement.

`flutter_map` with OpenStreetMap tiles was used instead. It is fully open-source, requires no API key and no billing account, and fulfils the same functional requirement — rendering a tile map, placing coordinate-based markers from Firestore data, and handling tap interactions. **Turn-by-turn navigation still launches Google Maps** via `url_launcher`, so the Google Maps experience is present where it matters most to the end user.

## State Management — Riverpod

All Firestore reads and writes go through a dedicated **service layer** (`FirestoreService`, `AuthService`) and are exposed to the UI via **Riverpod providers**:

| Provider | Type | Purpose |
|---|---|---|
| `allListingsStreamProvider` | `StreamProvider` | Real-time stream of all listings |
| `myListingsStreamProvider` | `StreamProvider` | Listings owned by the signed-in user |
| `filteredListingsProvider` | `Provider` | Computed search + category filter |
| `listingsNotifierProvider` | `StateNotifierProvider` | Add / update / delete operations |
| `authStateProvider` | `StreamProvider` | Firebase auth state stream |
| `authNotifierProvider` | `StateNotifierProvider` | Sign-up / login / logout actions |
| `userProfileProvider` | `StreamProvider` | Live user profile from Firestore |
| `notificationsProvider` | `StateNotifierProvider` | Notification preference toggle |

UI widgets **never call Firebase directly** — they only read providers or call notifier methods.

## Firestore Database Structure

```
/users/{uid}
  fullName: string
  email: string
  createdAt: timestamp

/listings/{listingId}
  name: string
  category: string          // Hospital | Café | Park | etc.
  address: string
  contactNumber: string
  description: string
  latitude: number
  longitude: number
  createdBy: string         // uid of the creating user
  createdAt: timestamp
  averageRating: number
  reviewCount: number

/reviews/{reviewId}
  listingId: string
  userId: string
  userName: string
  rating: number
  comment: string
  createdAt: timestamp
```

## Setup

### 1. Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/) and create a project.
2. Enable **Authentication → Email/Password**.
3. Create a **Firestore Database** (start in test mode, then secure with rules).
4. Register an **Android app** (package `com.kigali.kigali_locate`) and download `google-services.json` to `android/app/`.

### 2. FlutterFire CLI (recommended)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This regenerates `lib/firebase_options.dart` with your real credentials.

### 3. Firestore Security Rules (recommended)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /listings/{id} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
        && request.auth.uid == resource.data.createdBy;
    }
    match /reviews/{id} {
      allow read: if true;
      allow create: if request.auth != null;
    }
  }
}
```

### 4. Run

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── app_theme.dart       # Dark navy theme + AppColors
│   └── constants.dart       # Categories, Kigali coords, strings
├── models/
│   ├── listing_model.dart
│   ├── user_profile_model.dart
│   └── review_model.dart
├── services/
│   ├── auth_service.dart      # Firebase Auth wrapper
│   ├── firestore_service.dart # All Firestore reads/writes
│   └── location_service.dart  # Geolocator wrapper
├── providers/
│   ├── auth_provider.dart      # Auth state + notifier
│   ├── listings_provider.dart  # Listings streams + notifier
│   └── settings_provider.dart  # Notification toggle
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── verify_email_screen.dart
│   ├── directory/
│   │   ├── directory_screen.dart        # Search + filter
│   │   ├── listing_detail_screen.dart   # Map + reviews
│   │   └── add_edit_listing_screen.dart
│   ├── my_listings/
│   │   └── my_listings_screen.dart
│   ├── map/
│   │   └── map_view_screen.dart
│   ├── settings/
│   │   └── settings_screen.dart
│   └── main_scaffold.dart  # BottomNavigationBar shell
├── widgets/
│   ├── listing_card.dart
│   ├── category_chip_bar.dart
│   ├── star_rating.dart
│   └── empty_state.dart
├── firebase_options.dart   # Generated by flutterfire configure
└── main.dart               # Firebase init + AuthWrapper routing
```

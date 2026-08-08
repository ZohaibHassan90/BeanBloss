# BeanBloss ☕

**End-to-end Flutter café pickup app** — real auth, cloud database, live order tracking, and media uploads. 

Browse the menu → customize & checkout → track preparation in real time → pay at the counter.

---

## Why this project stands out

| | |
|---|---|
| **Full stack mobile** | Flutter client + Firebase backend + Cloudinary media |
| **Real user flows** | Auth → catalog → cart → orders → track → reorder |
| **Cloud-native data** | Profiles, favorites, menu, and orders in Firestore |
| **Push-ready** | FCM token sync + order status notifications |
| **Secure by default** | Secrets gitignored; rules for users / products / orders |

---

## Core features

- **Authentication** — Email/password with Firebase Auth; session-aware splash routing
- **Dynamic menu** — Firestore product catalog (auto-seeded), categories, search & sort
- **Cart & checkout** — Line items with size/milk options; **pay at pickup**
- **Live order tracking** — Status pipeline: received → preparing → almost ready → ready
- **Order history & reorder** — Past orders from Firestore, one-tap reorder into cart
- **Favorites** — Persisted per user across devices
- **Profile** — Editable info + Cloudinary avatar upload
- **Notifications** — Local alerts as order status advances; FCM token stored on user

---

## Architecture

```
Flutter App
 ├── Firebase Auth          → sign up / sign in / session
 ├── Cloud Firestore        → users · products · orders
 ├── Cloudinary             → avatar (unsigned upload presets)
 └── FCM + local notifs     → order updates
```

**Key collections**

- `users/{uid}` — profile, favorites, FCM token, photo URL  
- `products/{id}` — menu items (name, price, category, imageUrl, …)  
- `orders/{id}` — cart snapshot, totals, payment + status  

---

## Tech stack

**Flutter** · **Firebase Auth** · **Cloud Firestore** · **Firebase Cloud Messaging** · **Cloudinary** · **Android**

---

## Run locally

```bash
flutter pub get
flutter run
```

**Setup (required once)**

1. Copy Firebase templates and fill with your project:
   - `android/app/google-services.json.example` → `google-services.json`
   - `lib/firebase_options.example.dart` → `firebase_options.dart`  
   (or `flutterfire configure`)
2. Enable Email/Password Auth + Cloud Firestore
3. Publish `firestore.rules`

**Cloudinary (optional, for avatars)**

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=your_products_preset \
  --dart-define=CLOUDINARY_AVATARS_UPLOAD_PRESET=your_avatars_preset
```

---


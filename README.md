# TriVerse – Premium AI Creation Hub (Brahma / Vishnu / Shiva)

Futuristic Flutter app that uses Google Gemini + Firebase to generate Flutter apps & games as ZIPs (uploaded to Cloud Storage), with a full credit economy, Razorpay payments, hybrid AI + human support with push notifications, and a live admin control panel.

---

## 📁 Project Structure

```
TriVerse_Final/
├── android/                       # AndroidManifest (perms + FCM channel)
├── functions/                     # Firebase Cloud Functions (Node 18)
│   ├── index.js                   # All 9 callable/trigger functions
│   └── package.json               # Includes `razorpay` SDK
├── lib/
│   ├── main.dart                  # Entry + Firebase + FCM + Provider
│   ├── firebase_options.dart      # PLACEHOLDER – replaced by `flutterfire configure`
│   ├── providers/app_state.dart   # Live Firestore user state
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── gemini_service.dart
│   │   ├── zip_service.dart       # Firebase Storage uploader
│   │   ├── firestore_service.dart
│   │   ├── support_chat_service.dart
│   │   ├── fcm_service.dart       # Push + deep-link
│   │   └── payment_service.dart   # Razorpay Flutter wrapper
│   └── screens/
│       ├── splash_screen.dart
│       ├── login_screen.dart
│       ├── main_layout.dart
│       ├── home_dashboard.dart
│       ├── brahma_hub.dart              # App + Game generators
│       ├── vishnu_hub.dart              # Cloud ZIP list
│       ├── shiva_panel.dart             # Unread badges + role-gated cards
│       ├── admin_dashboard_screen.dart  # Live stats + 7-day chart
│       ├── admin_users_screen.dart
│       ├── admin_tickets_screen.dart    # Admin inbox
│       ├── credit_control_screen.dart   # Editable global config + leaderboard
│       ├── ai_logs_screen.dart
│       ├── ticket_detail_screen.dart    # Hybrid AI+human thread view
│       ├── support_hub_screen.dart      # Gemini-powered chat
│       ├── my_tickets_screen.dart
│       ├── daily_reward_screen.dart
│       ├── buy_credits_screen.dart
│       ├── payment_screen.dart          # Razorpay / mock
│       └── payment_success_screen.dart
├── assets/images/                 # Drop logo.png here
├── firebase.json                  # firestore + storage + functions
├── firestore.rules                # Role-based + unread-counter aware
├── storage.rules                  # Owner-only ZIPs (20MB cap)
├── pubspec.yaml                   # All deps incl razorpay_flutter + fl_chart
└── README.md
```

---

## 🚀 One-Time Setup

**No laptop? Read [`MOBILE_SETUP.md`](./MOBILE_SETUP.md) for full mobile-only instructions using GitHub Actions.**

### 1. Install prerequisites

```bash
# Flutter SDK ≥ 3.0  →  https://docs.flutter.dev/get-started/install
# Node.js 18         →  https://nodejs.org
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

### 2. Login & configure Firebase

```bash
firebase login
cd TriVerse_Final
flutter pub get
flutterfire configure   # pick your project + Android (optionally iOS)
```

### 3. Enable in Firebase Console

- Authentication → Email/Password
- Firestore → Create database (production mode)
- Storage → Get started (production mode)
- Cloud Messaging (auto-enabled)
- **Blaze plan** (required for Cloud Functions + outbound Gemini/Razorpay + FCM quota)

### 4. Set Razorpay keys (OPTIONAL — skip for MOCK mode)

If you don't have Razorpay keys yet, the app ships in **mock mode** — tapping "Pay" will still credit your account for testing. To go live:

```bash
# Get keys from https://dashboard.razorpay.com/app/keys
firebase functions:config:set \
  razorpay.key_id="rzp_test_XXXXXXXXXXXXXXXX" \
  razorpay.key_secret="YYYYYYYYYYYYYYYYYYYYYYYY"
firebase deploy --only functions      # re-deploy after setting config
```

No client-side keys needed — the Flutter app receives the key_id from the Cloud Function.

### 5. Add your Gemini API key

Edit `lib/services/gemini_service.dart` → replace `'YOUR_GEMINI_API_KEY'` with a free key from https://aistudio.google.com/app/apikey

### 6. Deploy everything

```bash
firebase deploy --only firestore:rules,storage:rules
cd functions && npm install && cd ..
firebase deploy --only functions
```

### 7. Run

```bash
flutter run
```

---

## 🔑 Admin Account

First user who signs up with `ADMIN_EMAIL` (default `abhimaniu041@gmail.com` inside `functions/index.js`) automatically gets `role: "admin"`. All admin screens (Dashboard, Users, All Tickets, Credit Control, AI Logs) unlock automatically.

---

## 💰 Global Pricing & Limits — EDITABLE LIVE

The following values are stored in `config/global` Firestore doc and can be edited from **Shiva → Credit Control** any time (no redeploy):

| Key             | Default | Meaning                                    |
|-----------------|---------|--------------------------------------------|
| `signupCredits` | 7       | Credits granted on signup                  |
| `dailyReward`   | 2       | Credits granted per 24h claim              |
| `maxLimit`      | 1000    | ₹ hard cap per user before admin unblock   |
| `appCost`       | 100     | Credits to generate a full app             |
| `gameCost`      | 70      | Credits to generate a full game            |

---

## 📊 Admin Panel Features

- **Dashboard** — Live counters (users / revenue / apps / open tickets) + 7-day usage bar chart (powered by `fl_chart`)
- **Users** — Search, add credits, block/unblock anyone
- **All Tickets** — Hybrid AI+human inbox with filter chips + red unread badges
- **Credit Control** — Edit live pricing + top-10 spend leaderboard
- **AI Logs** — Every `processUsage` call with user, prompt preview, credits, ₹ cost, time; filterable App / Game / All

---

## 🧱 Firestore Collections

| Collection | Schema |
|---|---|
| `users/{uid}` | `uid, email, credits, role, totalUsageCost, totalRevenue, isUsageBlocked, lastClaimDate, fcmTokens[], createdAt` |
| `apps/{id}` | `userId, name, version, downloadUrl, storagePath, sizeBytes, createdAt` |
| `tickets/{id}` | `userId, email, issue, status, userUnread, adminUnread, lastMessageAt, createdAt` |
| `tickets/{id}/messages/{msgId}` | `text, role: user|assistant|admin, createdAt` |
| `aiLogs/{id}` | `userId, email, kind: app|game, creditsDeducted, costRupees, prompt, createdAt` |
| `orders/{id}` | `userId, amountRupees, creditsToAdd, status, mode, razorpayOrderId, razorpayPaymentId, createdAt, paidAt` |
| `config/global` | `signupCredits, dailyReward, maxLimit, appCost, gameCost, updatedAt` |

**Firebase Storage**: `apps/{uid}/{timestamp}_{appName}.zip` — owner-only, 20 MB cap, `application/zip` only.

---

## 🔔 Push Notifications (FCM)

- **Admin → User**: On every admin reply, user gets *"Abhimaniu (Support) replied"* with preview. Tapping opens that ticket directly.
- **User → Admin**: On every new ticket, all admins get *"🆕 New Support Ticket"*.
- Android 13+ permission (`POST_NOTIFICATIONS`) + default channel `triverse_support` wired in AndroidManifest.
- Tap anywhere (cold start / background / foreground) → deep-links to `TicketDetailScreen`.

---

## 🛠 Production Checklist

- [ ] Enable Blaze plan
- [ ] `flutterfire configure`
- [ ] Deploy rules + functions
- [ ] Add real Razorpay keys (`functions:config:set`)
- [ ] Add real Gemini API key in `gemini_service.dart`
- [ ] (iOS) Upload APNs Auth Key in Firebase Cloud Messaging settings
- [ ] Drop `logo.png` into `assets/images/` + swap `Icon(...)` in `splash_screen.dart` + `login_screen.dart`
- [ ] `flutter build apk --release` (or appbundle for Play Store)

---

## 🎯 Features Matrix

| Feature | Status |
|---|---|
| Firebase Auth (email/password) | ✅ |
| Credit economy (signup / daily / usage / cap) | ✅ live-configurable |
| Brahma AI **App** Generator | ✅ |
| Brahma AI **Game** Generator | ✅ |
| Vishnu Hub (Cloud Storage ZIPs with signed URLs) | ✅ |
| Shiva Dashboard (live stats + chart) | ✅ |
| Shiva User Management | ✅ |
| Shiva Credit Control (live global config) | ✅ |
| Shiva AI Logs (full audit trail) | ✅ |
| Razorpay Payment Gateway | ✅ (mock fallback) |
| Hybrid AI (Gemini) + Human Support Chat | ✅ |
| Admin "All Tickets" Inbox | ✅ |
| FCM Push — admin→user reply | ✅ with deep-link |
| FCM Push — user→admin new ticket | ✅ |
| Unread reply badges | ✅ |

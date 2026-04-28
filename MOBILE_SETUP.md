# 📱 TriVerse — Get Your APK From Mobile (No Laptop Needed)

## 🎯 What you'll get
After running the GitHub Actions workflow, you'll have **permanent direct download URLs** like:
```
https://github.com/YOUR_USERNAME/triverse/releases/download/v1.0.20260127/TriVerse-arm64-v8a.apk
```
Just tap from your phone browser → APK downloads → install.

---

## 1️⃣ Firebase Console Setup (mobile browser, 10 min)

1. Go to https://console.firebase.google.com
2. **Add project** → name: `triverse` → continue
3. Upgrade to **Blaze plan** (required for Cloud Functions + Gemini + FCM). Settings → Usage and billing → Details & settings
4. Project Overview → **Add app** → Android icon
   - Package name: **`com.abhimaniu.triverse`** (exactly)
   - App nickname: `TriVerse`
   - Register app
   - **Download `google-services.json`** → save in phone
5. Left menu — Enable:
   - **Authentication** → Sign-in method → Email/Password → Enable
   - **Firestore** → Create database → Production mode → `asia-south1`
   - **Storage** → Get started → Production mode
   - **Messaging** (auto-enabled)
6. Project settings (gear ⚙️) → General → "Your apps" → **copy config** (apiKey, appId, messagingSenderId, projectId, storageBucket) for next step.

---

## 2️⃣ Create GitHub Repository (mobile browser, 2 min)

1. https://github.com/new
2. Repo name: `triverse`  
3. Click **Create repository**

---

## 3️⃣ Upload TriVerse Code (mobile browser, 5 min)

1. Download `TriVerse_Final.zip` on your phone
2. Extract using **ZArchiver** (free on Play Store): open zip → Extract → remember the location
3. In your new GitHub repo: tap "uploading an existing file" link
4. Select **ALL files and folders** from the extracted `TriVerse_Final/` including hidden `.github/` folder
5. Commit directly to `main` branch

> **Tip**: If your file manager hides `.github/`, toggle "Show hidden files" first. Without it, the workflow won't run.

---

## 4️⃣ Add Firebase Credentials to the Repo

### File A: `android/app/google-services.json`
1. In GitHub repo → navigate to `android/app/`
2. Add file → Create new file → name: `google-services.json`
3. Open the `google-services.json` you downloaded in Step 1.4 in a text editor (**Acode** free app) → copy all contents
4. Paste into the GitHub editor → Commit

### File B: `lib/firebase_options.dart`
1. Navigate to `lib/firebase_options.dart` → edit (pencil icon)
2. Replace its contents with:
```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Only Android configured.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PASTE_FROM_google-services.json → client[0].api_key[0].current_key',
    appId: 'PASTE → client[0].client_info.mobilesdk_app_id',
    messagingSenderId: 'PASTE → project_info.project_number',
    projectId: 'PASTE → project_info.project_id',
    storageBucket: 'PASTE → project_info.storage_bucket',
  );
}
```
3. Fill in the PASTE lines from your `google-services.json`
4. Commit

### File C: `lib/services/gemini_service.dart`
1. Get free Gemini key: https://aistudio.google.com/app/apikey (works on mobile)
2. In the repo → `lib/services/gemini_service.dart` → edit
3. Replace `'YOUR_GEMINI_API_KEY'` with your real key
4. Commit

---

## 5️⃣ Deploy Cloud Functions (one-time, 10 min)

Open **GitHub Codespaces** (60 free hours/month — all in browser):
1. Repo → green **Code** button → **Codespaces** tab → "Create codespace on main"
2. Wait for terminal to load (~1 min)
3. Run:
   ```bash
   npm install -g firebase-tools
   firebase login --no-localhost
   firebase use --add   # pick your triverse project, alias: default
   firebase deploy --only firestore:rules,storage:rules
   cd functions && npm install && cd ..
   firebase deploy --only functions
   ```
4. (Optional) Add Razorpay keys:
   ```bash
   firebase functions:config:set \
     razorpay.key_id="rzp_test_XXXXXXXXXXXXXXXX" \
     razorpay.key_secret="YYYYYYYYYYYYYYYYYYYYYYYY"
   firebase deploy --only functions
   ```
5. Close the codespace. **You won't need it again.**

---

## 6️⃣ Build the APK (automatic)

The workflow runs automatically on every push. To trigger manually:
1. Repo → **Actions** tab
2. Click **"Build & Release TriVerse"** → top-right **"Run workflow"** → choose `main` → Run
3. Watch it complete (5–8 min). Green ✅ = success.

---

## 7️⃣ Download Your APK 📱

There are **3 ways** to get the APK — pick whichever works on your phone:

### Way 1: GitHub Release (RECOMMENDED — permanent direct URL)
1. Repo → **Releases** tab (right sidebar)
2. Click the latest release (e.g. `v1.0.20260127123045`)
3. Scroll to **Assets**
4. Tap **`TriVerse-arm64-v8a.apk`** (for modern phones)
5. Android prompts → "Allow install from unknown source" → Install

**Direct URL format** (for sharing):
```
https://github.com/YOUR_USERNAME/triverse/releases/latest/download/TriVerse-arm64-v8a.apk
```
☝️ This URL **never expires** and always serves the latest build.

### Way 2: Workflow Artifact
1. Actions → tap the completed workflow run
2. Scroll to **Artifacts**
3. Tap `TriVerse-APK` (downloads a zip containing all ABI APKs)
4. Extract → install the matching APK

### Way 3: Workflow Summary
1. Actions → tap the completed run
2. At the top, see **📲 Direct APK download links** section
3. Tap any link

---

## 🔐 Play Store Upload

When you're ready to publish on Google Play:
1. Download `TriVerse.aab` from Releases
2. In your Google Play Console → create app → Upload this AAB

> **Important**: The auto-generated keystore is for side-load only. For Play Store, create a proper keystore and add these GitHub Secrets:
> - `KEYSTORE_B64` — `base64 -w0 upload-keystore.jks` output
> - `KEYSTORE_PASSWORD`
> - `KEY_ALIAS`
> - `KEY_PASSWORD`
> 
> Optional for real Firebase: `GOOGLE_SERVICES_JSON_B64`

---

## 🆘 Troubleshooting

| Symptom | Fix |
|---|---|
| Workflow fails at Flutter step | Usually transient — re-run the workflow |
| APK installs, splash shows "Firebase not configured" banner | You forgot Steps 4A or 4B — fix + re-run workflow |
| Login fails with "Network error" | Firestore rules not deployed — redo Step 5 |
| No push notifications | Blaze plan not active, OR user hasn't granted notification permission on first open |
| Credits not updating after payment | Cloud Functions not deployed — redo Step 5 |
| `flutter create` error about missing `android` folder | The workflow handles this automatically — make sure `.github/workflows/build-apk.yml` was committed |

---

## 📊 First-run Test Checklist

After installing the APK:
- [ ] App opens to splash (2 sec) → login screen
- [ ] Signup with a test email → dashboard shows 7 credits
- [ ] Tap gift icon → claim daily reward → +2 credits
- [ ] Brahma → write prompt → tap "100" → wait → success snackbar
- [ ] Vishnu → see the generated app → tap download → browser opens Firebase Storage URL
- [ ] Home → support icon → chat with AI → reply appears
- [ ] Signup with admin email → Shiva → all 5 cards tappable
- [ ] Buy Credits → Pay ₹50 → (mock mode) success → +100 credits
- [ ] Logout → Login screen appears

🎉 All green? Ship it.

---

## 🔗 Quick Links
- Firebase Console: https://console.firebase.google.com
- Gemini API Key: https://aistudio.google.com/app/apikey
- Razorpay Dashboard: https://dashboard.razorpay.com
- GitHub Codespaces docs: https://docs.github.com/codespaces

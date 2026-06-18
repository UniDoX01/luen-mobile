# Building LUÉN — APK & IPA without owning a Mac

Building Android + iOS apps from your shared host's command line was attempted
and rejected by the CloudLinux **LVE** per-user memory cap (Gradle daemon
killed at ~1 GB). The right answer is a free cloud build pipeline. Two files
have been added to this project:

| File                              | What it does                          |
|-----------------------------------|---------------------------------------|
| `codemagic.yaml`                  | Builds **APK + unsigned IPA** on every push (Codemagic, free 500 min/mo) |
| `.github/workflows/build-apk.yml` | Builds **APK only** on every push (GitHub Actions, free) |

You only need ONE of them — Codemagic is the recommended path because it
produces both artifacts. Use the GitHub Actions one if you only care about
Android or want a redundant pipeline.

---

## 1. One-time setup (≤ 15 min)

### a) Push `~/luen-mobile/` to a GitHub repository

```bash
cd ~/luen-mobile
git init -b main
# Avoid committing build junk
cat > .gitignore <<'EOF'
.dart_tool/
.gradle/
build/
ios/Pods/
ios/.symlinks/
android/.gradle/
*.iml
*.lock
.flutter-plugins
.flutter-plugins-dependencies
EOF
git add .
git commit -m "Initial LUÉN mobile scaffold"

# Create a *private* repo at https://github.com/new (e.g. houseofluen/luen-mobile)
git remote add origin git@github.com:<your-username>/luen-mobile.git
git push -u origin main
```

### b) Codemagic (recommended)

1. Open https://codemagic.io → **Sign up with GitHub**
2. **Applications → Add application → Other → Flutter** → pick your repo
3. Codemagic auto-detects `codemagic.yaml`. You'll see two workflows:
   - **LUÉN — Android APK** (Linux, free, ~3 min)
   - **LUÉN — iOS unsigned IPA** (macOS, free 500 min/mo, ~7 min)
4. Click **Start new build** → pick a workflow → run.
5. Email arrives with the artifact link. Download the file.

> Codemagic emails go to `norsksikkerhet@icloud.com` (set in `codemagic.yaml`).
> Edit the file to change recipients.

### c) GitHub Actions (APK only, alternative)

After pushing to GitHub the workflow runs automatically on every push to
`main`. Or trigger manually:

1. Repo → **Actions** tab → **Build Android APK** → **Run workflow**
2. Wait ~4 minutes
3. Click the completed run → **Artifacts** → **luen-android-apk** → download
4. Unzip → `app-release.apk`

---

## 2. Installing the APK on Android

1. Transfer `app-release.apk` to your phone (USB, Drive, AirDrop-equivalent)
2. Settings → Apps → Special access → **Install unknown apps** → enable for
   the app you'll use to open the file (Files / Drive)
3. Tap the APK → Install → Open. Done.

---

## 3. Installing the unsigned IPA on iPhone (AltStore / Sideloadly)

> **No $99 Apple Developer needed.** Free Apple ID (your iCloud account) is
> enough. The signature expires after 7 days — just re-sign from your Mac
> when that happens.

### Sideloadly (easiest — works on Mac AND Windows)

1. Download Sideloadly: https://sideloadly.io (free)
2. Connect your iPhone via USB cable
3. Drag `Runner-unsigned.ipa` into the Sideloadly window
4. Enter your Apple ID (the one signed into your iPhone)
5. Click **Start**. First time: confirm the app on the iPhone via
   Settings → General → VPN & Device Management → trust your Apple ID
6. App icon appears on the iPhone home screen

### AltStore (auto re-sign before expiry)

1. https://altstore.io → install **AltServer** on your computer
2. Plug iPhone in over USB → AltServer menu → **Install AltStore → [your iPhone]**
3. On iPhone: open AltStore → My Apps → **+** → pick `Runner-unsigned.ipa`
4. AltStore keeps the app signed automatically as long as your computer
   is on the same Wi-Fi as the iPhone once a week. Set-and-forget.

---

## 4. What can your phone actually do with this build?

| Feature                  | Status                                           |
|--------------------------|--------------------------------------------------|
| Browse products + detail | ✅ live (`/api/products`)                        |
| Sign in / sign up        | ✅ live (Sanctum token in Keychain/Keystore)     |
| Add to cart              | ✅ live (`/api/cart-items`)                      |
| View orders + VIP badge  | ✅ live (`/api/orders`, `/api/auth/me`)          |
| AI Concierge tab         | ✅ live once OpenAI key is set on `/admin/ai-chat`|
| Checkout                 | ⚠️ Opens https://houseofluen.com/checkout in browser. Native Stripe/Vipps SDKs deferred. |
| Force update / maintenance | ✅ live (driven by `/admin/app-settings`)      |
| Push notifications       | ❌ deferred — needs Firebase project setup       |
| Wallet pass              | ❌ deferred — needs Apple Developer + Google Wallet Issuer |

---

## 5. Bumping the version

`pubspec.yaml`:

```yaml
version: 1.0.0+1
#         ↑      ↑
#         semver (must be ≥ min_version_* in /admin/app-settings or app force-updates)
#                build number (increment every push to Codemagic)
```

After bumping, commit + push. Codemagic + GitHub Actions both rebuild.

---

## 6. When you're ready for the App Store / Play Store

1. **Apple Developer Program** ($99/yr) → enroll → create App Store Connect
   record → switch the `ios-unsigned-ipa` workflow to a signed
   distribution build (Codemagic has a one-click "iOS App Store" workflow
   template you can swap in)
2. **Google Play Console** ($25 one-time) → create app record → upload `.aab`
   from `flutter build appbundle --release`

Then update the URLs in `/admin/app-settings` so force-update links point to
the real listings.

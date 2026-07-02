# Hostel Management System

A single Flutter **web** app with three role-based experiences — **Owner (Admin)**,
**Tenant**, and **Staff** — backed by **Firebase** (Auth + Firestore). Everyone
logs in with a unique ID issued by the Owner.

See [`DESIGN.md`](DESIGN.md) for the full design and data model.

**Live app (after first deploy):** https://katakam26.github.io/hostel-management/

---

## What's built

### 👤 Owner (Admin)
- **Dashboard** — live occupancy/headcount counts + this month's **revenue,
  expenses and profit**, with an expense editor.
- **Hostel setup** — blocks → floors → rooms (with sharing, AC, washroom, rent,
  deposit, amenities); adding a room auto-creates its beds.
- **Tenants** — add tenant, auto-issue login ID + password, assign a bed,
  check-in/out, deposit tracking.
- **Staff** — add staff, issue employee login, role filter, salary status,
  shift editor.
- **Payments** — one-tap "Generate rent" for all active tenants, add
  electricity/amenity charges, mark paid/unpaid, monthly collected/pending
  summary.
- **Complaints** — board of all complaints; assign to staff; move through
  open → assigned → in progress → resolved.
- **Food** — edit the daily mess menu; read tenant food feedback.
- **Notices** — post notices/alerts to everyone, tenants only, or staff only.

### 🛏️ Tenant
- **Home** — room & bed, deposit status, pending-dues summary.
- **Payments** — rent history + pay (demo) pending bills.
- **Food** — today's menu + rate the food.
- **Amenities** — room amenities + book a washing-machine slot.
- **Complaints** — raise and track complaints.
- **Notices** — notices feed.
- **Profile** — details, documents, service rating, and a move-out request.

### 🧹 Staff
- **Shifts** — assigned shift timings + assigned tasks (complaints).
- **Attendance** — daily check-in / check-out + history.
- **Complaints** — assigned complaints; advance status to resolved.
- **Salary** — salary amount + monthly payment status.
- **Notices** — notices feed.

---

## Running it — no local Flutter needed (GitHub Pages)

This repo ships a GitHub Actions workflow
([`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)) that builds the
Flutter web app on GitHub's servers and publishes it to **GitHub Pages** on
every push to `main`.

**One-time setup:**
1. In the repo, go to **Settings → Pages → Build and deployment** and set
   **Source = GitHub Actions**.
2. Push to `main` (or use **Actions → Build & deploy… → Run workflow**).
3. Wait for the green check, then open
   `https://katakam26.github.io/hostel-management/`.

## Firebase setup (required for login/data to work)

Firebase **web** config is already wired in `lib/firebase_options.dart`
(project `hostel-management-8b8dd`). To make login and data work you must enable
these in the [Firebase console](https://console.firebase.google.com/):

1. **Authentication → Sign-in method →** enable **Email/Password**.
   (The app maps each unique ID to a synthetic `id@hostel.app` email.)
2. **Firestore Database → Create database** (start in production or test mode).
3. **Firestore → Rules →** paste [`firestore.rules`](firestore.rules) and
   publish (or run `firebase deploy --only firestore:rules`).

### First run
- Open the app → **"First time? Create owner account"** → set a password.
  You then log in with ID **`OWNER`** + that password.
- As Owner: add blocks/floors/rooms, then tenants and staff. Each tenant/staff
  gets a login ID + one-time password shown on screen — hand those over so they
  can log in to their own app.

---

## Running locally (optional)

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(Dart ≥ 3.12).

```bash
flutter pub get
flutter run -d chrome
```

## Notes / next steps
- **Payments** are marked paid in-app (demo). Swap `_pay` in
  `tenant_payments_screen.dart` for a real gateway (Razorpay/Stripe) to charge
  cards.
- **Push notifications (FCM)** and **Cloud Functions** (auto rent reminders) are
  described in `DESIGN.md` and can be added on the Firebase Blaze plan; the app
  covers notices in-app today.
- Android build isn't configured (web-only). Register an Android app in Firebase
  and add its options to `firebase_options.dart` to enable it.

# Hostel Management System — Design Document

**Stack:** Flutter (Web + Android) · Firebase (Auth, Firestore, Storage, Cloud Messaging, Cloud Functions)
**Roles:** Owner (Admin) · Tenant · Staff
**Source of requirements:** `requirements of hostel management.pdf`

---

## 1. Overview

A single Flutter app with **three role-based experiences**. The Owner sets up the hostel,
manages everyone, and sees business dashboards. Tenants and Staff log in with a **unique ID
issued by the Owner** and see only their own screens.

```
                        ┌─────────────────────┐
                        │     Login (UID)     │
                        └──────────┬──────────┘
                  role lookup in Firestore decides destination
        ┌───────────────────┬───────────────────┬───────────────────┐
        ▼                   ▼                   ▼
   OWNER APP            TENANT APP           STAFF APP
   (full control)     (self-service)       (tasks & shifts)
```

---

## 2. Authentication & Identity ("login with unique ID")

The spec says **each user logs in with a unique ID given by the Owner**. Firebase Auth is
built around email/password, so we bridge the two cleanly:

- When the Owner creates a tenant/staff, the app generates a **unique ID** (e.g. `TEN-1027`, `STF-4012`)
  and a temporary password.
- Behind the scenes we register a Firebase Auth account using a synthetic email:
  `ten-1027@hostel.app` (the user only ever types the ID + password).
- A `users/{uid}` document stores `{ uniqueId, role, name, linkedDocId }` so that after login we
  read the role and route to the correct app.
- Owner signs up once with a real email/password (the first/admin account).

**Roles:** `owner`, `tenant`, `staff`. Role-based access is enforced by **Firestore Security Rules**.

---

## 3. Firestore Data Model (collections)

```
users/{uid}
  uniqueId, role, name, email, linkedId, createdAt

hostels/{hostelId}
  name, ownerUid, address

blocks/{blockId}
  hostelId, name (e.g. "A Block")

floors/{floorId}
  blockId, number

rooms/{roomId}
  blockId, floorId, roomCode (UNIQUE id),
  sharing (1|2|3), ac (bool), washroom ("attached"|"common"),
  rentAmount, depositAmount, status ("vacant"|"occupied"),
  amenities: [ "wifi", "washing_machine", ... ]

beds/{bedId}
  roomId, bedNumber, occupiedByTenantId (nullable)

tenants/{tenantId}
  uniqueId, name, phone, email, photoUrl,
  roomId, bedId, checkInDate, checkOutDate (nullable),
  depositPaid (bool), depositAmount,
  documents: [ {type, url} ], status ("active"|"moved_out")

staff/{staffId}
  uniqueId (employee id), name, phone, role ("cleaner"|"warden"|"security"),
  salaryAmount, salaryStatus ("paid"|"unpaid"),
  shifts: [ {day, start, end} ]

attendance/{attendanceId}
  personType ("tenant"|"staff"), personId, date, checkIn, checkOut

payments/{paymentId}
  tenantId, month, type ("rent"|"deposit"|"electricity"|"amenity"),
  baseRent, electricityBill, extraAmenityCharge, totalAmount,
  status ("paid"|"unpaid"), paidAt, method

complaints/{complaintId}
  raisedByType ("tenant"), raisedById,
  category ("water"|"electricity"|"fan_ac"|"cleaning"|"wifi"|"food"|"other"),
  description, status ("open"|"assigned"|"in_progress"|"resolved"),
  assignedStaffId (nullable), createdAt, updatedAt

requests/{requestId}            // staff requests + tenant move-out requests
  fromType, fromId, kind ("staff_request"|"move_out"), details, status, createdAt

menus/{menuId}
  date, breakfast, lunch, dinner

foodFeedback/{feedbackId}
  tenantId, date, rating (1-5), comment

notices/{noticeId}
  title, body, audience ("all"|"tenants"|"staff"), urgent (bool), createdAt

amenityBookings/{bookingId}     // washing machine slots
  amenity ("washing_machine"), tenantId, date, slotStart, slotEnd

expenses/{expenseId}            // for dashboard profit calc
  type ("recurring"|"non_recurring"), category, amount, month, note

ratings/{ratingId}
  tenantId, target ("food"|"service"), rating, comment, createdAt
```

---

## 4. Feature → Screen Map

### 👤 OWNER APP
| Module | Screens | Key actions |
|---|---|---|
| **Hostel Setup** | Blocks, Floors, Rooms | Create blocks/floors/rooms; set sharing type, unique room code, amenities, deposit |
| **Room Management** | Room list + detail | Edit AC/non-AC, washroom type, rent; status vacant/occupied (auto from beds) |
| **Tenant Management** | Tenant list, Add tenant, Tenant detail | Add tenant + docs, issue unique ID, check-in/out, stay history, attendance, deposit, complaints |
| **Staff Management** | Staff list, Add staff, Staff detail | Add staff + employee ID, role filter, salary, assign shifts, track requests |
| **Rent & Payments** | Payments board | Paid/unpaid status, set rent by room type, electricity + extra-amenity charges, history, **auto reminders** (Cloud Function) |
| **Dashboard** | Home metrics | Tenant count, recurring/non-recurring expenses, monthly revenue, profit, complaint overview |
| **Food & Mess** | Daily menu, Feedback | Update menu; read tenant food feedback |
| **Notices** | Notices composer | Send urgent alerts, rules, mess timings, holidays (push via FCM) |
| **Complaints** | Complaints board | View all, assign to staff, track status |

### 🛏️ TENANT APP
| Module | Screens | Key actions |
|---|---|---|
| **Login** | UID login | Login with owner-issued unique ID |
| **Dashboard** | Home | Room & bed number, payment status, raise complaint |
| **Profile & Docs** | Profile | View/update documents, check-in date |
| **Rent & Payments** | Pay rent, History | Pay monthly rent, view payment history |
| **Food / Mess** | Menu, Food complaint | View breakfast/lunch/dinner, raise food complaint |
| **Notices** | Notices feed | Alerts, rules, mess timings, holidays |
| **Amenities** | Amenities, WM booking | View wifi/washing machine, book washing-machine slots, usage timings |
| **Move-out** | Checkout request | Submit move-out date |
| **Complaints** | Raise + Track | Water/electricity/fan-AC/cleaning/wifi; track status |
| **Feedback** | Ratings | Rate food, rate services, contact owner |

### 🧹 STAFF APP
| Module | Screens | Key actions |
|---|---|---|
| **Login** | UID login | Login with employee unique ID |
| **Shifts** | Shift + tasks | View shift timings & assigned tasks |
| **Attendance** | Check-in/out, History | Mark check-in/out, view history |
| **Notices** | Notices feed | Rule updates, shift-change notices |
| **Salary** | Salary info | View salary amount + payment status |
| **Complaints** | Assigned complaints | View assigned complaints, problem details, update status |

---

## 5. App Structure (folders)

```
lib/
  main.dart
  firebase_options.dart
  models/         (tenant.dart, staff.dart, room.dart, payment.dart, complaint.dart, ...)
  services/       (auth_service.dart, firestore_service.dart, storage_service.dart)
  screens/
    auth/         (login_screen.dart, splash_router.dart)
    owner/        (dashboard, hostel_setup, tenants, staff, payments, notices, menu, complaints)
    tenant/       (dashboard, payments, food, amenities, complaints, profile, feedback)
    staff/        (dashboard, shifts, attendance, salary, complaints)
  widgets/        (shared cards, buttons, forms)
```

---

## 6. Firebase Services Used

- **Auth** — unique-ID login (synthetic email under the hood)
- **Firestore** — all data above (real-time updates)
- **Storage** — tenant documents, profile photos
- **Cloud Messaging (FCM)** — urgent notices & alerts
- **Cloud Functions** — auto rent reminders, monthly revenue/profit calc, recurring-expense automation
- **Security Rules** — role-based access control

---

## 7. Phased Build Plan (proposed)

**Phase 0 — Project setup**
- Create Flutter project, add Firebase, connect project, set up auth + role routing.

**Phase 1 — Owner core (most valuable first)**
- Hostel setup (blocks/floors/rooms), Room management, Tenant management, Staff management.

**Phase 2 — Payments & dashboard**
- Rent/payment tracking, pricing rules, dashboard metrics (revenue, expenses, profit, complaints).

**Phase 3 — Tenant app**
- Login, dashboard, payments, complaints, food menu, amenities + WM booking, move-out, feedback.

**Phase 4 — Staff app**
- Login, shifts/tasks, attendance, salary, assigned complaint handling.

**Phase 5 — Automation & polish**
- FCM notices, auto rent reminders (Cloud Functions), expense automation, security rules hardening.

---

## 8. Decisions still needed from you

1. **Platforms:** Web only, or Web + Android? (affects Firebase setup & push notifications)
2. **Online payments:** Real gateway (Razorpay/Stripe) or just mark paid/unpaid manually?
3. **Scope for now:** Academic demo (mock-friendly) or production-ready?
4. **Firebase account:** You'll need to create a Firebase project (Google login) — OK to proceed when we reach that step?
5. **Build order:** Is the phased plan above good, or do you want a different module first?
```


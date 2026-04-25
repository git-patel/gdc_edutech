# Login & Onboarding Flow – Summary of Changes

**Date:** February 2026  
**Scope:** Professional login/onboarding flow, returning vs new user, profile photo, Home/Profile data from storage and Firestore.

---

## 1. What Was Fixed

| Issue | Fix |
|-------|-----|
| Home showed wrong role ("parent") | Home now uses `OnboardingStorage.getProfile()` and `getRole()` only; no hardcoded default. Greeting: Student = "Hi {name}, ready to learn?" / Parent = "Hi {name}, track progress". |
| Profile photo not shown | Profile screen uses `FirebaseAuth.currentUser?.photoURL` and Firestore `photoUrl`; `CircleAvatar` shows `NetworkImage(photoUrl)` when set, else initials. |
| Onboarding forced full form for existing users | After Google sign-in we call `FirebaseService.userExists(uid)`. If doc exists → load from Firestore, sync to local, toast "Welcome back!", go to MainScreen (skip form). |
| No new vs returning user check | Returning: `userExists(uid)` → true → `getUserDocument` → `completeOnboardingFromFirestore(doc)` → MainScreen. New: pre-fill name from `displayName`, show form, "Continue" → save local + Firestore → MainScreen. |
| Name required even when Google provides displayName | Name is **not** required when using Google. New users get name pre-filled from `user.displayName ?? user.email`; optional hint shown. "Continue" uses that name if field is empty. |

---

## 2. New / Updated Flow

### 2.1 Onboarding last page – "Sign in with Google"

1. User taps **Sign in with Google** (no name validation).
2. `FirebaseService.signInWithGoogle()` runs.
3. If cancel/fail → toast "Sign in was cancelled or failed. Try again."
4. If success → `user = credential.user`, then `FirebaseService.userExists(user.uid)`:
   - **Returning user (doc exists):**
     - `getUserDocument(uid)` → `OnboardingStorage.completeOnboardingFromFirestore(doc)` → `setUserUid(uid)`.
     - Toast: **"Welcome back!"**
     - Navigate to **MainScreen** (form skipped).
   - **New user (doc does not exist):**
     - Pre-fill name field with `user.displayName ?? user.email ?? ''`.
     - Set `_signedInNewUserWaitingProfile = true`, `_currentUserForNewProfile = user`.
     - Bottom shows single **"Continue"** button (no Skip / no second Google button).
     - User fills role, board, standard, goal, medium, child name (if parent). Name is optional (pre-filled).
     - On **Continue**: validate only role + child name (if parent). Name = controller text or `displayName ?? email ?? 'User'`.
     - `completeOnboarding` + `setUserUid` + `ensureUserDocument`.
     - Toast: **"Profile setup complete"**
     - Navigate to **MainScreen**.

### 2.2 Onboarding last page – "Skip for now"

- Unchanged: name required, role required, child name required if parent.
- `OnboardingStorage.completeOnboarding(...)` only (no Firebase).
- Navigate to **MainScreen** (guest).

### 2.3 Profile screen

- **Load:** `getRole()` + `getProfile()` from local first.
- **Photo:** `_photoUrl = FirebaseAuth.currentUser?.photoURL`; if Firestore fallback runs, `_photoUrl` can also come from doc `photoUrl`.
- **Fallback:** If signed in and local profile empty (no name, no board/standard) → `getUserDocument(uid)` → set state from doc and `completeOnboarding` + `setUserUid` to sync to local.
- **UI:** `CircleAvatar` with `backgroundImage: NetworkImage(_photoUrl)` when `_photoUrl` is set; otherwise initials in `primaryContainer`.

### 2.4 Home screen

- `_loadProfile()` in `initState`: `getRole()` + `getProfile()` → setState `_role`, `_name`, `_board`, `_standard`, `_goal`.
- Greeting:
  - Student: **"Hi {name}, ready to learn?"**
  - Parent: **"Hi {name}, track progress"**
- Uses `_name ?? 'Student'` / `_name ?? 'Parent'` when name is empty.

### 2.5 Logout

- `FirebaseAuth.instance.signOut()` + `GoogleSignIn().signOut()` + `OnboardingStorage.clearOnboarding()`.
- `clearOnboarding()` now also removes all **pending_*** keys (used if we add pending-profile-before-Google later).
- Then `pushAndRemoveUntil(OnboardingScreen)`.

---

## 3. File-by-File Changes

### 3.1 `lib/services/firebase_service.dart`

- **Added:** `Future<bool> userExists(String uid)` – returns true if `users/{uid}` document exists.

### 3.2 `lib/services/onboarding_storage.dart`

- **Added:** `completeOnboardingFromFirestore(Map<String, dynamic> doc)` – writes role, name, board, standard, goal, medium, childName from doc to SharedPreferences and sets `onboarding_completed = true`. Does not set `user_uid` (caller calls `setUserUid` after).
- **Updated:** `clearOnboarding()` – also removes `pendingRole`, `pendingName`, `pendingBoard`, `pendingStandard`, `pendingGoal`, `pendingMedium`, `pendingChildName`.
- **Removed:** Debug print statements from `completeOnboarding` and `getProfile`.

### 3.3 `lib/screens/onboarding_screen.dart`

- **State:** `_signedInNewUserWaitingProfile`, `_currentUserForNewProfile` (User?).
- **"Sign in with Google":** No name/role validation before sign-in. After sign-in: `userExists(uid)` → returning: sync from Firestore, "Welcome back!", MainScreen. New: pre-fill name, set `_signedInNewUserWaitingProfile = true`, show form + single "Continue" button.
- **New method:** `_completeNewUserProfileAfterGoogle()` – validates role + child name if parent; name from controller or `displayName ?? email ?? 'User'`; then `completeOnboarding` + `setUserUid` + `ensureUserDocument`; toast "Profile setup complete"; MainScreen.
- **Last page UI:** When `_signedInNewUserWaitingProfile` → only "Continue". Else → "Sign in with Google" + "Skip for now".
- **_ProfilePage:** New parameter `nameOptional`. When true, name hint = "Pre-filled from Google (optional)" and small caption "Name is optional when signed in with Google."

### 3.4 `lib/screens/profile_screen.dart`

- **State:** `_photoUrl` (String?).
- **_loadProfile:** Load from local first. If `currentUser != null` set `_photoUrl = user.photoURL`. If local profile empty → Firestore fallback; from doc also set `_photoUrl` from `photoUrl` if present.
- **Header:** `CircleAvatar` with `backgroundImage: NetworkImage(_photoUrl)` when non-empty; else initials. Removed debug prints.

### 3.5 `lib/screens/home_screen.dart`

- **Greeting:** Parent copy changed to "Hi {name}, track progress" (no "today?"). Role/name still from `_loadProfile()` (getProfile / getRole).

---

## 4. Flow Diagram

```
[Onboarding – Last page]
        │
        ├─ "Sign in with Google"
        │       │
        │       ├─ success → userExists(uid)?
        │       │       ├─ YES (returning) → completeOnboardingFromFirestore(doc) → setUserUid → "Welcome back!" → MainScreen
        │       │       └─ NO (new)        → pre-fill name, show form, "Continue" → completeOnboarding + setUserUid + ensureUserDocument → "Profile setup complete" → MainScreen
        │       └─ cancel/fail → toast
        │
        └─ "Skip for now" → completeOnboarding (guest) → MainScreen

[Profile tab]
    _loadProfile(): getRole + getProfile (local) → setState
    If currentUser != null → _photoUrl = user.photoURL
    If local empty → getUserDocument → setState + completeOnboarding + setUserUid (sync)
    UI: CircleAvatar(photoUrl or initials)

[Home tab]
    _loadProfile(): getRole + getProfile → setState
    Greeting: Student "Hi {name}, ready to learn?" | Parent "Hi {name}, track progress"

[Logout]
    signOut (Auth + Google) → clearOnboarding (incl. pending_*) → OnboardingScreen
```

---

## 5. Custom Widgets & Theme

- All screens use theme via `Theme.of(context)`, `colorScheme`, and custom widgets (PrimaryButton, SecondaryButton, AppTitle, SectionTitle, BodyText, BodySmall, CustomTextField, etc.) per `.cursorrules`.
- Light/Dark supported via existing app theme; no hardcoded colors in the updated flow.

---

This completes the professional login/onboarding flow with returning vs new user handling, optional name for Google, profile photo, and correct Home/Profile data from storage and Firestore.

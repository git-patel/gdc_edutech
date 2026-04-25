# Google Login & User Data – Development Report

**Project:** LearnFlow (HVN Flutter)  
**Scope:** Google Sign-In, user profile persistence, Firebase usage, and end-to-end flow.

---

## 1. Overview

We implemented:

- **Google Sign-In** on the last onboarding screen (optional; user can also “Skip for now”).
- **Dual storage of user data:** local device (SharedPreferences) and cloud (Firestore).
- **Profile screen** that shows name, role, board, standard, goal, medium, and (for parents) child name — loaded from local storage, with a **Firestore fallback** when local profile is empty but the user is signed in.
- **Logout** that signs out from Firebase + Google and clears local onboarding/profile, then returns to onboarding.

---

## 2. Firebase Services Used

| Service | Purpose | Where used |
|--------|---------|------------|
| **Firebase Auth** | Sign-in state, Google credential, `currentUser` (uid, email, displayName, photoURL). | `FirebaseService.auth`, `AuthWrapper`, Profile screen (current user check), logout. |
| **Cloud Firestore** | Persist user profile in the cloud at `users/{uid}`. | `FirebaseService.ensureUserDocument`, `FirebaseService.getUserDocument` (profile fallback). |
| **Firebase Core** | App initialization (`Firebase.initializeApp`). | `main.dart`, `FirebaseService.initialize`. |

**Note:** Google Sign-In is done via the **google_sign_in** package; the resulting credential is then passed to **Firebase Auth** with `signInWithCredential(GoogleAuthProvider.credential(...))`, so the “logged-in user” is always a Firebase Auth user.

---

## 3. Local Storage (SharedPreferences)

**File:** `lib/services/onboarding_storage.dart`  
**Keys (OnboardingKeys):**

| Key | Purpose |
|-----|--------|
| `onboarding_completed` | Boolean – has user finished onboarding (skip or Google). |
| `user_role` | `"student"` or `"parent"`. |
| `user_name` | Display name (from form or Google). |
| `user_board` | e.g. CBSE, ICSE, State, Others. |
| `user_standard` | e.g. 1–12. |
| `user_goal` | e.g. School exams, Olympiads, JEE/NEET, General knowledge. |
| `user_medium` | e.g. English, Gujarati, Hindi. |
| `child_name` | Filled only for parent role. |
| `user_uid` | Firebase Auth UID after sign-in. |
| `pending_*` | Optional pending profile saved before opening Google sign-in UI (to avoid losing form data when app goes to background). |

**Main APIs:**

- `completeOnboarding(...)` – set onboarding completed and save full profile.
- `getProfile()` – return map of name, board, standard, goal, medium, childName, userUid.
- `getRole()` – return role.
- `setUserUid(uid)` – save Firebase UID after sign-in.
- `clearOnboarding()` – clear all keys (used on logout).

---

## 4. End-to-End Flow

### 4.1 App start

```
main()
  → Firebase.initializeApp (if not already)
  → runApp(LearnFlowApp)
  → MaterialApp home: AuthWrapper
```

**AuthWrapper:**

- Listens to `FirebaseService.auth.authStateChanges()`.
- **Waiting:** show `SplashScreen`.
- **User != null (signed in):** show `MainScreen` (no onboarding).
- **User == null:**  
  - Check `OnboardingStorage.isOnboardingCompleted()`.  
  - **true:** show `MainScreen` (guest who skipped sign-in).  
  - **false:** show `OnboardingScreen`.

So: **Google sign-in** is only triggered from onboarding; after that, “signed in” is determined only by Firebase Auth.

---

### 4.2 Onboarding (last page – profile form)

User fills:

- Name (required)
- Role: Student / Parent (required)
- If Parent: Child’s name (required)
- Board, Standard, Goal, Medium (dropdowns)

Two actions:

**A) “Skip for now”**

- `_finishOnboarding()` runs.
- `OnboardingStorage.completeOnboarding(role, name, board, standard, goal, medium, childName)`.
- No Firebase; no `setUserUid`.
- Navigate to `MainScreen`.

**B) “Sign in with Google”**

- `_signInWithGoogleAndFinish()` runs.
- Validate name (and child name if parent).
- Call `FirebaseService.signInWithGoogle()`:
  - Opens Google sign-in UI (e.g. SignInHubActivity on Android).
  - User picks account; returns `UserCredential` or null.
- If credential/user is null → toast, stop.
- Else:
  1. **Save profile locally:**  
     `OnboardingStorage.completeOnboarding(role, name, _board, _standard, _goal, _medium, childNameValue)`  
     (uses form state: `_board`, `_standard`, etc.)
  2. **Save UID:**  
     `OnboardingStorage.setUserUid(user.uid)`
  3. **Save profile to Firestore:**  
     `FirebaseService.ensureUserDocument(user.uid, { name, email, photoUrl, role, board, standard, goal, medium, childName })`  
     Name in doc: `user.displayName ?? name`.
  4. Navigate to `MainScreen` (`pushReplacement`).

So after Google sign-in, user data exists in:

- **Firebase Auth:** uid, email, displayName, photoURL (from Google).
- **SharedPreferences:** full profile (role, name, board, standard, goal, medium, childName, userUid).
- **Firestore `users/{uid}`:** same profile fields (cloud copy).

---

### 4.3 MainScreen and Profile tab

- **MainScreen** shows bottom nav; one tab is **ProfileScreen**.
- **ProfileScreen** in `initState`:
  - `_loadProfile()`:
    1. Load **role** and **profile** from `OnboardingStorage.getRole()` and `OnboardingStorage.getProfile()`.
    2. Update UI state (name, board, standard, goal, medium, childName).
    3. **Fallback:** if `FirebaseService.auth.currentUser != null` and local profile is effectively empty (no name, no board/standard), then:
       - Call `FirebaseService.getUserDocument(user.uid)` (Firestore).
       - If document exists, set UI from doc and call `OnboardingStorage.completeOnboarding(...)` and `setUserUid(uid)` to sync Firestore → local.

So profile is shown from **local storage first**, and from **Firestore** only when local is empty but user is signed in (e.g. after reinstall or lost local state).

---

### 4.4 Logout (Profile screen)

- User taps Logout → confirmation dialog.
- On confirm:
  1. `FirebaseAuth.instance.signOut()`
  2. `GoogleSignIn().signOut()`
  3. `OnboardingStorage.clearOnboarding()` (clears all onboarding + profile keys in SharedPreferences)
  4. `pushAndRemoveUntil(OnboardingScreen)` so back stack is cleared and user sees onboarding again.

Next launch: AuthWrapper sees no Firebase user and (after clear) onboarding not completed → shows OnboardingScreen again.

---

## 5. Where User Data Lives (Summary)

| Data | Firebase Auth | Firestore | SharedPreferences |
|------|----------------|-----------|--------------------|
| UID | ✓ (currentUser.uid) | Document ID `users/{uid}` | user_uid |
| Email | ✓ (from Google) | users/{uid}.email | — |
| Display / name | ✓ (displayName) | users/{uid}.name | user_name |
| Photo URL | ✓ (photoURL) | users/{uid}.photoUrl | — |
| Role | — | users/{uid}.role | user_role |
| Board | — | users/{uid}.board | user_board |
| Standard | — | users/{uid}.standard | user_standard |
| Goal | — | users/{uid}.goal | user_goal |
| Medium | — | users/{uid}.medium | user_medium |
| Child name | — | users/{uid}.childName | child_name |
| Onboarding done | — | — | onboarding_completed |

---

## 6. Files and Responsibilities

| File | Responsibility |
|------|----------------|
| `lib/main.dart` | Firebase init, `AuthWrapper` as home. |
| `lib/screens/auth_wrapper.dart` | Route by auth state + onboarding completed; decides OnboardingScreen vs MainScreen. |
| `lib/screens/onboarding_screen.dart` | Onboarding UI; `_finishOnboarding()` (skip) and `_signInWithGoogleAndFinish()` (Google sign-in + save local + Firestore + navigate). |
| `lib/screens/profile_screen.dart` | Load profile from storage; Firestore fallback when local empty; logout (Firebase + Google signOut + clearOnboarding). |
| `lib/services/firebase_service.dart` | `signInWithGoogle()`, `ensureUserDocument()`, `getUserDocument()`, `auth`, Firestore `users` collection. |
| `lib/services/onboarding_storage.dart` | SharedPreferences: completeOnboarding, getProfile, getRole, setUserUid, clearOnboarding, (optional) pending profile. |

---

## 7. Firestore Structure

- **Collection:** `users`
- **Document ID:** Firebase Auth UID
- **Fields:**  
  `name`, `email`, `photoUrl`, `createdAt` (server timestamp), `role`, `board`, `standard`, `goal`, `medium`, `childName`  
  (all stored at sign-in via `ensureUserDocument` with `SetOptions(merge: true)`).

---

## 8. Flow Diagram (High Level)

```
App Launch
    → AuthWrapper
        → authStateChanges()
        → If user != null → MainScreen (Profile loads from Storage / Firestore fallback)
        → If user == null → isOnboardingCompleted?
            → Yes → MainScreen
            → No  → OnboardingScreen

OnboardingScreen (last page)
    → "Skip for now"  → completeOnboarding() → MainScreen (no Firebase user)
    → "Sign in with Google"
        → signInWithGoogle() [Auth + Google]
        → completeOnboarding() [SharedPreferences]
        → setUserUid(uid)
        → ensureUserDocument(uid, profile) [Firestore]
        → MainScreen

ProfileScreen
    → getRole() + getProfile() [SharedPreferences]
    → If signed in and profile empty → getUserDocument(uid) [Firestore] → setState + completeOnboarding (sync to local)

Logout
    → FirebaseAuth.signOut() + GoogleSignIn().signOut() + clearOnboarding() → OnboardingScreen
```

This is the full flow of what we developed for Google login and user data saving and where Firebase (Auth + Firestore) is used in detail.

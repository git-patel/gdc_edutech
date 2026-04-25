# Admin Flow – Setup

## 1. Firestore: Add `isAdmin` to a user

Admin access is controlled by a boolean field **`isAdmin`** on the user document in Firestore.

### Steps in Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com) → your project.
2. Go to **Firestore Database**.
3. Open the **`users`** collection.
4. Select the document for your **test account** (document ID = the user’s Firebase Auth UID).
   - If you don’t see it, sign in once in the app with that Google account so `ensureUserDocument` creates the doc; then refresh the console.
5. Click **Add field** (or the **+** next to existing fields).
6. Set:
   - **Field name:** `isAdmin`
   - **Type:** `boolean`
   - **Value:** `true`
7. Save.

That user will then see **Admin Panel** in the Profile tab and can open the Admin Dashboard.

### Optional: Set via Console UI

- Field: `isAdmin`  
- Type: boolean  
- Value: `true`

---

## 2. App flow

- **Profile (Me)** → if current user’s `users/{uid}.isAdmin == true` → show **Admin Panel** ListTile.
- **Admin Panel** → opens **Admin Dashboard** (Manage Subjects, Chapters, Contents).
- **Admin Dashboard** checks `FirebaseService.isCurrentUserAdmin()`; if false, shows “Admin access only” and a back button.
- Admin users use the app normally (Home, My Class, Library, Me) and can open Admin from Profile.

---

## 3. Firestore indexes (when prompted)

If you filter contents by "Library only" or use orderBy on filtered queries, Firestore may ask you to create a composite index. Use the link in the error message to create it in the Firebase Console.

## 4. Security rules (recommended for production)

In **Firestore → Rules**, restrict write access to admin-only for CMS collections:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    match /users/{userId} { allow read, write: if request.auth != null && request.auth.uid == userId; }
    match /subjects/{id} { allow read: true; allow write: if isAdmin(); }
    match /chapters/{id} { allow read: true; allow write: if isAdmin(); }
    match /contents/{id} { allow read: true; allow write: if isAdmin(); }
  }
}
```

The app only reads `isAdmin` to show the Admin Panel; these rules enforce who can actually modify data.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

/// Central Firebase access: initialization, auth, and Firestore.
/// Call [initialize] once at app startup (e.g. from main.dart).
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;

  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Call once at app startup (or use to ensure Firebase is ready elsewhere).
  /// Safe to call again; no-op if already initialized.
  static Future<void> initialize() async {
    if (_initialized) return;
    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      return;
    }
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    _initialized = true;
  }

  /// Sign in with Google. Returns [UserCredential] on success, null on error/cancel.
  /// Caller should show toast on null.
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await auth.signInWithCredential(credential);
    } catch (_) {
      return null;
    }
  }

  /// Create or update Firestore user document at /users/{uid}.
  /// [profile] should include: name, email?, photoUrl?, role, board, standard, goal, medium?, childName?.
  static Future<void> ensureUserDocument(String uid, Map<String, dynamic> profile) async {
    debugPrint('[HGP] FirebaseService.ensureUserDocument uid=$uid profileKeys=${profile.keys.toList()}');
    try {
      final ref = users.doc(uid);
      final data = <String, dynamic>{
        'name': profile['name'],
        'email': profile['email'] ?? '',
        'photoUrl': profile['photoUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'role': profile['role'] ?? 'student',
        'board': profile['board'] ?? '',
        'standard': profile['standard'] ?? '',
        'goal': profile['goal'] ?? '',
        'medium': profile['medium'] ?? '',
        'childName': profile['childName'] ?? '',
      };
      await ref.set(data, SetOptions(merge: true));
      debugPrint('[HGP] FirebaseService.ensureUserDocument SUCCESS uid=$uid');
    } catch (e, st) {
      debugPrint('[HGP] FirebaseService.ensureUserDocument ERROR uid=$uid error=$e');
      debugPrint('[HGP] FirebaseService.ensureUserDocument stackTrace=$st');
      rethrow;
    }
  }

  /// Returns true if a user document exists at users/{uid}.
  static Future<bool> userExists(String uid) async {
    debugPrint('[HGP] FirebaseService.userExists uid=$uid');
    try {
      final snap = await users.doc(uid).get();
      debugPrint('[HGP] FirebaseService.userExists uid=$uid exists=${snap.exists}');
      return snap.exists;
    } catch (e, st) {
      debugPrint('[HGP] FirebaseService.userExists ERROR uid=$uid error=$e');
      debugPrint('[HGP] FirebaseService.userExists stackTrace=$st');
      return false;
    }
  }

  /// Returns true if the current user's Firestore doc has isAdmin == true.
  static Future<bool> isCurrentUserAdmin() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final snap = await users.doc(uid).get();
      if (!snap.exists || snap.data() == null) return false;
      final isAdmin = snap.data()!['isAdmin'];
      return isAdmin == true;
    } catch (_) {
      return false;
    }
  }

  /// Get user document from Firestore (for profile fallback when local storage is empty).
  static Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    debugPrint('[HGP] FirebaseService.getUserDocument uid=$uid');
    try {
      final snap = await users.doc(uid).get();
      if (snap.exists && snap.data() != null) {
        debugPrint('[HGP] FirebaseService.getUserDocument uid=$uid hasData=true keys=${snap.data()!.keys.toList()}');
        return snap.data();
      }
      debugPrint('[HGP] FirebaseService.getUserDocument uid=$uid hasData=false');
      return null;
    } catch (e, st) {
      debugPrint('[HGP] FirebaseService.getUserDocument ERROR uid=$uid error=$e');
      debugPrint('[HGP] FirebaseService.getUserDocument stackTrace=$st');
      return null;
    }
  }

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Users (profile, role, board, standard, etc.)
  static CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  /// Content items (PDF, video, article, etc.) – unstructured library.
  static CollectionReference<Map<String, dynamic>> get contents =>
      _firestore.collection('contents');

  /// Chapters (per subject) – structured curriculum.
  static CollectionReference<Map<String, dynamic>> get chapters =>
      _firestore.collection('chapters');

  /// Subjects (e.g. Maths, Science) – structured curriculum.
  static CollectionReference<Map<String, dynamic>> get subjects =>
      _firestore.collection('subjects');

  static Reference get _storageRef => FirebaseStorage.instance.ref();

  /// Upload a file to [path] (e.g. "contents/abc123.pdf") and return its download URL.
  static Future<String?> uploadFileAndGetUrl(File file, String path) async {
    try {
      final ref = _storageRef.child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e, st) {
      debugPrint('[HGP] FirebaseService.uploadFileAndGetUrl ERROR path=$path error=$e');
      debugPrint('[HGP] stackTrace=$st');
      return null;
    }
  }

  /// Stream of all subjects, ordered by order (then by name in app if needed).
  static Stream<QuerySnapshot<Map<String, dynamic>>> subjectsStream() {
    return subjects.orderBy('order').snapshots();
  }

  static Future<void> addSubject(Map<String, dynamic> data) async {
    await subjects.add(data);
  }

  static Future<void> updateSubject(String id, Map<String, dynamic> data) async {
    await subjects.doc(id).update(data);
  }

  static Future<void> deleteSubject(String id) async {
    await subjects.doc(id).delete();
  }

  /// Stream of chapters, optionally filtered by [subjectId].
  static Stream<QuerySnapshot<Map<String, dynamic>>> chaptersStream({String? subjectId}) {
    if (subjectId != null && subjectId.isNotEmpty) {
      return chapters.where('subjectId', isEqualTo: subjectId).orderBy('order').snapshots();
    }
    return chapters.orderBy('order').snapshots();
  }

  static Future<void> addChapter(Map<String, dynamic> data) async {
    await chapters.add(data);
  }

  static Future<void> updateChapter(String id, Map<String, dynamic> data) async {
    await chapters.doc(id).update(data);
  }

  static Future<void> deleteChapter(String id) async {
    await chapters.doc(id).delete();
  }

  /// Stream of contents. [chapterId] = specific chapter; [libraryOnly] = true for contents with no chapter; both null = all.
  static Stream<QuerySnapshot<Map<String, dynamic>>> contentsStream({String? chapterId, bool libraryOnly = false}) {
    if (libraryOnly) {
      return contents.where('chapterId', isNull: true).orderBy('title').snapshots();
    }
    if (chapterId != null && chapterId.isNotEmpty) {
      return contents.where('chapterId', isEqualTo: chapterId).orderBy('title').snapshots();
    }
    return contents.orderBy('title').snapshots();
  }

  static Future<void> addContent(Map<String, dynamic> data) async {
    await contents.add(data);
  }

  static Future<void> updateContent(String id, Map<String, dynamic> data) async {
    await contents.doc(id).update(data);
  }

  static Future<void> deleteContent(String id) async {
    await contents.doc(id).delete();
  }
}

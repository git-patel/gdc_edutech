import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for onboarding and profile in SharedPreferences.
abstract final class OnboardingKeys {
  static const String onboardingCompleted = 'onboarding_completed';
  static const String userRole = 'user_role';
  static const String userName = 'user_name';
  static const String userBoard = 'user_board';
  static const String userStandard = 'user_standard';
  static const String userGoal = 'user_goal';
  static const String userMedium = 'user_medium';
  static const String childName = 'child_name';
  static const String userUid = 'user_uid';
  // Pending profile saved before Google sign-in (so we don't lose it when activity goes to background)
  static const String pendingRole = 'pending_role';
  static const String pendingName = 'pending_name';
  static const String pendingBoard = 'pending_board';
  static const String pendingStandard = 'pending_standard';
  static const String pendingGoal = 'pending_goal';
  static const String pendingMedium = 'pending_medium';
  static const String pendingChildName = 'pending_child_name';
}

/// Read/write onboarding completion and profile. Uses SharedPreferences.
class OnboardingStorage {
  OnboardingStorage._();

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// True if user has finished onboarding.
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await _instance;
    return prefs.getBool(OnboardingKeys.onboardingCompleted) ?? false;
  }

  /// Mark onboarding as done and save profile.
  static Future<void> completeOnboarding({
    required String role,
    required String name,
    required String board,
    required String standard,
    required String goal,
    required String medium,
    String? childNameValue,
  }) async {
    debugPrint('[HGP] OnboardingStorage.completeOnboarding role=$role name=$name board=$board standard=$standard goal=$goal medium=$medium childName=$childNameValue');
    final prefs = await _instance;
    await prefs.setBool(OnboardingKeys.onboardingCompleted, true);
    await prefs.setString(OnboardingKeys.userRole, role);
    await prefs.setString(OnboardingKeys.userName, name);
    await prefs.setString(OnboardingKeys.userBoard, board);
    await prefs.setString(OnboardingKeys.userStandard, standard);
    await prefs.setString(OnboardingKeys.userGoal, goal);
    await prefs.setString(OnboardingKeys.userMedium, medium);
    if (childNameValue != null && childNameValue.trim().isNotEmpty) {
      await prefs.setString(OnboardingKeys.childName, childNameValue.trim());
    }
  }

  /// Get saved role (student | parent).
  static Future<String?> getRole() async {
    final prefs = await _instance;
    return prefs.getString(OnboardingKeys.userRole);
  }

  /// Sync profile from Firestore doc to local storage (returning user). Marks onboarding completed.
  static Future<void> completeOnboardingFromFirestore(Map<String, dynamic> doc) async {
    debugPrint('[HGP] OnboardingStorage.completeOnboardingFromFirestore docKeys=${doc.keys.toList()}');
    final prefs = await _instance;
    final name = doc['name']?.toString() ?? '';
    final role = doc['role']?.toString() ?? 'student';
    final board = doc['board']?.toString() ?? '';
    final standard = doc['standard']?.toString() ?? '';
    final goal = doc['goal']?.toString() ?? '';
    final medium = doc['medium']?.toString() ?? '';
    final childName = doc['childName']?.toString() ?? '';
    await prefs.setBool(OnboardingKeys.onboardingCompleted, true);
    await prefs.setString(OnboardingKeys.userRole, role);
    await prefs.setString(OnboardingKeys.userName, name);
    await prefs.setString(OnboardingKeys.userBoard, board);
    await prefs.setString(OnboardingKeys.userStandard, standard);
    await prefs.setString(OnboardingKeys.userGoal, goal);
    await prefs.setString(OnboardingKeys.userMedium, medium);
    if (childName.isNotEmpty) await prefs.setString(OnboardingKeys.childName, childName);
  }

  /// Get saved profile (for settings/display).
  static Future<Map<String, String>> getProfile() async {
    final prefs = await _instance;
    return {
      'name': prefs.getString(OnboardingKeys.userName) ?? '',
      'board': prefs.getString(OnboardingKeys.userBoard) ?? '',
      'standard': prefs.getString(OnboardingKeys.userStandard) ?? '',
      'goal': prefs.getString(OnboardingKeys.userGoal) ?? '',
      'medium': prefs.getString(OnboardingKeys.userMedium) ?? '',
      'childName': prefs.getString(OnboardingKeys.childName) ?? '',
      'userUid': prefs.getString(OnboardingKeys.userUid) ?? '',
    };
  }

  /// Save Firebase user UID after sign-in.
  static Future<void> setUserUid(String uid) async {
    final prefs = await _instance;
    await prefs.setString(OnboardingKeys.userUid, uid);
  }

  /// Update profile (name, board, standard, goal, medium). Keeps role and onboarding completed.
  static Future<void> updateProfile({
    required String name,
    required String board,
    required String standard,
    required String goal,
    required String medium,
  }) async {
    final prefs = await _instance;
    await prefs.setString(OnboardingKeys.userName, name.trim());
    await prefs.setString(OnboardingKeys.userBoard, board);
    await prefs.setString(OnboardingKeys.userStandard, standard);
    await prefs.setString(OnboardingKeys.userGoal, goal);
    await prefs.setString(OnboardingKeys.userMedium, medium);
  }

  /// Clear onboarding and profile (e.g. logout). Next launch will show onboarding again.
  static Future<void> clearOnboarding() async {
    final prefs = await _instance;
    await prefs.setBool(OnboardingKeys.onboardingCompleted, false);
    await prefs.remove(OnboardingKeys.userRole);
    await prefs.remove(OnboardingKeys.userName);
    await prefs.remove(OnboardingKeys.userBoard);
    await prefs.remove(OnboardingKeys.userStandard);
    await prefs.remove(OnboardingKeys.userGoal);
    await prefs.remove(OnboardingKeys.userMedium);
    await prefs.remove(OnboardingKeys.childName);
    await prefs.remove(OnboardingKeys.userUid);
    await prefs.remove(OnboardingKeys.pendingRole);
    await prefs.remove(OnboardingKeys.pendingName);
    await prefs.remove(OnboardingKeys.pendingBoard);
    await prefs.remove(OnboardingKeys.pendingStandard);
    await prefs.remove(OnboardingKeys.pendingGoal);
    await prefs.remove(OnboardingKeys.pendingMedium);
    await prefs.remove(OnboardingKeys.pendingChildName);
  }
}

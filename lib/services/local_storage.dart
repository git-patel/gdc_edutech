import 'package:shared_preferences/shared_preferences.dart';

/// Keys for streak, mastery, and audio position in SharedPreferences.
abstract final class LocalStorageKeys {
  static const String streakCount = 'streak_count';
  static const String streakLastDate = 'streak_last_date';
  static String chapterMastery(String chapterId) => 'chapter_${chapterId}_mastery';
  static String audioPosition(String chapterId) => 'audio_${chapterId}_position';
  static String audioDuration(String chapterId) => 'audio_${chapterId}_duration';
}

/// Streak and chapter mastery (local only). Use SharedPreferences.
class LocalStorage {
  LocalStorage._();

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ─── Streak ─────────────────────────────────────────────────────────────

  /// Current study streak (consecutive days).
  static Future<int> getCurrentStreak() async {
    final prefs = await _instance;
    return prefs.getInt(LocalStorageKeys.streakCount) ?? 0;
  }

  /// Call once per day (e.g. on app open / home). Updates streak from last active date.
  static Future<void> updateStreak() async {
    final prefs = await _instance;
    final today = _dateOnly(DateTime.now());
    final lastStr = prefs.getString(LocalStorageKeys.streakLastDate);
    int newStreak = prefs.getInt(LocalStorageKeys.streakCount) ?? 0;

    if (lastStr == null) {
      newStreak = 1;
    } else {
      final last = DateTime.tryParse(lastStr);
      if (last == null) {
        newStreak = 1;
      } else {
        final lastDate = _dateOnly(last);
        if (today.isAtSameMomentAs(lastDate)) {
          return;
        }
        final diffDays = today.difference(lastDate).inDays;
        if (diffDays == 1) {
          newStreak++;
        } else if (diffDays > 1) {
          newStreak = 1;
        } else {
          return;
        }
      }
    }

    await prefs.setInt(LocalStorageKeys.streakCount, newStreak);
    await prefs.setString(LocalStorageKeys.streakLastDate, today.toIso8601String().substring(0, 10));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // ─── Chapter mastery ────────────────────────────────────────────────────

  /// Mastery for a chapter (0.0–1.0). Returns 0.0 if none saved.
  static Future<double> getMasteryForChapter(String chapterId) async {
    final prefs = await _instance;
    return prefs.getDouble(LocalStorageKeys.chapterMastery(chapterId)) ?? 0.0;
  }

  /// Save chapter mastery (0.0–1.0). Clamped to [0, 1].
  static Future<void> saveMasteryForChapter(String chapterId, double percentage) async {
    final prefs = await _instance;
    await prefs.setDouble(
      LocalStorageKeys.chapterMastery(chapterId),
      percentage.clamp(0.0, 1.0),
    );
  }

  /// Overall mastery as average of all stored chapter masteries (0.0–1.0).
  static Future<double> getOverallMastery() async {
    final prefs = await _instance;
    final keys = prefs.getKeys();
    final prefix = 'chapter_';
    const suffix = '_mastery';
    double sum = 0;
    int count = 0;
    for (final key in keys) {
      if (key.startsWith(prefix) && key.endsWith(suffix)) {
        final v = prefs.getDouble(key);
        if (v != null) {
          sum += v;
          count++;
        }
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  // ─── Audio position (for resume + chapter card progress) ─────────────────

  /// Saved audio position in milliseconds. Null if none.
  static Future<int?> getAudioPosition(String chapterId) async {
    final prefs = await _instance;
    return prefs.getInt(LocalStorageKeys.audioPosition(chapterId));
  }

  /// Save audio position (ms). Call on pause/dispose.
  static Future<void> saveAudioPosition(String chapterId, int positionMs) async {
    final prefs = await _instance;
    await prefs.setInt(LocalStorageKeys.audioPosition(chapterId), positionMs);
  }

  /// Saved audio duration in milliseconds. Null if unknown.
  static Future<int?> getAudioDuration(String chapterId) async {
    final prefs = await _instance;
    return prefs.getInt(LocalStorageKeys.audioDuration(chapterId));
  }

  /// Save audio duration (ms) when known.
  static Future<void> saveAudioDuration(String chapterId, int durationMs) async {
    final prefs = await _instance;
    await prefs.setInt(LocalStorageKeys.audioDuration(chapterId), durationMs);
  }

  /// Progress 0.0–1.0 for audio card if both position and duration saved.
  static Future<double> getAudioProgress(String chapterId) async {
    final pos = await getAudioPosition(chapterId);
    final dur = await getAudioDuration(chapterId);
    if (pos == null || dur == null || dur <= 0) return 0.0;
    return (pos / dur).clamp(0.0, 1.0);
  }

}


import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _activeKey = 'app_session_active';
  static const String _backgroundKey = 'app_session_background_at';

  static const Duration sessionDuration =
      Duration(minutes: 15);

  // Start a new session after successful login.
  static Future<void> startSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_activeKey, true);
    await prefs.remove(_backgroundKey);
  }

  // Save the time when the app goes into background.
  static Future<void> markBackgrounded() async {
    final prefs = await SharedPreferences.getInstance();

    final isActive = prefs.getBool(_activeKey) ?? false;

    if (!isActive) return;

    // Do not reset the countdown on repeated lifecycle events.
    if (prefs.getInt(_backgroundKey) != null) return;

    await prefs.setInt(
      _backgroundKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Check whether the previous session is still valid.
  static Future<bool> validateAndResume() async {
    final prefs = await SharedPreferences.getInstance();

    final isActive = prefs.getBool(_activeKey) ?? false;

    if (!isActive) return false;

    final backgroundTime = prefs.getInt(_backgroundKey);

    // No background timestamp means the session was active.
    if (backgroundTime == null) return true;

    final currentTime = DateTime.now().millisecondsSinceEpoch;

    final elapsed = currentTime - backgroundTime;

    if (elapsed < 0 ||
        elapsed >= sessionDuration.inMilliseconds) {
      await clearSession();
      return false;
    }

    // Resume the session and reset the background timer.
    await prefs.remove(_backgroundKey);

    return true;
  }

  // Clear everything on manual logout or expiration.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_activeKey);
    await prefs.remove(_backgroundKey);
  }
}

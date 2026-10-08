import 'package:shared_preferences/shared_preferences.dart';

/// حفظ واستعادة جلسة المستخدم (ولي أمر / طفل)
class SessionService {
  static const _keyUserId = 'session_user_id';
  static const _keyRole = 'session_role';
  static const _keyParentId = 'session_parent_id';
  static const _keyDisplayName = 'session_display_name';

  static Future<void> saveSession(
    int userId, {
    String role = 'parent',
    int? parentId,
    String? displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyRole, role);
    if (parentId != null) {
      await prefs.setInt(_keyParentId, parentId);
    } else {
      await prefs.remove(_keyParentId);
    }
    if (displayName != null && displayName.isNotEmpty) {
      await prefs.setString(_keyDisplayName, displayName);
    } else {
      await prefs.remove(_keyDisplayName);
    }
  }

  static Future<int?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole) ?? 'parent';
  }

  static Future<int?> getParentId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyParentId)) return null;
    return prefs.getInt(_keyParentId);
  }

  static Future<String?> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDisplayName);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyParentId);
    await prefs.remove(_keyDisplayName);
  }
}

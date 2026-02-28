import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordService {
  static const _doubleHashKey = 'password_double_hash';

  /// Computes SHA-256 hash of a string and returns hex digest.
  static String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Returns hash(password) — NOT stored, used later for encryption.
  static String hashPassword(String password) {
    return _sha256(password);
  }

  /// Returns hash(hash(password)) — this is what gets stored.
  static String doubleHashPassword(String password) {
    return _sha256(_sha256(password));
  }

  /// Checks if a password has been set (i.e. double hash exists in prefs).
  static Future<bool> isPasswordSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_doubleHashKey) &&
        (prefs.getString(_doubleHashKey)?.isNotEmpty ?? false);
  }

  /// Saves hash(hash(password)) to SharedPreferences.
  static Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_doubleHashKey, doubleHashPassword(password));
  }

  /// Verifies a password by comparing hash(hash(input)) to stored value.
  static Future<bool> verifyPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_doubleHashKey);
    if (stored == null || stored.isEmpty) return false;
    return doubleHashPassword(password) == stored;
  }

  /// Removes the stored password (used during app reset before setting new one).
  static Future<void> clearPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_doubleHashKey);
  }
}

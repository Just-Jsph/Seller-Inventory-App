import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Secure password hashing helper
class PasswordHasher {
  // Application-wide cryptographic salt prefix
  static const String _salt = 'small_biz_mgr_secure_salt_2026';

  /// Hash a plaintext password using SHA-256 with salt
  static String hashPassword(String password) {
    final bytes = utf8.encode('$_salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify whether a plaintext password matches the stored hash
  static bool verifyPassword(String password, String storedHash) {
    final hash = hashPassword(password);
    return hash == storedHash;
  }
}

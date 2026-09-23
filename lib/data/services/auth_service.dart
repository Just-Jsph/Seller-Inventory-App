import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/password_hasher.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  static const String _sessionUserIdKey = 'active_session_user_id';
  final UserRepository _userRepo;

  AuthService({UserRepository? userRepo}) : _userRepo = userRepo ?? UserRepository();

  /// Register a new user
  Future<UserModel> register({
    required String name,
    required String usernameOrEmail,
    required String password,
  }) async {
    final cleanUsername = usernameOrEmail.trim().toLowerCase();

    // Check for duplicate username or email
    final existingUser = await _userRepo.getByUsername(cleanUsername);
    if (existingUser != null) {
      throw AuthException('This username or email is already registered. Please log in.');
    }

    // Hash password with cryptographic salt
    final passwordHash = PasswordHasher.hashPassword(password);

    final newUser = UserModel(
      name: name.trim(),
      username: cleanUsername,
      passwordHash: passwordHash,
    );

    final userId = await _userRepo.insert(newUser);
    final registeredUser = newUser.copyWith(id: userId);

    // Save persistent local session
    await _saveSession(userId);

    return registeredUser;
  }

  /// Login an existing user
  Future<UserModel> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final cleanUsername = usernameOrEmail.trim().toLowerCase();

    final user = await _userRepo.getByUsername(cleanUsername);
    if (user == null) {
      throw AuthException('No account found with this username or email.');
    }

    final isValid = PasswordHasher.verifyPassword(password, user.passwordHash);
    if (!isValid) {
      throw AuthException('Incorrect password. Please try again.');
    }

    // Save persistent local session
    if (user.id != null) {
      await _saveSession(user.id!);
    }

    return user;
  }

  /// Check and restore active user session on app launch
  Future<UserModel?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_sessionUserIdKey);

    if (userId == null) {
      return null;
    }

    final user = await _userRepo.getById(userId);
    if (user == null) {
      // User may have been removed, clear stale session
      await prefs.remove(_sessionUserIdKey);
      return null;
    }

    return user;
  }

  /// Log out the user by clearing the session without touching business data
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserIdKey);
  }

  Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionUserIdKey, userId);
  }
}

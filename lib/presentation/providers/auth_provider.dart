import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  static AuthProvider? _instance;
  final AuthService _authService;

  UserModel? _currentUser;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _errorMessage;

  AuthProvider({AuthService? authService}) : _authService = authService ?? AuthService() {
    _instance = this;
  }

  UserModel? get currentUser => _currentUser;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get isLoading => _status == AuthStatus.loading;
  String? get errorMessage => _errorMessage;

  /// Check for existing local session when the app launches
  Future<void> checkSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final user = await _authService.getActiveSession();
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
      } else {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
      }
    } catch (e) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Register a new user
  Future<bool> register({
    required String name,
    required String usernameOrEmail,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        name: name,
        usernameOrEmail: usernameOrEmail,
        password: password,
      );
      _currentUser = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Registration failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Log in with existing credentials
  Future<bool> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );
      _currentUser = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Login failed. Please check your credentials.';
      notifyListeners();
      return false;
    }
  }

  /// Log out and clear current user session
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _authService.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear any transient error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  static int ofCurrentUserId() => _instance?._currentUser?.id ?? 0;
}


/// Form validation helper functions
class Validators {
  /// Validate required full name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    return null;
  }

  /// Validate username or email
  static String? validateUsernameOrEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username or email';
    }
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(trimmed)) {
        return 'Please enter a valid email address';
      }
    } else {
      if (trimmed.length < 3) {
        return 'Username must be at least 3 characters long';
      }
      final usernameRegex = RegExp(r'^[a-zA-Z0-9._-]+$');
      if (!usernameRegex.hasMatch(trimmed)) {
        return 'Username can only contain letters, numbers, dots, and underscores';
      }
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}

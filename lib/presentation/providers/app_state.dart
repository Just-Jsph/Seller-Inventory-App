import 'package:flutter/foundation.dart';

/// App state management foundation placeholder
class AppState extends ChangeNotifier {
  bool _isInitialized = true;
  bool get isInitialized => _isInitialized;

  void setInitialized(bool value) {
    _isInitialized = value;
    notifyListeners();
  }
}

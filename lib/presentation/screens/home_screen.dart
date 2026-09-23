import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';

/// Legacy alias for MainNavigationScreen.
/// Directs users directly to the Material 3 dashboard and navigation hub.
class HomeScreen extends StatelessWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return MainNavigationScreen(initialIndex: initialIndex);
  }
}

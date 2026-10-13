import 'package:flutter/material.dart';
import '../../features/welcome/presentation/screens/welcome_screen.dart';

/// Centralized route definitions for navigation across the exam portal.
abstract class AppRoutes {
  static const String welcome = '/';

  // Future Milestone Routes
  static const String login = '/login';
  static const String candidateDashboard = '/dashboard';
  static const String examSession = '/exam-session';
  static const String examResults = '/results';

  /// Generates the base application route table
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      welcome: (context) => const WelcomeScreen(),
    };
  }
}

import 'package:flutter/material.dart';
import '../../features/onboarding/models/candidate_details.dart';
import '../../features/onboarding/presentation/screens/candidate_details_screen.dart';
import '../../features/onboarding/presentation/screens/exam_instructions_screen.dart';
import '../../features/welcome/presentation/screens/welcome_screen.dart';

/// Centralized route definitions for navigation across the exam portal.
abstract class AppRoutes {
  static const String welcome = '/';
  static const String candidateDetails = '/candidate-details';
  static const String instructions = '/instructions';

  // Future Milestone Routes
  static const String login = '/login';
  static const String candidateDashboard = '/dashboard';
  static const String examSession = '/exam-session';
  static const String examResults = '/results';

  /// Generates the base application route table
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      welcome: (context) => const WelcomeScreen(),
      candidateDetails: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as CandidateDetails?;
        return CandidateDetailsScreen(initialDetails: args);
      },
      instructions: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as CandidateDetails?;
        return ExamInstructionsScreen(candidateDetails: args);
      },
    };
  }
}

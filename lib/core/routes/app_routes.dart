import 'package:flutter/material.dart';
import '../../features/exam/domain/models/exam_result.dart';
import '../../features/exam/presentation/screens/exam_results_screen.dart';
import '../../features/exam/presentation/screens/exam_screen.dart';
import '../../features/onboarding/models/candidate_details.dart';
import '../../features/onboarding/presentation/screens/candidate_details_screen.dart';
import '../../features/onboarding/presentation/screens/exam_instructions_screen.dart';
import '../../features/welcome/presentation/screens/welcome_screen.dart';

/// Centralized route definitions for navigation across the exam portal.
abstract class AppRoutes {
  static const String welcome = '/';
  static const String candidateDetails = '/candidate-details';
  static const String instructions = '/instructions';
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
      examSession: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as CandidateDetails? ??
            const CandidateDetails(
              studentName: 'Candidate',
              registerNumber: 'REG-2026',
              examinationName: 'Standard Examination',
            );
        return ExamScreen(candidateDetails: args);
      },
      examResults: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as ExamResult?;
        if (args == null) {
          // Fallback if accessed unexpectedly
          return const Scaffold(
            body: Center(child: Text('No examination result found.')),
          );
        }
        return ExamResultsScreen(result: args);
      },
    };
  }
}

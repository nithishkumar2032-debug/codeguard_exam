/// Application-wide string constants.
///
/// Centralizing user-facing text ensures consistent terminology across
/// screens and simplifies future internationalization (l10n).
abstract class AppStrings {
  // Brand & Identity
  static const String appName = 'CodeGuard Exam';
  static const String appTagline = 'Secure, Reliable Online Examination Portal';
  static const String appDescription =
      'A modern, high-integrity assessment platform engineered for students and educators. '
      'Built with Flutter Web to deliver a responsive, proctor-ready testing experience across all devices.';

  // Actions
  static const String getStarted = 'Get Started';
  static const String exploreGuidelines = 'Exam Instructions';
  static const String systemStatusReady = 'System Status: Ready';
  static const String proceedToInstructions = 'Proceed to Instructions';
  static const String startExamination = 'Start Examination';
  static const String back = 'Back';

  // Feature Highlights
  static const String featureSecurityTitle = 'Integrity & Security';
  static const String featureSecurityDesc =
      'Proctor-ready environment designed to prevent unauthorized navigation and screen changes.';

  static const String featureResilienceTitle = 'Offline Resilience';
  static const String featureResilienceDesc =
      'Local state persistence ensures answers remain safe during network interruptions.';

  static const String featureAnalyticsTitle = 'Instant Insights';
  static const String featureAnalyticsDesc =
      'Automated scoring pipelines and comprehensive performance breakdown for test takers.';

  // Candidate Onboarding
  static const String onboardingTitle = 'Candidate Details';
  static const String onboardingSubtitle =
      'Enter your test-taker information to initialize your examination session.';
  static const String studentNameLabel = 'Full Name';
  static const String studentNameHint = 'e.g. Alex Morgan';
  static const String registerNumberLabel = 'Register Number / Student ID';
  static const String registerNumberHint = 'e.g. CS-2026-8941';
  static const String examNameLabel = 'Examination Name';
  static const String examNameHint = 'e.g. CS301 - Data Structures & Algorithms Final';
  static const String candidateDisclaimer =
      'Candidate session details are collected for this assessment attempt. '
      'Institutional single sign-on and backend identity verification will be introduced in a future milestone.';

  // Validation Messages
  static const String errorNameRequired = 'Student full name is required.';
  static const String errorNameTooShort = 'Student name must be at least 2 characters.';
  static const String errorRegisterRequired = 'Register number is required.';
  static const String errorRegisterTooShort = 'Register number must be at least 3 characters.';
  static const String errorExamNameRequired = 'Examination name is required.';

  // Examination Instructions
  static const String instructionsTitle = 'Examination Instructions';
  static const String instructionsSubtitle =
      'Read all guidelines carefully before beginning. The examination countdown will NOT start until you click "Start Examination".';

  static const String ruleDurationTitle = '30-Minute Duration';
  static const String ruleDurationDesc =
      'The assessment is strictly timed for 30 minutes. An active countdown timer will display at the top of your test screen once launched.';

  static const String ruleFormatTitle = '10 MCQs & 2 Coding Challenges';
  static const String ruleFormatDesc =
      'Questions consist of 10 multiple-choice conceptual questions and 2 hands-on coding problems with built-in test runners.';

  static const String ruleSavingTitle = 'Continuous Auto-Saving';
  static const String ruleSavingDesc =
      'Your answer selections and code buffers are automatically saved as you write. Network hiccups will not erase your progress.';

  static const String ruleSubmissionTitle = 'Submission Rules';
  static const String ruleSubmissionDesc =
      'You can review and submit your exam at any time before the timer runs out. If the timer reaches 00:00, your exam will auto-submit automatically.';

  static const String ruleLifecycleTitle = 'Lifecycle & Interruption Policy';
  static const String ruleLifecycleDesc =
      'CodeGuard monitors browser tab focus and full-screen state. Leaving full screen, switching browser tabs, or minimizing the window will trigger security alerts and be logged.';

  static const String declarationText =
      'I hereby declare that I will complete this examination independently without unauthorized assistance. '
      'I acknowledge that my browser focus and lifecycle events will be actively logged for proctoring compliance.';
}

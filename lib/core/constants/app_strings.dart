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
}

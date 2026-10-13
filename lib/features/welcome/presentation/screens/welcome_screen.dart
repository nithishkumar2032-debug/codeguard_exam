import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../widgets/responsive_builder.dart';
import '../widgets/exam_feature_card.dart';

/// Welcome screen for CodeGuard Exam.
///
/// Designed to adapt cleanly across mobile browsers and wide desktop monitors.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _onGetStartedPressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Welcome to CodeGuard Exam! Milestone 1 setup is active. Authentication & exam modules will be integrated in subsequent milestones.',
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showGuidelinesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF0F3E6D)),
              SizedBox(width: 8),
              Text('Candidate Guidelines'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              'CodeGuard Exam is designed to provide fair, monitored assessments:\n\n'
              '• Ensure a stable internet connection.\n'
              '• Keep your browser in full screen once an examination starts.\n'
              '• Unauthorized tab switching or multi-window actions will be logged.\n'
              '• Auto-save secures your answer choices every 15 seconds.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.security_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.appName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Chip(
              avatar: const Icon(
                Icons.fiber_manual_record,
                color: Colors.green,
                size: 14,
              ),
              label: const Text(
                'System Ready',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              backgroundColor: colorScheme.surface,
              side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, screenType) {
          final isDesktop = screenType == DeviceScreenType.desktop;
          final isTablet = screenType == DeviceScreenType.tablet;
          final double horizontalPadding = isDesktop ? 64.0 : (isTablet ? 32.0 : 20.0);

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isDesktop ? 48.0 : 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Section
                      _buildHeroSection(context, isDesktop),
                      SizedBox(height: isDesktop ? 64.0 : 40.0),

                      // Features Header
                      Text(
                        'Core Architecture Highlights',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Engineered for reliability, integrity, and smooth examination workflows.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),

                      // Responsive Feature Grid
                      _buildFeatureGrid(screenType),

                      SizedBox(height: isDesktop ? 80.0 : 48.0),

                      // Footer
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      Text(
                        'CodeGuard Exam • Milestone 1: Clean Architecture & Responsive Foundation',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.4),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'MILIESTONE 1: PROJECT SETUP ACTIVE',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.appName,
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.appTagline,
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              AppStrings.appDescription,
              textAlign: isDesktop ? TextAlign.left : TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          Wrap(
            alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                key: const Key('get_started_button'),
                onPressed: () => _onGetStartedPressed(context),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(AppStrings.getStarted),
              ),
              OutlinedButton.icon(
                onPressed: () => _showGuidelinesDialog(context),
                icon: const Icon(Icons.description_outlined),
                label: const Text(AppStrings.exploreGuidelines),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(DeviceScreenType screenType) {
    const features = [
      (
        icon: Icons.shield_outlined,
        title: AppStrings.featureSecurityTitle,
        desc: AppStrings.featureSecurityDesc,
      ),
      (
        icon: Icons.cloud_sync_outlined,
        title: AppStrings.featureResilienceTitle,
        desc: AppStrings.featureResilienceDesc,
      ),
      (
        icon: Icons.analytics_outlined,
        title: AppStrings.featureAnalyticsTitle,
        desc: AppStrings.featureAnalyticsDesc,
      ),
    ];

    if (screenType == DeviceScreenType.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: features
            .map(
              (f) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ExamFeatureCard(
                    icon: f.icon,
                    title: f.title,
                    description: f.desc,
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    // Tablet & Mobile: Vertical list
    return Column(
      children: features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ExamFeatureCard(
                icon: f.icon,
                title: f.title,
                description: f.desc,
              ),
            ),
          )
          .toList(),
    );
  }
}

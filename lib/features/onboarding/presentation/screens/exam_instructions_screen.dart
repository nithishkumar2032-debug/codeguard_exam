import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../widgets/responsive_builder.dart';
import '../../models/candidate_details.dart';

/// Examination Instructions screen detailing rules, interruption policy, and declaration.
class ExamInstructionsScreen extends StatefulWidget {
  final CandidateDetails? candidateDetails;

  const ExamInstructionsScreen({super.key, this.candidateDetails});

  @override
  State<ExamInstructionsScreen> createState() => _ExamInstructionsScreenState();
}

class _ExamInstructionsScreenState extends State<ExamInstructionsScreen> {
  bool _isDeclarationAccepted = false;

  void _onStartExamPressed(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          icon: const Icon(Icons.rocket_launch_outlined, size: 36, color: Color(0xFF0F3E6D)),
          title: const Text('Onboarding Complete!'),
          content: Text(
            'Candidate: ${widget.candidateDetails?.studentName ?? "Alex Morgan"}\n'
            'Register No: ${widget.candidateDetails?.registerNumber ?? "CS-2026-8941"}\n'
            'Exam: ${widget.candidateDetails?.examinationName ?? "CS301 Final"}\n\n'
            'Milestone 2 (Onboarding & Instructions) successfully verified. '
            'The active examination session & live timer will be initialized in Milestone 3.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood'),
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
    final details = widget.candidateDetails;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.instructionsTitle),
        leading: IconButton(
          key: const Key('instructions_back_button'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Candidate Details',
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ResponsiveBuilder(
        builder: (context, screenType) {
          final isDesktop = screenType == DeviceScreenType.desktop;
          final double horizontalPadding = isDesktop ? 48.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 32.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Candidate Summary Header Card
                    if (details != null) ...[
                      Card(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    child: Text(
                                      details.studentName.isNotEmpty
                                          ? details.studentName[0].toUpperCase()
                                          : 'C',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        details.studentName,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Reg: ${details.registerNumber}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Chip(
                                avatar: const Icon(Icons.school_outlined, size: 16),
                                label: Text(
                                  details.examinationName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Instructions Card
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 36.0 : 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.instructionsTitle,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.instructionsSubtitle,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),

                            // Guidelines List
                            _buildInstructionTile(
                              context,
                              icon: Icons.timer_outlined,
                              title: AppStrings.ruleDurationTitle,
                              description: AppStrings.ruleDurationDesc,
                            ),
                            _buildInstructionTile(
                              context,
                              icon: Icons.format_list_numbered,
                              title: AppStrings.ruleFormatTitle,
                              description: AppStrings.ruleFormatDesc,
                            ),
                            _buildInstructionTile(
                              context,
                              icon: Icons.cloud_done_outlined,
                              title: AppStrings.ruleSavingTitle,
                              description: AppStrings.ruleSavingDesc,
                            ),
                            _buildInstructionTile(
                              context,
                              icon: Icons.send_outlined,
                              title: AppStrings.ruleSubmissionTitle,
                              description: AppStrings.ruleSubmissionDesc,
                            ),
                            _buildInstructionTile(
                              context,
                              icon: Icons.security_update_warning_outlined,
                              title: AppStrings.ruleLifecycleTitle,
                              description: AppStrings.ruleLifecycleDesc,
                              isWarning: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Declaration Card
                    Card(
                      color: _isDeclarationAccepted
                          ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: CheckboxListTile(
                          key: const Key('declaration_checkbox'),
                          value: _isDeclarationAccepted,
                          onChanged: (bool? value) {
                            setState(() {
                              _isDeclarationAccepted = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            AppStrings.declarationText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Button (Enabled only if declaration is accepted)
                    ElevatedButton.icon(
                      key: const Key('start_examination_button'),
                      onPressed: _isDeclarationAccepted
                          ? () => _onStartExamPressed(context)
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(AppStrings.startExamination),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = isWarning ? Colors.amber.shade800 : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isWarning
                  ? Colors.amber.shade50
                  : colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

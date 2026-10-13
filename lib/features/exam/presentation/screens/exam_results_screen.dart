import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../widgets/responsive_builder.dart';
import '../../domain/models/exam_result.dart';

/// Screen presenting candidate exam completion metrics and score summary.
class ExamResultsScreen extends StatelessWidget {
  final ExamResult result;

  const ExamResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Examination Submission Summary'),
        automaticallyImplyLeading: false,
      ),
      body: ResponsiveBuilder(
        builder: (context, screenType) {
          final isDesktop = screenType == DeviceScreenType.desktop;
          final double horizontalPadding = isDesktop ? 64.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 36.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Completion Hero Card
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 36.0 : 24.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.shade100,
                              ),
                              child: Icon(
                                Icons.task_alt_rounded,
                                size: 48,
                                color: Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Examination Completed',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Submission Reason: ${result.submissionReason}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Candidate Metadata Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Wrap(
                                spacing: 20,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  Text(
                                    'Candidate: ${result.candidateDetails.studentName}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Register: ${result.candidateDetails.registerNumber}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Exam: ${result.candidateDetails.examinationName}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Metrics Grid
                    Row(
                      children: [
                        // MCQ Score Card
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'MCQ Score',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          '${result.mcqPercentage.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${result.mcqScore} / ${result.maxMcqScore}',
                                    key: const Key('mcq_score_text'),
                                    style: theme.textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Questions Answered: ${result.answeredCount} / ${result.maxMcqScore}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Coding Challenges Card
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Coding Challenges',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          '${result.codingAttemptedCount}/${result.codingChallengesCount}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Pending Review',
                                    key: const Key('coding_status_text'),
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    result.codingEvaluationStatus,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Official Disclaimer Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade900,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prototype Assessment Notice',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Scores calculated here represent client-side preliminary results for MCQs. '
                                  'Official examination transcripts and coding grades are authoritative only after '
                                  'formal server-side sandbox evaluation and proctoring review.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber.shade900,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Return Home Action
                    ElevatedButton.icon(
                      key: const Key('results_return_home_button'),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.welcome,
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Return to Home Screen'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
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
}

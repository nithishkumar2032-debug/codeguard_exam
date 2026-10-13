import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../widgets/responsive_builder.dart';
import '../../../onboarding/models/candidate_details.dart';
import '../controllers/exam_controller.dart';
import '../widgets/coding_challenge_view.dart';
import '../widgets/exam_timer_display.dart';
import '../widgets/mcq_view.dart';
import '../widgets/question_palette.dart';

/// Main examination screen hosting the active countdown timer,
/// question views, and palette navigation.
class ExamScreen extends StatefulWidget {
  final CandidateDetails candidateDetails;
  final ExamController? controller; // Injectable for unit/widget testing

  const ExamScreen({
    super.key,
    required this.candidateDetails,
    this.controller,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  late final ExamController _controller;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        ExamController(candidateDetails: widget.candidateDetails);

    _controller.addListener(_handleControllerUpdate);

    // Attempt restoring any draft answers saved in local storage
    _controller.restoreSessionIfAvailable();

    // Start 30-minute countdown now that candidate has arrived at exam screen
    _controller.startTimer();
  }

  void _handleControllerUpdate() {
    if (!mounted || _isDisposed) return;

    if (_controller.isSubmitted && _controller.examResult != null) {
      // Navigate to results screen upon manual or timeout submission
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.examResults,
            arguments: _controller.examResult,
          );
        }
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.removeListener(_handleControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _showSubmitConfirmationDialog() {
    final answered = _controller.answeredCount;
    final total = _controller.totalQuestionsCount;
    final unanswered = total - answered;
    final marked = _controller.markedForReviewCount;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          icon: const Icon(Icons.help_outline_rounded, size: 36, color: Color(0xFF0F3E6D)),
          title: const Text('Submit Examination?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please review your progress before final submission:'),
              const SizedBox(height: 16),
              _buildProgressRow('Total Questions:', '$total'),
              _buildProgressRow('Answered:', '$answered', color: Colors.green.shade700),
              _buildProgressRow('Unanswered:', '$unanswered', color: Colors.red.shade700),
              _buildProgressRow('Marked for Review:', '$marked', color: Colors.amber.shade800),
              const SizedBox(height: 16),
              const Text(
                'Once submitted, your answers cannot be altered. Are you sure you wish to finish?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Return to Exam'),
            ),
            ElevatedButton(
              key: const Key('confirm_submit_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _controller.submitExam(reason: 'Manual submission by candidate');
              },
              child: const Text('Confirm & Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final candidate = widget.candidateDetails;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shield_rounded, size: 20, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.examinationName,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${candidate.studentName} (${candidate.registerNumber})',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ExamTimerDisplay(
              key: const Key('exam_timer_display'),
              remainingSeconds: _controller.remainingSeconds,
              formattedTime: _controller.formattedRemainingTime,
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              key: const Key('exam_submit_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: _showSubmitConfirmationDialog,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Submit Exam'),
            ),
          ),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, screenType) {
          final isDesktop = screenType == DeviceScreenType.desktop;

          return Column(
            children: [
              Expanded(
                child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
              ),

              // Bottom Navigation Bar
              _buildBottomNavigationBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Content (75%)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: _buildCurrentQuestionView(),
            ),
          ),
          const SizedBox(width: 20),

          // Palette Panel (25%)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: SingleChildScrollView(
              child: QuestionPalette(
                totalQuestions: _controller.totalQuestionsCount,
                mcqCount: _controller.mcqs.length,
                currentIndex: _controller.currentIndex,
                getStatus: _controller.getQuestionStatus,
                onQuestionSelected: _controller.goToQuestion,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildCurrentQuestionView(),
          const SizedBox(height: 20),
          QuestionPalette(
            totalQuestions: _controller.totalQuestionsCount,
            mcqCount: _controller.mcqs.length,
            currentIndex: _controller.currentIndex,
            getStatus: _controller.getQuestionStatus,
            onQuestionSelected: _controller.goToQuestion,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentQuestionView() {
    if (_controller.isCurrentMcq) {
      final mcq = _controller.currentMcq!;
      return McqView(
        key: ValueKey(mcq.id),
        question: mcq,
        selectedOptionIndex: _controller.mcqAnswers[mcq.id],
        isMarkedForReview: _controller.reviewFlags.contains(mcq.id),
        onOptionSelected: (index) => _controller.selectMcqOption(mcq.id, index),
        onToggleReview: () => _controller.toggleReviewFlag(mcq.id),
      );
    } else {
      final challenge = _controller.currentCodingChallenge!;
      final currentCode = _controller.codingDrafts[challenge.id] ?? challenge.starterCode;

      return CodingChallengeView(
        key: ValueKey(challenge.id),
        challenge: challenge,
        currentCode: currentCode,
        isMarkedForReview: _controller.reviewFlags.contains(challenge.id),
        codeExecutionService: _controller.codeExecutionService,
        onCodeChanged: (newCode) => _controller.updateCodingDraft(challenge.id, newCode),
        onToggleReview: () => _controller.toggleReviewFlag(challenge.id),
      );
    }
  }

  Widget _buildBottomNavigationBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final index = _controller.currentIndex;
    final total = _controller.totalQuestionsCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            key: const Key('exam_prev_button'),
            onPressed: index > 0 ? _controller.previousQuestion : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
          ),
          Text(
            'Question ${index + 1} of $total',
            key: const Key('question_index_indicator'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          ElevatedButton.icon(
            key: const Key('exam_next_button'),
            onPressed: index < total - 1 ? _controller.nextQuestion : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

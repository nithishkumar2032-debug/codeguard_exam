import 'package:flutter/material.dart';
import '../../domain/models/coding_challenge.dart';
import '../../domain/services/code_execution_service.dart';

/// Presentation view for a JavaScript Coding Challenge with safe test execution.
class CodingChallengeView extends StatefulWidget {
  final CodingChallenge challenge;
  final String currentCode;
  final bool isMarkedForReview;
  final CodeExecutionService codeExecutionService;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onToggleReview;

  const CodingChallengeView({
    super.key,
    required this.challenge,
    required this.currentCode,
    required this.isMarkedForReview,
    required this.codeExecutionService,
    required this.onCodeChanged,
    required this.onToggleReview,
  });

  @override
  State<CodingChallengeView> createState() => _CodingChallengeViewState();
}

class _CodingChallengeViewState extends State<CodingChallengeView> {
  late final TextEditingController _codeController;
  CodeExecutionResult? _executionResult;
  bool _isRunningTests = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.currentCode);
  }

  @override
  void didUpdateWidget(covariant CodingChallengeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.id != widget.challenge.id) {
      _codeController.text = widget.currentCode;
      _executionResult = null;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleRunTests() async {
    setState(() {
      _isRunningTests = true;
    });

    final result = await widget.codeExecutionService.executeTests(
      challenge: widget.challenge,
      code: _codeController.text,
    );

    if (mounted) {
      setState(() {
        _executionResult = result;
        _isRunningTests = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final challenge = widget.challenge;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Coding Challenge ${challenge.number} of 2 • ${challenge.language}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: Key('review_toggle_${challenge.id}'),
                  onPressed: widget.onToggleReview,
                  icon: Icon(
                    widget.isMarkedForReview
                        ? Icons.bookmark_added_rounded
                        : Icons.bookmark_add_outlined,
                    color: widget.isMarkedForReview ? Colors.amber.shade800 : null,
                  ),
                  label: Text(
                    widget.isMarkedForReview ? 'Marked for Review' : 'Mark for Review',
                    style: TextStyle(
                      color: widget.isMarkedForReview ? Colors.amber.shade800 : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title & Description
            Text(
              challenge.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),

            // Sample Input & Output
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sample Input:', style: theme.textTheme.labelSmall),
                        const SizedBox(height: 4),
                        Text(
                          challenge.sampleInput,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sample Output:', style: theme.textTheme.labelSmall),
                        const SizedBox(height: 4),
                        Text(
                          challenge.sampleOutput,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Code Editor Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Code Editor (${challenge.language})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ElevatedButton.icon(
                  key: Key('run_tests_button_${challenge.id}'),
                  onPressed: _isRunningTests ? null : _handleRunTests,
                  icon: _isRunningTests
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(_isRunningTests ? 'Evaluating...' : 'Run Tests'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Code Editor Field
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Dark slate editor background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: TextFormField(
                key: Key('code_editor_${challenge.id}'),
                controller: _codeController,
                maxLines: 12,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFFF8FAFC),
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
                onChanged: widget.onCodeChanged,
              ),
            ),
            const SizedBox(height: 16),

            // Security Notice Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Safe Sandbox Interface: Code execution is evaluated with static validation in this milestone. '
                      'Production deployments will link to an isolated server-side Docker sandbox.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Test Results Section
            if (_executionResult != null) ...[
              Text(
                'Test Results',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _executionResult!.allPassed
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _executionResult!.allPassed
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _executionResult!.allPassed
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          color: _executionResult!.allPassed
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _executionResult!.summary,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _executionResult!.allPassed
                                  ? Colors.green.shade900
                                  : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._executionResult!.testCaseResults.asMap().entries.map((entry) {
                      final i = entry.key;
                      final tc = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          'Test ${i + 1}: input(${tc.input}) ➔ expected: ${tc.expectedOutput} | actual: ${tc.actualOutput} (${tc.passed ? "PASS" : "FAIL"})',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

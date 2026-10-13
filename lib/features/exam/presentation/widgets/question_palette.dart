import 'package:flutter/material.dart';
import '../../domain/models/question_status.dart';

/// Interactive palette enabling quick navigation across questions and status inspection.
class QuestionPalette extends StatelessWidget {
  final int totalQuestions;
  final int mcqCount;
  final int currentIndex;
  final QuestionStatus Function(int index) getStatus;
  final ValueChanged<int> onQuestionSelected;

  const QuestionPalette({
    super.key,
    required this.totalQuestions,
    required this.mcqCount,
    required this.currentIndex,
    required this.getStatus,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.grid_view_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Question Palette',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // MCQ Section
            Text(
              'Multiple Choice (1 - $mcqCount)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(mcqCount, (index) {
                return _buildPaletteButton(context, index, '${index + 1}');
              }),
            ),
            const SizedBox(height: 16),

            // Coding Section
            Text(
              'Coding Challenges (C1 - C${totalQuestions - mcqCount})',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(totalQuestions - mcqCount, (offset) {
                final index = mcqCount + offset;
                return _buildPaletteButton(context, index, 'C${offset + 1}');
              }),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Status Legend
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteButton(BuildContext context, int index, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = getStatus(index);
    final isCurrent = index == currentIndex;

    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (status) {
      case QuestionStatus.answered:
        bg = Colors.green.shade600;
        fg = Colors.white;
        break;
      case QuestionStatus.answeredAndMarkedForReview:
        bg = Colors.purple.shade600;
        fg = Colors.white;
        break;
      case QuestionStatus.markedForReview:
        bg = Colors.amber.shade700;
        fg = Colors.white;
        break;
      case QuestionStatus.unanswered:
        bg = colorScheme.surfaceContainerHighest;
        fg = colorScheme.onSurface;
        break;
    }

    if (isCurrent) {
      borderSide = BorderSide(
        color: colorScheme.primary,
        width: 2.5,
      );
    }

    return InkWell(
      key: Key('palette_item_$index'),
      onTap: () => onQuestionSelected(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildLegendItem(
          color: Colors.green.shade600,
          label: 'Answered',
          theme: theme,
        ),
        const SizedBox(height: 4),
        _buildLegendItem(
          color: theme.colorScheme.surfaceContainerHighest,
          label: 'Unanswered',
          theme: theme,
        ),
        const SizedBox(height: 4),
        _buildLegendItem(
          color: Colors.amber.shade700,
          label: 'Marked for Review',
          theme: theme,
        ),
        const SizedBox(height: 4),
        _buildLegendItem(
          color: Colors.purple.shade600,
          label: 'Answered & Review',
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black12, width: 0.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }
}

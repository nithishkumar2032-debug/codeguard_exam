import 'package:flutter/material.dart';
import '../../domain/models/mcq_question.dart';

/// Presentation view for a single Multiple Choice Question.
class McqView extends StatelessWidget {
  final McqQuestion question;
  final int? selectedOptionIndex;
  final bool isMarkedForReview;
  final ValueChanged<int> onOptionSelected;
  final VoidCallback onToggleReview;

  const McqView({
    super.key,
    required this.question,
    required this.selectedOptionIndex,
    required this.isMarkedForReview,
    required this.onOptionSelected,
    required this.onToggleReview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Question Index and Review Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Question ${question.number} of 10 • Multiple Choice',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: Key('review_toggle_${question.id}'),
                  onPressed: onToggleReview,
                  icon: Icon(
                    isMarkedForReview
                        ? Icons.bookmark_added_rounded
                        : Icons.bookmark_add_outlined,
                    color: isMarkedForReview ? Colors.amber.shade800 : null,
                  ),
                  label: Text(
                    isMarkedForReview ? 'Marked for Review' : 'Mark for Review',
                    style: TextStyle(
                      color: isMarkedForReview ? Colors.amber.shade800 : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question Text
            Text(
              question.text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Option Choices
            ...List.generate(question.options.length, (index) {
              final isSelected = selectedOptionIndex == index;
              final optionLetter = String.fromCharCode(65 + index); // A, B, C, D

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  key: Key('option_${question.id}_$index'),
                  onTap: () => onOptionSelected(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.7),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            optionLetter,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            question.options[index],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

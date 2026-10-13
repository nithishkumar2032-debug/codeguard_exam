import 'package:flutter/material.dart';

/// Real-time examination timer display with urgency color changes.
class ExamTimerDisplay extends StatelessWidget {
  final int remainingSeconds;
  final String formattedTime;

  const ExamTimerDisplay({
    super.key,
    required this.remainingSeconds,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowTime = remainingSeconds <= 300; // Less than 5 minutes
    final isCriticalTime = remainingSeconds <= 60; // Less than 1 minute

    final Color badgeColor = isCriticalTime
        ? Colors.red.shade700
        : (isLowTime ? Colors.amber.shade800 : theme.colorScheme.primary);

    final Color backgroundColor = isCriticalTime
        ? Colors.red.shade50
        : (isLowTime ? Colors.amber.shade50 : theme.colorScheme.primaryContainer.withValues(alpha: 0.35));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCriticalTime ? Icons.warning_amber_rounded : Icons.timer_outlined,
            size: 20,
            color: badgeColor,
          ),
          const SizedBox(width: 8),
          Text(
            formattedTime,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: badgeColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

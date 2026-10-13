import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../widgets/responsive_builder.dart';
import '../../models/candidate_details.dart';

/// Screen collecting candidate details before entering the examination instructions.
class CandidateDetailsScreen extends StatefulWidget {
  final CandidateDetails? initialDetails;

  const CandidateDetailsScreen({super.key, this.initialDetails});

  @override
  State<CandidateDetailsScreen> createState() => _CandidateDetailsScreenState();
}

class _CandidateDetailsScreenState extends State<CandidateDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _registerController;
  late final TextEditingController _examController;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialDetails?.studentName ?? '',
    );
    _registerController = TextEditingController(
      text: widget.initialDetails?.registerNumber ?? '',
    );
    _examController = TextEditingController(
      text: widget.initialDetails?.examinationName ?? 'CS301 - Data Structures & Algorithms Final',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _registerController.dispose();
    _examController.dispose();
    super.dispose();
  }

  Future<void> _onProceedPressed() async {
    if (_isAuthenticating) return;
    if (_formKey.currentState?.validate() ?? false) {
      final details = CandidateDetails(
        studentName: _nameController.text.trim(),
        registerNumber: _registerController.text.trim(),
        examinationName: _examController.text.trim(),
      );

      if (SupabaseService.instance.isInitialized) {
        setState(() => _isAuthenticating = true);
        try {
          await SupabaseService.instance.ensureAuthenticatedCandidate(
            metadata: {
              'student_name': details.studentName,
              'register_number': details.registerNumber,
              'examination_name': details.examinationName,
            },
          );
        } catch (e) {
          if (mounted) {
            setState(() => _isAuthenticating = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Authentication connection error: $e'),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _onProceedPressed,
                ),
              ),
            );
            return;
          }
        }
        if (mounted) {
          setState(() => _isAuthenticating = false);
        }
      }

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.instructions,
          arguments: details,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.onboardingTitle),
        leading: IconButton(
          key: const Key('candidate_back_button'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Welcome',
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
                constraints: const BoxConstraints(maxWidth: 640),
                child: Form(
                  key: _formKey,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(isDesktop ? 40.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Icon & Title
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.badge_outlined,
                                  color: colorScheme.onPrimaryContainer,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.onboardingTitle,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppStrings.onboardingSubtitle,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Student Name Field
                          Text(
                            AppStrings.studentNameLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('candidate_name_field'),
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: AppStrings.studentNameHint,
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return AppStrings.errorNameRequired;
                              }
                              if (trimmed.length < 2) {
                                return AppStrings.errorNameTooShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Register Number Field
                          Text(
                            AppStrings.registerNumberLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('candidate_register_field'),
                            controller: _registerController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: AppStrings.registerNumberHint,
                              prefixIcon: Icon(Icons.numbers_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return AppStrings.errorRegisterRequired;
                              }
                              if (trimmed.length < 3) {
                                return AppStrings.errorRegisterTooShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Examination Name Field
                          Text(
                            AppStrings.examNameLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('candidate_exam_field'),
                            controller: _examController,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _onProceedPressed(),
                            decoration: const InputDecoration(
                              hintText: AppStrings.examNameHint,
                              prefixIcon: Icon(Icons.assignment_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return AppStrings.errorExamNameRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Notice / Disclaimer Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppStrings.candidateDisclaimer,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit Action
                          ElevatedButton.icon(
                            key: const Key('proceed_button'),
                            onPressed: _isAuthenticating ? null : _onProceedPressed,
                            icon: _isAuthenticating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.arrow_forward),
                            label: Text(
                              _isAuthenticating
                                  ? 'Authenticating...'
                                  : AppStrings.proceedToInstructions,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

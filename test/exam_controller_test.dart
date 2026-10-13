import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:codeguard_exam/features/exam/domain/models/coding_challenge.dart';
import 'package:codeguard_exam/features/exam/domain/models/question_status.dart';
import 'package:codeguard_exam/features/exam/domain/services/exam_scoring_service.dart';
import 'package:codeguard_exam/features/exam/domain/services/exam_storage_service.dart';
import 'package:codeguard_exam/features/exam/domain/services/code_execution_service.dart';
import 'package:codeguard_exam/features/exam/presentation/controllers/exam_controller.dart';
import 'package:codeguard_exam/features/onboarding/models/candidate_details.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testCandidate = CandidateDetails(
    studentName: 'Test Student',
    registerNumber: 'REG-1234',
    examinationName: 'Unit Test Exam',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ExamController Unit Tests', () {
    test('Initial state: 30 minutes, 12 total questions, index 0', () {
      final controller = ExamController(candidateDetails: testCandidate);
      expect(controller.remainingSeconds, 1800);
      expect(controller.formattedRemainingTime, '30:00');
      expect(controller.totalQuestionsCount, 12);
      expect(controller.currentIndex, 0);
      expect(controller.isCurrentMcq, isTrue);
      expect(controller.isCurrentCoding, isFalse);
      expect(controller.isSubmitted, isFalse);
      expect(controller.answeredCount, 0);
      expect(controller.markedForReviewCount, 0);
      controller.dispose();
    });

    test('Question navigation: next, previous, and direct jump', () {
      final controller = ExamController(candidateDetails: testCandidate);

      controller.nextQuestion();
      expect(controller.currentIndex, 1);

      controller.previousQuestion();
      expect(controller.currentIndex, 0);

      // Previous at 0 stays at 0
      controller.previousQuestion();
      expect(controller.currentIndex, 0);

      // Jump to coding challenge (index 10)
      controller.goToQuestion(10);
      expect(controller.currentIndex, 10);
      expect(controller.isCurrentMcq, isFalse);
      expect(controller.isCurrentCoding, isTrue);
      expect(controller.currentCodingChallenge, isNotNull);

      // Jump beyond bounds is ignored
      controller.goToQuestion(99);
      expect(controller.currentIndex, 10);

      controller.dispose();
    });

    test('MCQ answer selection, changing answers, and review flags', () {
      final controller = ExamController(candidateDetails: testCandidate);

      expect(controller.getQuestionStatus(0), QuestionStatus.unanswered);

      // Select option 1
      controller.selectMcqOption('mcq_1', 1);
      expect(controller.mcqAnswers['mcq_1'], 1);
      expect(controller.answeredCount, 1);
      expect(controller.getQuestionStatus(0), QuestionStatus.answered);

      // Change answer to option 2
      controller.selectMcqOption('mcq_1', 2);
      expect(controller.mcqAnswers['mcq_1'], 2);
      expect(controller.getQuestionStatus(0), QuestionStatus.answered);

      // Toggle review flag
      controller.toggleReviewFlag('mcq_1');
      expect(controller.reviewFlags.contains('mcq_1'), isTrue);
      expect(controller.markedForReviewCount, 1);
      expect(
        controller.getQuestionStatus(0),
        QuestionStatus.answeredAndMarkedForReview,
      );

      // Unmark review flag
      controller.toggleReviewFlag('mcq_1');
      expect(controller.reviewFlags.contains('mcq_1'), isFalse);
      expect(controller.getQuestionStatus(0), QuestionStatus.answered);

      controller.dispose();
    });

    test('Duplicate submission prevention: subsequent calls return same result', () {
      final controller = ExamController(candidateDetails: testCandidate);

      final result1 = controller.submitExam(reason: 'First manual submission');
      expect(controller.isSubmitted, isTrue);
      expect(result1.submissionReason, 'First manual submission');

      // Attempt second submission
      final result2 = controller.submitExam(reason: 'Duplicate attempt');
      expect(identical(result1, result2), isTrue);
      expect(result2.submissionReason, 'First manual submission');

      controller.dispose();
    });

    test('Persistence: save and restore session state', () async {
      final storage = SharedPrefsExamStorageService();
      final controller = ExamController(
        candidateDetails: testCandidate,
        storageService: storage,
      );

      // Answer question 1 and mark question 2 for review
      controller.selectMcqOption('mcq_1', 1);
      controller.toggleReviewFlag('mcq_2');
      controller.updateCodingDraft('code_1', 'function isPalindrome(str) { return true; }');
      await controller.persistSession();

      // Create new controller simulating browser refresh
      final restoredController = ExamController(
        candidateDetails: testCandidate,
        storageService: storage,
      );

      await restoredController.restoreSessionIfAvailable();

      expect(restoredController.mcqAnswers['mcq_1'], 1);
      expect(restoredController.reviewFlags.contains('mcq_2'), isTrue);
      expect(
        restoredController.codingDrafts['code_1'],
        'function isPalindrome(str) { return true; }',
      );

      controller.dispose();
      restoredController.dispose();
    });

    test('Scoring service: calculates correct MCQ score and marks coding pending', () {
      final scoring = ExamScoringService(
        answerKeys: {
          'mcq_1': 1,
          'mcq_2': 1,
          'mcq_3': 2,
        },
      );

      // Submit 2 correct and 1 wrong answer
      final result = scoring.scoreSubmission(
        candidateDetails: testCandidate,
        mcqAnswers: {
          'mcq_1': 1, // correct
          'mcq_2': 1, // correct
          'mcq_3': 0, // incorrect (expected 2)
        },
        codingDrafts: {
          'code_1': 'function isPalindrome(str) { return true; }',
        },
        submissionReason: 'Manual test submission',
      );

      expect(result.mcqScore, 2);
      expect(result.maxMcqScore, 10);
      expect(result.codingAttemptedCount, 1);
      expect(result.isPreliminary, isTrue);
      expect(result.codingEvaluationStatus, contains('Pending Automated Test Suite Evaluation'));
    });

    test('Code execution service: rejects unmodified starter code safely', () async {
      final runner = SafePlaceholderCodeExecutionService();
      final challenge = controllerChallengeHelper();

      // Test with unmodified starter code
      final resultUnmodified = await runner.executeTests(
        challenge: challenge,
        code: challenge.starterCode,
      );

      expect(resultUnmodified.allPassed, isFalse);
      expect(resultUnmodified.isSandboxPlaceholder, isTrue);
      expect(resultUnmodified.summary, contains('Starter code remains unchanged'));

      // Test with valid solution structure
      const validCode = '''
function isPalindrome(str) {
  const clean = str.toLowerCase().replace(/[^a-z0-9]/g, '');
  return clean === clean.split('').reverse().join('');
}
''';
      final resultValid = await runner.executeTests(
        challenge: challenge,
        code: validCode,
      );

      expect(resultValid.allPassed, isTrue);
      expect(resultValid.testCaseResults.length, challenge.testCases.length);
    });
  });
}

CodingChallenge controllerChallengeHelper() {
  return const CodingChallenge(
    id: 'code_1',
    number: 1,
    title: 'Palindrome Test',
    description: 'Check palindrome',
    language: 'JavaScript',
    starterCode: 'function isPalindrome(str) {\n  // starter\n}',
    sampleInput: 'test',
    sampleOutput: 'true',
    testCases: [
      CodingTestCase(input: '"racecar"', expectedOutput: 'true'),
    ],
  );
}

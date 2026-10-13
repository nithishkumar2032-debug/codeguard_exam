/// Secret answer keys for examination MCQs.
///
/// Security Notice: This file is used exclusively by the [ExamScoringService]
/// and is never transmitted or exposed to the candidate's question views.
abstract class SecretExamAnswerKeys {
  static const Map<String, int> mcqAnswerKeys = {
    'mcq_1': 1, // O(log n)
    'mcq_2': 1, // ===
    'mcq_3': 2, // Stack
    'mcq_4': 0, // Atomicity
    'mcq_5': 2, // Orchestrating asynchronous callbacks, Promises, and the Call Stack
    'mcq_6': 1, // 201 Created
    'mcq_7': 0, // The same shared secret key
    'mcq_8': 1, // O(n log n)
    'mcq_9': 1, // Flexbox
    'mcq_10': 1, // Single Responsibility Principle
  };
}

/// Visual and operational status of an exam question.
enum QuestionStatus {
  unanswered,
  answered,
  markedForReview,
  answeredAndMarkedForReview,
}

extension QuestionStatusExtension on QuestionStatus {
  bool get isAnswered =>
      this == QuestionStatus.answered ||
      this == QuestionStatus.answeredAndMarkedForReview;

  bool get isMarkedForReview =>
      this == QuestionStatus.markedForReview ||
      this == QuestionStatus.answeredAndMarkedForReview;
}

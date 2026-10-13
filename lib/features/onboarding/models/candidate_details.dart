/// Data model capturing candidate onboarding details for an assessment session.
///
/// Note: These fields are collected for session context and display.
/// Official identity verification will be handled by the backend in a future milestone.
class CandidateDetails {
  final String studentName;
  final String registerNumber;
  final String examinationName;

  const CandidateDetails({
    required this.studentName,
    required this.registerNumber,
    required this.examinationName,
  });

  CandidateDetails copyWith({
    String? studentName,
    String? registerNumber,
    String? examinationName,
  }) {
    return CandidateDetails(
      studentName: studentName ?? this.studentName,
      registerNumber: registerNumber ?? this.registerNumber,
      examinationName: examinationName ?? this.examinationName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandidateDetails &&
          runtimeType == other.runtimeType &&
          studentName == other.studentName &&
          registerNumber == other.registerNumber &&
          examinationName == other.examinationName;

  @override
  int get hashCode =>
      studentName.hashCode ^ registerNumber.hashCode ^ examinationName.hashCode;
}

/// Candidate-facing Coding Challenge model.
class CodingTestCase {
  final String input;
  final String expectedOutput;
  final bool isHidden;

  const CodingTestCase({
    required this.input,
    required this.expectedOutput,
    this.isHidden = false,
  });

  Map<String, dynamic> toJson() => {
    'input': input,
    'expectedOutput': expectedOutput,
    'isHidden': isHidden,
  };

  factory CodingTestCase.fromJson(Map<String, dynamic> json) {
    return CodingTestCase(
      input: json['input'] as String,
      expectedOutput: json['expectedOutput'] as String,
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }
}

class CodingChallenge {
  final String id;
  final int number;
  final String title;
  final String description;
  final String language;
  final String starterCode;
  final String sampleInput;
  final String sampleOutput;
  final List<CodingTestCase> testCases;

  const CodingChallenge({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.language,
    required this.starterCode,
    required this.sampleInput,
    required this.sampleOutput,
    required this.testCases,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'title': title,
    'description': description,
    'language': language,
    'starterCode': starterCode,
    'sampleInput': sampleInput,
    'sampleOutput': sampleOutput,
    'testCases': testCases.map((tc) => tc.toJson()).toList(),
  };

  factory CodingChallenge.fromJson(Map<String, dynamic> json) {
    return CodingChallenge(
      id: json['id'] as String,
      number: json['number'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      language: json['language'] as String,
      starterCode: json['starterCode'] as String,
      sampleInput: json['sampleInput'] as String,
      sampleOutput: json['sampleOutput'] as String,
      testCases: (json['testCases'] as List)
          .map((tc) => CodingTestCase.fromJson(tc as Map<String, dynamic>))
          .toList(),
    );
  }
}

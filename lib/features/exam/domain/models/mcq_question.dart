/// Candidate-facing Multiple Choice Question model.
///
/// Security Notice: The correct answer key is strictly omitted from this model
/// to prevent client-side inspection or exploitation.
class McqQuestion {
  final String id;
  final int number;
  final String text;
  final List<String> options;

  const McqQuestion({
    required this.id,
    required this.number,
    required this.text,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'text': text,
    'options': options,
  };

  factory McqQuestion.fromJson(Map<String, dynamic> json) {
    return McqQuestion(
      id: json['id'] as String,
      number: json['number'] as int,
      text: json['text'] as String,
      options: List<String>.from(json['options'] as List),
    );
  }
}

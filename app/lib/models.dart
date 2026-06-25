class Question {
  final int id;
  final String optionA;
  final String optionB;
  final String category;
  int votesA;
  int votesB;

  Question({
    required this.id,
    required this.optionA,
    required this.optionB,
    required this.category,
    this.votesA = 0,
    this.votesB = 0,
  });

  int get totalVotes => votesA + votesB;

  double get percentA => totalVotes == 0 ? 0 : votesA / totalVotes;
  double get percentB => totalVotes == 0 ? 0 : votesB / totalVotes;

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as int,
        optionA: j['option_a'] as String,
        optionB: j['option_b'] as String,
        category: (j['category'] ?? 'Community') as String,
        votesA: (j['votes_a'] ?? 0) as int,
        votesB: (j['votes_b'] ?? 0) as int,
      );
}

/// A pending question awaiting admin review (no vote counts shown).
class PendingQuestion {
  final int id;
  String optionA;
  String optionB;
  String category;

  PendingQuestion({
    required this.id,
    required this.optionA,
    required this.optionB,
    required this.category,
  });

  factory PendingQuestion.fromJson(Map<String, dynamic> j) => PendingQuestion(
        id: j['id'] as int,
        optionA: j['option_a'] as String,
        optionB: j['option_b'] as String,
        category: (j['category'] ?? 'Community') as String,
      );
}

class Topic {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final bool isPremium;
  final String category;
  final String domain;

  const Topic({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.isPremium,
    required this.category,
    required this.domain,
  });
}

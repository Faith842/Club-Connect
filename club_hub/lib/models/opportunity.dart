class Opportunity {
  final String id;
  String title;
  String description;
  String organization;
  String type;
  String? deadline;
  String applicationLink;
  bool isBookmarked;
  String emoji;
  String colorHex;
  String eligibility;

  Opportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.organization,
    required this.type,
    this.deadline,
    required this.applicationLink,
    this.isBookmarked = false,
    required this.emoji,
    required this.colorHex,
    required this.eligibility,
  });
}

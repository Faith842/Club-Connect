class Event {
  final String id;
  final String clubId;
  String clubName;
  String title;
  String description;
  String category;
  DateTime date;
  String time;
  String location;
  String format;
  int maxAttendees;
  List<String> rsvpdUserIds;
  final String organizerId;
  String organizerName;
  String emoji;
  String colorHex;

  Event({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.time,
    required this.location,
    required this.format,
    required this.maxAttendees,
    required this.rsvpdUserIds,
    required this.organizerId,
    required this.organizerName,
    required this.emoji,
    required this.colorHex,
  });

  int get rsvpCount => rsvpdUserIds.length;
  bool isRsvpd(String userId) => rsvpdUserIds.contains(userId);
  bool get isFull => maxAttendees > 0 && rsvpCount >= maxAttendees;
  int get spotsLeft => maxAttendees > 0 ? maxAttendees - rsvpCount : -1;
  bool get isUpcoming => date.isAfter(DateTime.now());

  Event copyWith({
    String? title,
    String? description,
    String? category,
    DateTime? date,
    String? time,
    String? location,
    String? format,
    int? maxAttendees,
    List<String>? rsvpdUserIds,
    String? emoji,
    String? colorHex,
  }) {
    return Event(
      id: id,
      clubId: clubId,
      clubName: clubName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      format: format ?? this.format,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      rsvpdUserIds: rsvpdUserIds ?? List.from(this.rsvpdUserIds),
      organizerId: organizerId,
      organizerName: organizerName,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}

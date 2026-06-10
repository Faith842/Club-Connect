class Club {
  final String id;
  String name;
  String description;
  String category;
  final String leaderId;
  String leaderName;
  List<String> memberIds;
  List<String> pendingMemberIds;
  String emoji;
  String colorHex;
  DateTime createdAt;
  List<String> tags;
  String meetingSchedule;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.leaderId,
    required this.leaderName,
    required this.memberIds,
    required this.pendingMemberIds,
    required this.emoji,
    required this.colorHex,
    required this.createdAt,
    required this.tags,
    required this.meetingSchedule,
  });

  int get memberCount => memberIds.length;
  bool isMember(String userId) => memberIds.contains(userId);
  bool isPending(String userId) => pendingMemberIds.contains(userId);

  Club copyWith({
    String? name,
    String? description,
    String? category,
    String? leaderName,
    List<String>? memberIds,
    List<String>? pendingMemberIds,
    String? emoji,
    String? colorHex,
    List<String>? tags,
    String? meetingSchedule,
  }) {
    return Club(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      leaderId: leaderId,
      leaderName: leaderName ?? this.leaderName,
      memberIds: memberIds ?? List.from(this.memberIds),
      pendingMemberIds: pendingMemberIds ?? List.from(this.pendingMemberIds),
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt,
      tags: tags ?? List.from(this.tags),
      meetingSchedule: meetingSchedule ?? this.meetingSchedule,
    );
  }
}

class AppUser {
  final String id;
  String name;
  final String email;
  final String role;
  String avatar;
  String major;
  String cohort;
  List<String> interests;
  List<String> joinedClubIds;
  List<String> rsvpdEventIds;
  int points;
  List<String> badges;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatar,
    required this.major,
    required this.cohort,
    required this.interests,
    required this.joinedClubIds,
    required this.rsvpdEventIds,
    required this.points,
    required this.badges,
  });

  bool get isLeader => role == 'club_leader';
  bool get isStudent => role == 'student';

  String get pointsLevel {
    if (points >= 1000) return 'Gold';
    if (points >= 500) return 'Silver';
    return 'Bronze';
  }
}

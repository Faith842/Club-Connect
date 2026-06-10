class MembershipRequest {
  final String id;
  final String clubId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String userMajor;
  final String userCohort;
  final DateTime requestedAt;
  String status;

  MembershipRequest({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userMajor,
    required this.userCohort,
    required this.requestedAt,
    this.status = 'pending',
  });
}

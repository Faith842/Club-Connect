class Message {
  final String id;
  final String clubId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String senderRole;
  final String content;
  final DateTime timestamp;
  final bool isAnnouncement;

  const Message({
    required this.id,
    required this.clubId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.senderRole,
    required this.content,
    required this.timestamp,
    this.isAnnouncement = false,
  });
}

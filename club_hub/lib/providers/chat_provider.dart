import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../utils/mock_data.dart';

class ChatProvider extends ChangeNotifier {
  final Map<String, List<Message>> _messages = {};
  final _uuid = const Uuid();

  ChatProvider() {
    for (final club in MockData.getClubs()) {
      _messages[club.id] = MockData.getMessages(club.id);
    }
  }

  List<Message> getMessages(String clubId) =>
      List.unmodifiable(_messages[clubId] ?? []);

  Message? lastMessage(String clubId) {
    final msgs = _messages[clubId];
    if (msgs == null || msgs.isEmpty) return null;
    return msgs.last;
  }

  int unreadCount(String clubId) {
    final msgs = _messages[clubId];
    if (msgs == null) return 0;
    return msgs.where((m) => m.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 24)))).length;
  }

  void sendMessage({
    required String clubId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String senderRole,
    required String content,
    bool isAnnouncement = false,
  }) {
    _messages.putIfAbsent(clubId, () => []);
    _messages[clubId]!.add(Message(
      id: _uuid.v4(),
      clubId: clubId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      senderRole: senderRole,
      content: content,
      timestamp: DateTime.now(),
      isAnnouncement: isAnnouncement,
    ));
    notifyListeners();
  }

  void initClub(String clubId) {
    _messages.putIfAbsent(clubId, () => MockData.getMessages(clubId));
  }
}

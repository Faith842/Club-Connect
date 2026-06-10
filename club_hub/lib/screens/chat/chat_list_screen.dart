import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state_widget.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final clubProv = context.watch<ClubProvider>();
    final chatProv = context.watch<ChatProvider>();
    final user = auth.currentUser!;
    final myClubs = clubProv.myClubs(user.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: myClubs.isEmpty
          ? const EmptyStateWidget(
              emoji: '💬',
              title: 'No conversations yet',
              subtitle: 'Join a club to start chatting with members and leaders',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: myClubs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) {
                final club = myClubs[i];
                final last = chatProv.lastMessage(club.id);
                final isLeader = club.leaderId == user.id;

                Color color;
                try {
                  color = Color(int.parse('FF${club.colorHex.replaceFirst('#', '')}', radix: 16));
                } catch (_) {
                  color = AppColors.primary;
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(club.emoji, style: const TextStyle(fontSize: 26))),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          club.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (last != null)
                        Text(
                          _formatTime(last.timestamp),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          last != null
                              ? '${last.senderId == user.id ? 'You' : last.senderName.split(' ').first}: ${last.content}'
                              : 'No messages yet. Say hello!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      if (isLeader)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x1FFF6D00),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Leader', style: TextStyle(fontSize: 9, color: AppColors.accent, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatRoomScreen(clubId: club.id, clubName: club.name)),
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(dt);
  }
}

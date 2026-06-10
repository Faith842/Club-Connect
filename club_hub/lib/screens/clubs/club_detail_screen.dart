import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/mock_data.dart';
import '../../providers/club_provider.dart';
import '../../providers/event_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../events/event_detail_screen.dart';
import '../events/create_edit_event_screen.dart';
import '../chat/chat_room_screen.dart';
import 'create_edit_club_screen.dart';
import 'member_management_screen.dart';

class ClubDetailScreen extends StatefulWidget {
  final String clubId;
  const ClubDetailScreen({super.key, required this.clubId});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final clubProv = context.watch<ClubProvider>();
    final eventProv = context.watch<EventProvider>();
    final user = auth.currentUser!;
    final club = clubProv.findById(widget.clubId);

    if (club == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Club')),
        body: const EmptyStateWidget(emoji: '❌', title: 'Club not found', subtitle: 'This club may have been removed'),
      );
    }

    final isLeader = club.leaderId == user.id;
    final isMember = club.isMember(user.id);
    final isPending = club.isPending(user.id);
    final events = eventProv.clubEvents(club.id);

    Color color;
    try {
      final hex = club.colorHex.replaceFirst('#', '');
      color = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      color = AppColors.primary;
    }

    final pending = clubProv.pendingRequests(club.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            foregroundColor: Colors.white,
            actions: [
              if (isLeader) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateEditClubScreen(club: club)),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'delete') _confirmDelete(context, clubProv);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'delete', child: Text('Delete Club', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(club.emoji, style: const TextStyle(fontSize: 52)),
                    const SizedBox(height: 8),
                    Text(
                      club.name,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      club.category,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              tabs: const [Tab(text: 'About'), Tab(text: 'Events'), Tab(text: 'Members')],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _AboutTab(
              club: club,
              isLeader: isLeader,
              isMember: isMember,
              isPending: isPending,
              color: color,
              pending: pending.length,
              onJoin: () {
                clubProv.requestJoin(club.id, user);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Join request sent! Waiting for approval.'), behavior: SnackBarBehavior.floating),
                );
              },
              onLeave: () => _confirmLeave(context, clubProv, user.id),
              onManage: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberManagementScreen(clubId: club.id))),
              onChat: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(clubId: club.id, clubName: club.name))),
              onCreateEvent: isLeader ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEditEventScreen(clubId: club.id, clubName: club.name))) : null,
            ),
            _EventsTab(events: events, userId: user.id),
            _MembersTab(club: club, currentUserId: user.id, isLeader: isLeader),
          ],
        ),
      ),
    );
  }

  void _confirmLeave(BuildContext context, ClubProvider clubProv, String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Club?'),
        content: const Text('You will need to request to join again if you change your mind.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              clubProv.leaveClub(widget.clubId, userId);
              context.read<AuthProvider>().removeJoinedClub(widget.clubId);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Leave', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ClubProvider clubProv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Club?'),
        content: const Text('This action cannot be undone. All club data will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              clubProv.deleteClub(widget.clubId);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Club deleted'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  final dynamic club;
  final bool isLeader;
  final bool isMember;
  final bool isPending;
  final Color color;
  final int pending;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onManage;
  final VoidCallback onChat;
  final VoidCallback? onCreateEvent;

  const _AboutTab({
    required this.club,
    required this.isLeader,
    required this.isMember,
    required this.isPending,
    required this.color,
    required this.pending,
    required this.onJoin,
    required this.onLeave,
    required this.onManage,
    required this.onChat,
    this.onCreateEvent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _StatCard(label: 'Members', value: '${club.memberCount}', icon: Icons.people_outline, color: color),
            const SizedBox(width: 10),
            _StatCard(label: 'Pending', value: '${club.pendingMemberIds.length}', icon: Icons.hourglass_empty_outlined, color: AppColors.warning),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'About',
          child: Text(club.description, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Meeting Schedule',
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: color),
              const SizedBox(width: 8),
              Text(club.meetingSchedule, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Club Leader',
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.12),
                child: const Text('👑', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Text(club.leaderName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
        if (club.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Tags',
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: (club.tags as List).map<Widget>((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tag.toString(), style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (isLeader) ...[
          if (pending > 0)
            OutlinedButton.icon(
              onPressed: onManage,
              icon: Badge(label: Text('$pending'), child: const Icon(Icons.people)),
              label: const Text('Manage Members'),
            ),
          if (pending == 0)
            OutlinedButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.people_outline),
              label: const Text('Manage Members'),
            ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: onCreateEvent,
            icon: const Icon(Icons.add),
            label: const Text('Post New Event'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Open Club Chat'),
          ),
        ] else if (isMember) ...[
          ElevatedButton.icon(
            onPressed: onChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Open Club Chat'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onLeave,
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Leave Club'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isPending ? null : onJoin,
              style: ElevatedButton.styleFrom(backgroundColor: isPending ? Colors.grey : AppColors.primary),
              child: Text(isPending ? 'Request Pending...' : 'Request to Join'),
            ),
          ),
        ],
      ],
    );
  }
}

class _EventsTab extends StatelessWidget {
  final List events;
  final String userId;
  const _EventsTab({required this.events, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const EmptyStateWidget(emoji: '📅', title: 'No events yet', subtitle: 'This club hasn\'t posted any events');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = events[i];
        return EventCard(
          event: e,
          currentUserId: userId,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: e.id))),
        );
      },
    );
  }
}

class _MembersTab extends StatelessWidget {
  final dynamic club;
  final String currentUserId;
  final bool isLeader;
  const _MembersTab({required this.club, required this.currentUserId, required this.isLeader});

  @override
  Widget build(BuildContext context) {
    final members = club.memberIds as List<String>;
    if (members.isEmpty) {
      return const EmptyStateWidget(emoji: '👥', title: 'No members yet', subtitle: 'Be the first to join!');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, i) {
        final uid = members[i];
        final isCurrentLeader = uid == club.leaderId;
        final info = _getUser(uid);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0x1F1565C0),
            child: Text(info['avatar']!, style: const TextStyle(fontSize: 18)),
          ),
          title: Text(info['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(info['major']!, style: const TextStyle(fontSize: 12)),
          trailing: isCurrentLeader
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0x1FFF6D00),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Leader', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
        );
      },
    );
  }

  Map<String, String> _getUser(String uid) {
    for (final u in [
      {'id': 'user_001', 'name': 'Amara Diallo', 'avatar': '👩🏾', 'major': 'Computer Science'},
      {'id': 'user_002', 'name': 'Kwame Asante', 'avatar': '👨🏿', 'major': 'Entrepreneurship'},
      ...MockData.otherUsers,
    ]) {
      if (u['id'] == uid) return {'name': u['name']!, 'avatar': u['avatar']!, 'major': u['major']!};
    }
    return {'name': 'ALU Student', 'avatar': '👤', 'major': 'ALU'};
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

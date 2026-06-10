import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state_widget.dart';

class MemberManagementScreen extends StatelessWidget {
  final String clubId;
  const MemberManagementScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context) {
    final clubProv = context.watch<ClubProvider>();
    final club = clubProv.findById(clubId);
    if (club == null) return const SizedBox.shrink();

    final pending = clubProv.pendingRequests(clubId);
    final members = club.memberIds;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Members'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '${club.memberCount} members',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pending.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.hourglass_empty, size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  'Pending Requests (${pending.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...pending.map((req) => _RequestCard(
              request: req,
              onApprove: () {
                clubProv.approveMembership(req.id, (userId, cId) {
                  context.read<AuthProvider>().addJoinedClub(cId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${req.userName} approved!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onReject: () {
                clubProv.rejectMembership(req.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${req.userName}\'s request declined'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            )),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
          ],
          if (pending.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text('No pending requests', style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Current Members (${members.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (members.isEmpty)
            const EmptyStateWidget(emoji: '👥', title: 'No members yet', subtitle: 'Members who join will appear here')
          else
            ...members.map((uid) {
              final isLeader = uid == club.leaderId;
              final info = _userInfo(uid);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0x1F1565C0),
                    child: Text(info['avatar']!, style: const TextStyle(fontSize: 18)),
                  ),
                  title: Text(info['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(info['major']!, style: const TextStyle(fontSize: 12)),
                  trailing: isLeader
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0x1FFF6D00),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Leader', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)),
                        )
                      : PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                          onSelected: (val) {
                            if (val == 'remove') {
                              _confirmRemove(context, clubProv, uid, info['name']!);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove from club', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, ClubProvider clubProv, String userId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Remove $name from this club?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              clubProv.removeMember(clubId, userId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name removed'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Map<String, String> _userInfo(String uid) {
    const all = [
      {'id': 'user_001', 'name': 'Amara Diallo', 'avatar': '👩🏾', 'major': 'Computer Science'},
      {'id': 'user_002', 'name': 'Kwame Asante', 'avatar': '👨🏿', 'major': 'Entrepreneurship'},
      {'id': 'user_003', 'name': 'Ngozi Okonkwo', 'avatar': '👩🏿', 'major': 'Global Challenges'},
      {'id': 'user_004', 'name': 'Darius Kamau', 'avatar': '👨🏾', 'major': 'Computer Science'},
      {'id': 'user_005', 'name': 'Fatima Al-Hassan', 'avatar': '👩🏽', 'major': 'Business Management'},
      {'id': 'user_006', 'name': 'Tendai Moyo', 'avatar': '👨🏿', 'major': 'Social Sciences'},
      {'id': 'user_007', 'name': 'Asha Kipchoge', 'avatar': '👩🏾', 'major': 'Health Sciences'},
      {'id': 'user_008', 'name': 'Zara Mensah', 'avatar': '👩🏿', 'major': 'Entrepreneurship'},
      {'id': 'user_009', 'name': 'Kofi Acheampong', 'avatar': '👨🏾', 'major': 'Computer Science'},
      {'id': 'user_010', 'name': 'Aisha Ndiaye', 'avatar': '👩🏽', 'major': 'Arts & Media'},
      {'id': 'user_011', 'name': 'Sipho Dlamini', 'avatar': '👨🏿', 'major': 'Education'},
      {'id': 'user_012', 'name': 'Precious Osei', 'avatar': '👩🏾', 'major': 'Global Challenges'},
    ];
    for (final u in all) {
      if (u['id'] == uid) return {'name': u['name']!, 'avatar': u['avatar']!, 'major': u['major']!};
    }
    return {'name': 'ALU Student', 'avatar': '👤', 'major': 'ALU'};
  }
}

class _RequestCard extends StatelessWidget {
  final dynamic request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({required this.request, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                child: Text(request.userAvatar, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${request.userMajor} · ${request.userCohort}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d').format(request.requestedAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

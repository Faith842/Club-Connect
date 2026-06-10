import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_provider.dart';
import '../../providers/event_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/mock_data.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final clubProv = context.watch<ClubProvider>();
    final eventProv = context.watch<EventProvider>();
    final user = auth.currentUser!;
    final myClubs = clubProv.myClubs(user.id);
    final rsvpdEvents = eventProv.userRsvpdEvents(user.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showEditProfile(context, auth),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _confirmLogout(context, auth),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    GestureDetector(
                      onTap: () => _showAvatarPicker(context, auth),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(user.avatar, style: const TextStyle(fontSize: 44)),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit, size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(user.major, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LevelBadge(level: user.pointsLevel),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.cohort,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        if (user.isLeader) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Club Leader', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsRow(user: user, clubs: myClubs.length, events: rsvpdEvents.length),
                  const SizedBox(height: 16),
                  if (user.badges.isNotEmpty) ...[
                    _SectionHeader(title: 'Achievements', trailing: '${user.badges.length} badges'),
                    const SizedBox(height: 10),
                    _BadgesGrid(badges: user.badges),
                    const SizedBox(height: 16),
                  ],
                  _SectionHeader(title: 'My Clubs', trailing: '${myClubs.length}'),
                  const SizedBox(height: 10),
                  if (myClubs.isEmpty)
                    const _EmptyCard(text: 'Join clubs to see them here')
                  else
                    ...myClubs.map((club) {
                      Color color;
                      try {
                        color = Color(int.parse('FF${club.colorHex.replaceFirst('#', '')}', radix: 16));
                      } catch (_) {
                        color = AppColors.primary;
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                              child: Center(child: Text(club.emoji, style: const TextStyle(fontSize: 20))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(club.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('${club.memberCount} members · ${club.category}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            if (club.leaderId == user.id)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0x1FFF6D00), borderRadius: BorderRadius.circular(6)),
                                child: const Text('Leader', style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'My RSVPs', trailing: '${rsvpdEvents.length}'),
                  const SizedBox(height: 10),
                  if (rsvpdEvents.isEmpty)
                    const _EmptyCard(text: 'RSVP for events to see them here')
                  else
                    ...rsvpdEvents.take(3).map((event) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Text(event.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('${event.clubName} · ${event.date.day}/${event.date.month}/${event.date.year}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Going', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser!;
    final nameCtrl = TextEditingController(text: user.name);
    final majorCtrl = TextEditingController(text: user.major);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(controller: majorCtrl, decoration: const InputDecoration(labelText: 'Major')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  auth.updateProfile(name: nameCtrl.text.trim(), major: majorCtrl.text.trim());
                  Navigator.pop(context);
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, AuthProvider auth) {
    const avatars = ['👩🏾', '👨🏿', '👩🏿', '👨🏾', '👩🏽', '👨🏽', '🧑🏾', '🧑🏿', '👩🏻', '👨🏻', '🧑🏻', '🧑🏼'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Avatar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: avatars.map((a) => GestureDetector(
                onTap: () { auth.updateProfile(avatar: a); Navigator.pop(context); },
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: auth.currentUser!.avatar == a ? const Color(0x1F1565C0) : AppColors.background,
                    shape: BoxShape.circle,
                    border: auth.currentUser!.avatar == a ? Border.all(color: AppColors.primary, width: 2) : null,
                  ),
                  child: Center(child: Text(a, style: const TextStyle(fontSize: 28))),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('You\'ll need to sign in again to access your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              auth.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final dynamic user;
  final int clubs;
  final int events;
  const _StatsRow({required this.user, required this.clubs, required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _Stat(value: '$clubs', label: 'Clubs'),
          _divider(),
          _Stat(value: '$events', label: 'RSVPs'),
          _divider(),
          _Stat(value: '${user.points}', label: 'Points'),
          _divider(),
          _Stat(value: '${user.badges.length}', label: 'Badges'),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.divider, margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    ),
  );
}

class _BadgesGrid extends StatelessWidget {
  final List<String> badges;
  const _BadgesGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges.map((b) {
        final label = MockData.badgeLabels[b] ?? b;
        final desc = MockData.badgeDescriptions[b] ?? '';
        return Tooltip(
          message: desc,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionHeader({required this.title, this.trailing});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      if (trailing != null) ...[
        const Spacer(),
        Text(trailing!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    ],
  );
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
    child: Center(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
  );
}

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});
  @override
  Widget build(BuildContext context) {
    final colors = {'Gold': const Color(0xFFFFD700), 'Silver': const Color(0xFFC0C0C0), 'Bronze': const Color(0xFFCD7F32)};
    final c = colors[level] ?? AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withValues(alpha: 0.5))),
      child: Text('$level Member', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

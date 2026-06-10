import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../theme/app_theme.dart';
import 'create_edit_event_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final eventProv = context.watch<EventProvider>();
    final user = auth.currentUser!;
    final event = eventProv.findById(eventId);

    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event')),
        body: const Center(child: Text('Event not found')),
      );
    }

    final isRsvpd = event.isRsvpd(user.id);
    final isOrganizer = event.organizerId == user.id;

    Color color;
    try {
      color = Color(int.parse('FF${event.colorHex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      color = AppColors.primary;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: color,
            foregroundColor: Colors.white,
            actions: [
              if (isOrganizer)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateEditEventScreen(
                        clubId: event.clubId,
                        clubName: event.clubName,
                        event: event,
                      ),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Text(event.emoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        event.title,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.clubName,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
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
                  _RsvpBanner(
                    isRsvpd: isRsvpd,
                    isFull: event.isFull,
                    spotsLeft: event.spotsLeft,
                    rsvpCount: event.rsvpCount,
                    maxAttendees: event.maxAttendees,
                    color: color,
                    onRsvp: () {
                      if (isRsvpd) {
                        eventProv.cancelRsvp(event.id, user.id);
                        auth.removeRsvp(event.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('RSVP cancelled'), behavior: SnackBarBehavior.floating),
                        );
                      } else if (!event.isFull) {
                        eventProv.rsvpEvent(event.id, user.id);
                        auth.addRsvp(event.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You\'re going! +50 points earned 🎉'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _InfoGrid(event: event, color: color),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'About This Event',
                    child: Text(
                      event.description,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Organizer',
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withValues(alpha: 0.12),
                          child: const Text('👑', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 10),
                        Text(event.organizerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AttendeesSection(rsvpdUserIds: event.rsvpdUserIds, color: color),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RsvpBanner extends StatelessWidget {
  final bool isRsvpd;
  final bool isFull;
  final int spotsLeft;
  final int rsvpCount;
  final int maxAttendees;
  final Color color;
  final VoidCallback onRsvp;

  const _RsvpBanner({
    required this.isRsvpd,
    required this.isFull,
    required this.spotsLeft,
    required this.rsvpCount,
    required this.maxAttendees,
    required this.color,
    required this.onRsvp,
  });

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;
    if (isRsvpd) {
      statusText = '✅ You\'re going!';
      statusColor = AppColors.success;
    } else if (isFull) {
      statusText = '⛔ Event is full';
      statusColor = AppColors.error;
    } else {
      statusText = spotsLeft > 0 ? '$spotsLeft spots remaining' : 'Open attendance';
      statusColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRsvpd ? AppColors.success.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRsvpd ? AppColors.success.withValues(alpha: 0.4) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: statusColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '$rsvpCount${maxAttendees > 0 ? '/$maxAttendees' : ''} people going',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isFull && !isRsvpd ? null : onRsvp,
            style: ElevatedButton.styleFrom(
              backgroundColor: isRsvpd ? AppColors.error : color,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isRsvpd ? 'Cancel RSVP' : 'RSVP Now'),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final dynamic event;
  final Color color;
  const _InfoGrid({required this.event, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _InfoRow(Icons.calendar_today_outlined, 'Date', DateFormat('EEEE, MMMM d, yyyy').format(event.date as DateTime), color),
          const Divider(height: 16),
          _InfoRow(Icons.access_time_outlined, 'Time', event.time as String, color),
          const Divider(height: 16),
          _InfoRow(Icons.location_on_outlined, 'Location', event.location as String, color),
          const Divider(height: 16),
          _InfoRow(Icons.laptop_outlined, 'Format', event.format as String, color),
          const Divider(height: 16),
          _InfoRow(Icons.category_outlined, 'Category', event.category as String, color),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoRow(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}

class _AttendeesSection extends StatelessWidget {
  final List<String> rsvpdUserIds;
  final Color color;
  const _AttendeesSection({required this.rsvpdUserIds, required this.color});

  @override
  Widget build(BuildContext context) {
    if (rsvpdUserIds.isEmpty) return const SizedBox.shrink();

    const allUsers = [
      {'id': 'user_001', 'avatar': '👩🏾', 'name': 'Amara'},
      {'id': 'user_002', 'avatar': '👨🏿', 'name': 'Kwame'},
      {'id': 'user_003', 'avatar': '👩🏿', 'name': 'Ngozi'},
      {'id': 'user_004', 'avatar': '👨🏾', 'name': 'Darius'},
      {'id': 'user_005', 'avatar': '👩🏽', 'name': 'Fatima'},
      {'id': 'user_006', 'avatar': '👨🏿', 'name': 'Tendai'},
      {'id': 'user_007', 'avatar': '👩🏾', 'name': 'Asha'},
      {'id': 'user_008', 'avatar': '👩🏿', 'name': 'Zara'},
      {'id': 'user_009', 'avatar': '👨🏾', 'name': 'Kofi'},
      {'id': 'user_010', 'avatar': '👩🏽', 'name': 'Aisha'},
      {'id': 'user_011', 'avatar': '👨🏿', 'name': 'Sipho'},
      {'id': 'user_012', 'avatar': '👩🏾', 'name': 'Precious'},
    ];

    return _Section(
      title: 'Attendees (${rsvpdUserIds.length})',
      child: Row(
        children: [
          ...rsvpdUserIds.take(5).map((uid) {
            final u = allUsers.firstWhere((u) => u['id'] == uid, orElse: () => {'avatar': '👤', 'name': 'Student'});
            return Tooltip(
              message: u['name']!,
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(child: Text(u['avatar']!, style: const TextStyle(fontSize: 18))),
              ),
            );
          }),
          if (rsvpdUserIds.length > 5)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '+${rsvpdUserIds.length - 5}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_provider.dart';
import '../../providers/event_provider.dart';
import '../../models/app_user.dart';
import '../../models/event.dart';
import '../../models/club.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../events/event_detail_screen.dart';
import '../clubs/club_detail_screen.dart';
import '../opportunities/opportunities_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'All';
  final _filters = ['All', 'Events', 'Clubs', 'Opportunities'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final eventProv = context.watch<EventProvider>();
    final clubProv = context.watch<ClubProvider>();
    final user = auth.currentUser!;
    final events = eventProv.upcomingEvents;
    final myClubs = clubProv.myClubs(user.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => await Future.delayed(const Duration(milliseconds: 600)),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(user, myClubs)),
              SliverToBoxAdapter(child: _buildSearch()),
              SliverToBoxAdapter(child: _buildFilters()),
              if (_filter == 'All' || _filter == 'Events')
                SliverToBoxAdapter(child: _buildSection('Upcoming Events', Icons.event)),
              if (_filter == 'All' || _filter == 'Events')
                _buildEventsList(events, user.id),
              if (_filter == 'All' || _filter == 'Clubs')
                SliverToBoxAdapter(child: _buildSection('Your Clubs', Icons.groups)),
              if (_filter == 'All' || _filter == 'Clubs')
                SliverToBoxAdapter(child: _buildClubsRow(myClubs)),
              if (_filter == 'All' || _filter == 'Opportunities')
                SliverToBoxAdapter(
                  child: _buildOpportunitiesBanner(),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppUser user, List<Club> myClubs) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(user.avatar, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                    Text(
                      user.name.split(' ').first,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '${user.points} pts',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatBubble(label: 'Clubs', value: '${user.joinedClubIds.length}'),
                ),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.3)),
                Expanded(
                  child: _StatBubble(label: 'RSVPs', value: '${user.rsvpdEventIds.length}'),
                ),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.3)),
                Expanded(
                  child: _StatBubble(label: 'Badges', value: '${user.badges.length}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search events, clubs...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final selected = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f),
                selected: selected,
                onSelected: (_) => setState(() => _filter = f),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                selectedColor: const Color(0x1F1565C0),
                checkmarkColor: AppColors.primary,
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<Event> events, String userId) {
    final query = _searchCtrl.text.toLowerCase();
    final filtered = query.isEmpty
        ? events
        : events.where((e) => e.title.toLowerCase().contains(query) || e.clubName.toLowerCase().contains(query)).toList();

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: EmptyStateWidget(
            emoji: '📅',
            title: 'No events found',
            subtitle: query.isNotEmpty ? 'Try a different search term' : 'Check back soon for upcoming events',
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final e = filtered[i];
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: EventCard(
              event: e,
              currentUserId: userId,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: e.id))),
              onRsvp: () {
                final eventProv = context.read<EventProvider>();
                final authProv = context.read<AuthProvider>();
                if (e.isRsvpd(userId)) {
                  eventProv.cancelRsvp(e.id, userId);
                  authProv.removeRsvp(e.id);
                } else {
                  eventProv.rsvpEvent(e.id, userId);
                  authProv.addRsvp(e.id);
                }
              },
            ),
          );
        },
        childCount: filtered.length,
      ),
    );
  }

  Widget _buildClubsRow(List<Club> myClubs) {
    if (myClubs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: EmptyStateWidget(
          emoji: '🏛️',
          title: 'No clubs yet',
          subtitle: 'Go to the Clubs tab to discover and join communities',
        ),
      );
    }
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: myClubs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = myClubs[i];
          Color color;
          try {
            final hex = c.colorHex.replaceFirst('#', '');
            color = Color(int.parse('FF$hex', radix: 16));
          } catch (_) {
            color = AppColors.primary;
          }
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: c.id)),
            ),
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(c.emoji, style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.name,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpportunitiesBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OpportunitiesScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF003C8F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🎓', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Opportunities Board',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scholarships, internships & competitions for ALU students',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.7), size: 16),
          ],
        ),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String label;
  final String value;
  const _StatBubble({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
      ],
    );
  }
}

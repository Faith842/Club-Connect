import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/mock_data.dart';
import '../../widgets/event_card.dart';
import '../../widgets/empty_state_widget.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final eventProv = context.watch<EventProvider>();
    final user = auth.currentUser!;

    final allEvents = eventProv.search(_searchCtrl.text, _category);
    final myEvents = eventProv.userRsvpdEvents(user.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Events'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(text: 'Upcoming'),
            Tab(text: 'My RSVPs (${myEvents.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search events...',
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
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: MockData.eventCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = MockData.eventCategories[i];
                      final selected = _category == cat;
                      return FilterChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) => setState(() => _category = cat),
                        labelStyle: TextStyle(
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                        selectedColor: const Color(0x1F1565C0),
                        checkmarkColor: AppColors.primary,
                        showCheckmark: false,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildEventList(context, allEvents, user.id, eventProv, auth),
                _buildEventList(context, myEvents, user.id, eventProv, auth, emptyMsg: 'No RSVPs yet'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(
    BuildContext context,
    List events,
    String userId,
    EventProvider eventProv,
    AuthProvider auth, {
    String emptyMsg = 'No events found',
  }) {
    if (events.isEmpty) {
      return EmptyStateWidget(
        emoji: '📅',
        title: emptyMsg,
        subtitle: _tabCtrl.index == 1
            ? 'RSVP for events to see them here'
            : 'Try a different filter or check back soon',
      );
    }

    // Group by month
    final grouped = <String, List>{};
    for (final e in events) {
      final key = DateFormat('MMMM yyyy').format(e.date as DateTime);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: grouped.entries.expand((entry) {
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              entry.key,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5),
            ),
          ),
          ...entry.value.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EventCard(
              event: e,
              currentUserId: userId,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: e.id))),
              onRsvp: () {
                if (e.isRsvpd(userId)) {
                  eventProv.cancelRsvp(e.id, userId);
                  auth.removeRsvp(e.id);
                } else {
                  eventProv.rsvpEvent(e.id, userId);
                  auth.addRsvp(e.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('RSVP confirmed! +50 points 🎉'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          )),
        ];
      }).toList(),
    );
  }
}

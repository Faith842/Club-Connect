import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/mock_data.dart';
import '../../widgets/club_card.dart';
import '../../widgets/empty_state_widget.dart';
import 'club_detail_screen.dart';
import 'create_edit_club_screen.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> with SingleTickerProviderStateMixin {
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
    final clubProv = context.watch<ClubProvider>();
    final user = auth.currentUser!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clubs'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Discover'),
            Tab(text: 'My Clubs'),
          ],
        ),
      ),
      floatingActionButton: auth.isLeader
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEditClubScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New Club'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search clubs...',
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
                    itemCount: MockData.clubCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = MockData.clubCategories[i];
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
                _DiscoverTab(
                  clubs: clubProv.search(_searchCtrl.text, _category),
                  userId: user.id,
                  isLeader: auth.isLeader,
                ),
                _MyClubsTab(
                  clubs: clubProv.myClubs(user.id),
                  userId: user.id,
                  isLeader: auth.isLeader,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverTab extends StatelessWidget {
  final List clubs;
  final String userId;
  final bool isLeader;
  const _DiscoverTab({required this.clubs, required this.userId, required this.isLeader});

  @override
  Widget build(BuildContext context) {
    if (clubs.isEmpty) {
      return const EmptyStateWidget(
        emoji: '🔍',
        title: 'No clubs found',
        subtitle: 'Try a different search term or category',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: clubs.length,
      itemBuilder: (context, i) {
        final club = clubs[i];
        return ClubCard(
          club: club,
          currentUserId: userId,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: club.id)),
          ),
          onJoin: isLeader
              ? null
              : () {
                  final auth = context.read<AuthProvider>();
                  context.read<ClubProvider>().requestJoin(club.id, auth.currentUser!);
                },
        );
      },
    );
  }
}

class _MyClubsTab extends StatelessWidget {
  final List clubs;
  final String userId;
  final bool isLeader;
  const _MyClubsTab({required this.clubs, required this.userId, required this.isLeader});

  @override
  Widget build(BuildContext context) {
    if (clubs.isEmpty) {
      return EmptyStateWidget(
        emoji: '🏛️',
        title: isLeader ? 'No clubs created yet' : 'You haven\'t joined any clubs',
        subtitle: isLeader
            ? 'Tap the + button to create your first club'
            : 'Go to Discover and request to join a club',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: clubs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final club = clubs[i];
        return ClubCard(
          club: club,
          currentUserId: userId,
          showJoinButton: false,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: club.id)),
          ),
        );
      },
    );
  }
}

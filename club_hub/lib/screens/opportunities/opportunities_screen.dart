import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/opportunity.dart';
import '../../utils/mock_data.dart';
import '../../widgets/opportunity_card.dart';
import '../../widgets/empty_state_widget.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'All';
  late List<Opportunity> _opps;

  static const _types = ['All', 'Scholarship', 'Internship', 'Grant', 'Competition', 'Fellowship', 'Ambassador Role'];

  @override
  void initState() {
    super.initState();
    _opps = MockData.getOpportunities();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Opportunity> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    return _opps.where((o) {
      final matchQ = q.isEmpty || o.title.toLowerCase().contains(q) || o.organization.toLowerCase().contains(q);
      final matchType = _filter == 'All' || o.type == _filter;
      return matchQ && matchType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final bookmarked = _opps.where((o) => o.isBookmarked).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Opportunities')),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search scholarships, internships...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white54),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = _types[i];
                  final selected = _filter == t;
                  return FilterChip(
                    label: Text(t),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = t),
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
          ),
          if (bookmarked.isNotEmpty && _filter == 'All' && _searchCtrl.text.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.bookmark, size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text('${bookmarked.length} bookmarked', style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyStateWidget(
                    emoji: '🔍',
                    title: 'No opportunities found',
                    subtitle: 'Try a different search term or category',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final opp = filtered[i];
                      return OpportunityCard(
                        opp: opp,
                        onBookmark: () {
                          setState(() => opp.isBookmarked = !opp.isBookmarked);
                          if (opp.isBookmarked) {
                            context.read<AuthProvider>().addBadge('scholar');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bookmarked! Scholar badge earned 📚'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        onApply: () => _showApplyDialog(context, opp),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showApplyDialog(BuildContext context, Opportunity opp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(opp.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Organization: ${opp.organization}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (opp.deadline != null)
              Text('Deadline: ${opp.deadline}', style: const TextStyle(color: AppColors.warning)),
            const SizedBox(height: 8),
            Text('Eligibility: ${opp.eligibility}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      opp.applicationLink,
                      style: const TextStyle(fontSize: 12, color: AppColors.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().addBadge('scholar');
              context.read<AuthProvider>().addPoints(25);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application link copied! Good luck 🌟 +25 pts'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Apply Now'),
          ),
        ],
      ),
    );
  }
}

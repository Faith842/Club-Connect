import 'package:flutter/material.dart';
import '../models/opportunity.dart';
import '../theme/app_theme.dart';

class OpportunityCard extends StatelessWidget {
  final Opportunity opp;
  final VoidCallback? onBookmark;
  final VoidCallback? onApply;

  const OpportunityCard({
    super.key,
    required this.opp,
    this.onBookmark,
    this.onApply,
  });

  Color get _color {
    try {
      final hex = opp.colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Color get _typeColor {
    switch (opp.type) {
      case 'Scholarship':
        return const Color(0xFF1565C0);
      case 'Internship':
        return const Color(0xFF00838F);
      case 'Grant':
        return const Color(0xFFFF6D00);
      case 'Competition':
        return const Color(0xFF6A1B9A);
      case 'Fellowship':
        return const Color(0xFF2E7D32);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(opp.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              opp.type,
                              style: TextStyle(
                                fontSize: 10,
                                color: _typeColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: onBookmark,
                            child: Icon(
                              opp.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: opp.isBookmarked ? AppColors.accent : AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opp.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        opp.organization,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              opp.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.people_outline, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    opp.eligibility,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (opp.deadline != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 13, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${opp.deadline}',
                    style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onApply,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _color,
                      side: BorderSide(color: _color),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Learn More & Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

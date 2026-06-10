import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final String? currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onRsvp;
  final bool compact;

  const EventCard({
    super.key,
    required this.event,
    this.currentUserId,
    this.onTap,
    this.onRsvp,
    this.compact = false,
  });

  Color get _color {
    try {
      final hex = event.colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRsvpd = currentUserId != null && event.isRsvpd(currentUserId!);
    final dateStr = DateFormat('MMM d').format(event.date);
    final dayStr = DateFormat('EEE').format(event.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 68,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(event.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    dayStr,
                    style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: _color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isRsvpd)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Going',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(event.time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            event.location,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _formatBadge(event.format),
                          const SizedBox(width: 6),
                          Text(
                            '${event.rsvpCount} going${event.maxAttendees > 0 ? ' · ${event.spotsLeft} spots left' : ''}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          if (onRsvp != null)
                            GestureDetector(
                              onTap: onRsvp,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isRsvpd ? Colors.white : _color,
                                  border: isRsvpd ? Border.all(color: _color) : null,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isRsvpd ? 'Cancel' : 'RSVP',
                                  style: TextStyle(
                                    color: isRsvpd ? _color : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formatBadge(String format) {
    Color c;
    switch (format) {
      case 'Virtual':
        c = const Color(0xFF6A1B9A);
        break;
      case 'Hybrid':
        c = const Color(0xFF00838F);
        break;
      default:
        c = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        format,
        style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}

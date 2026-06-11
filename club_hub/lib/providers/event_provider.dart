
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../utils/mock_data.dart';

class EventProvider extends ChangeNotifier {
  final List<Event> _events = MockData.getEvents();
  final _uuid = const Uuid();

  List<Event> get events => List.unmodifiable(_events);

  List<Event> get upcomingEvents {
    final now = DateTime.now();
    return [..._events]
      ..removeWhere((e) => e.date.isBefore(now.subtract(const Duration(days: 1))))
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Event> clubEvents(String clubId) =>
      _events.where((e) => e.clubId == clubId).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<Event> userRsvpdEvents(String userId) =>
      _events.where((e) => e.isRsvpd(userId)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<Event> search(String query, String category) {
    return _events.where((e) {
      final matchQuery = query.isEmpty ||
          e.title.toLowerCase().contains(query.toLowerCase()) ||
          e.clubName.toLowerCase().contains(query.toLowerCase());
      final matchCategory = category == 'All' || e.category == category;
      return matchQuery && matchCategory;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Event? findById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void createEvent(Event event) {
    _events.add(event);
    notifyListeners();
  }

  void updateEvent(Event updated) {
    final idx = _events.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _events[idx] = updated;
      notifyListeners();
    }
  }

  void deleteEvent(String eventId) {
    _events.removeWhere((e) => e.id == eventId);
    notifyListeners();
  }

  void rsvpEvent(String eventId, String userId) {
    final event = findById(eventId);
    if (event == null || event.isFull) return;
    if (!event.rsvpdUserIds.contains(userId)) {
      event.rsvpdUserIds.add(userId);
      notifyListeners();
    }
  }

  void cancelRsvp(String eventId, String userId) {
    final event = findById(eventId);
    if (event == null) return;
    event.rsvpdUserIds.remove(userId);
    notifyListeners();
  }

  String generateId() => _uuid.v4();
}
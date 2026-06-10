import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../utils/mock_data.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _hasSeenOnboarding = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isLeader => _currentUser?.isLeader ?? false;
  String? get error => _error;

  AuthProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    if (email.trim().toLowerCase() == 'student@alu.edu' && password == 'demo123') {
      _currentUser = MockData.studentUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } else if (email.trim().toLowerCase() == 'leader@alu.edu' && password == 'demo123') {
      _currentUser = MockData.leaderUser;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _error = 'Invalid email or password. Use the demo credentials below.';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void addPoints(int pts) {
    if (_currentUser == null) return;
    _currentUser!.points += pts;
    notifyListeners();
  }

  void addBadge(String badge) {
    if (_currentUser == null) return;
    if (!_currentUser!.badges.contains(badge)) {
      _currentUser!.badges.add(badge);
      notifyListeners();
    }
  }

  void addRsvp(String eventId) {
    if (_currentUser == null) return;
    if (!_currentUser!.rsvpdEventIds.contains(eventId)) {
      _currentUser!.rsvpdEventIds.add(eventId);
      addPoints(50);
      if (_currentUser!.rsvpdEventIds.length == 1) addBadge('early_bird');
      if (_currentUser!.rsvpdEventIds.length >= 5) addBadge('networker');
    }
    notifyListeners();
  }

  void removeRsvp(String eventId) {
    if (_currentUser == null) return;
    _currentUser!.rsvpdEventIds.remove(eventId);
    _currentUser!.points = (_currentUser!.points - 50).clamp(0, 99999);
    notifyListeners();
  }

  void addJoinedClub(String clubId) {
    if (_currentUser == null) return;
    if (!_currentUser!.joinedClubIds.contains(clubId)) {
      _currentUser!.joinedClubIds.add(clubId);
      addPoints(100);
      if (_currentUser!.joinedClubIds.length >= 3) addBadge('community_builder');
    }
    notifyListeners();
  }

  void removeJoinedClub(String clubId) {
    if (_currentUser == null) return;
    _currentUser!.joinedClubIds.remove(clubId);
    notifyListeners();
  }

  void updateProfile({String? name, String? avatar, String? major}) {
    if (_currentUser == null) return;
    if (name != null) _currentUser!.name = name;
    if (avatar != null) _currentUser!.avatar = avatar;
    if (major != null) _currentUser!.major = major;
    notifyListeners();
  }
}

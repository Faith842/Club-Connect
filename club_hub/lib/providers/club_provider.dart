import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/club.dart';
import '../models/membership_request.dart';
import '../models/app_user.dart';
import '../utils/mock_data.dart';

class ClubProvider extends ChangeNotifier {
  final List<Club> _clubs = MockData.getClubs();
  final List<MembershipRequest> _requests = [];
  final _uuid = const Uuid();

  List<Club> get clubs => List.unmodifiable(_clubs);

  List<Club> myClubs(String userId) =>
      _clubs.where((c) => c.isMember(userId) || c.leaderId == userId).toList();

  List<Club> leaderClubs(String leaderId) =>
      _clubs.where((c) => c.leaderId == leaderId).toList();

  Club? findById(String id) {
    try {
      return _clubs.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Club> search(String query, String category) {
    return _clubs.where((c) {
      final matchQuery = query.isEmpty ||
          c.name.toLowerCase().contains(query.toLowerCase()) ||
          c.description.toLowerCase().contains(query.toLowerCase());
      final matchCategory = category == 'All' || c.category == category;
      return matchQuery && matchCategory;
    }).toList();
  }

  void createClub(Club club) {
    _clubs.add(club);
    notifyListeners();
  }

  void updateClub(Club updated) {
    final idx = _clubs.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _clubs[idx] = updated;
      notifyListeners();
    }
  }

  void deleteClub(String clubId) {
    _clubs.removeWhere((c) => c.id == clubId);
    notifyListeners();
  }

  void requestJoin(String clubId, AppUser user) {
    final club = findById(clubId);
    if (club == null) return;
    if (club.isMember(user.id) || club.isPending(user.id)) return;

    club.pendingMemberIds.add(user.id);

    final existing = _requests.where(
      (r) => r.clubId == clubId && r.userId == user.id,
    );
    if (existing.isEmpty) {
      _requests.add(MembershipRequest(
        id: _uuid.v4(),
        clubId: clubId,
        userId: user.id,
        userName: user.name,
        userAvatar: user.avatar,
        userMajor: user.major,
        userCohort: user.cohort,
        requestedAt: DateTime.now(),
      ));
    }
    notifyListeners();
  }

  void cancelRequest(String clubId, String userId) {
    final club = findById(clubId);
    if (club == null) return;
    club.pendingMemberIds.remove(userId);
    _requests.removeWhere((r) => r.clubId == clubId && r.userId == userId);
    notifyListeners();
  }

  void approveMembership(String requestId, AuthCallback? onApproved) {
    final req = _requests.firstWhere((r) => r.id == requestId, orElse: () => throw StateError(''));
    final club = findById(req.clubId);
    if (club == null) return;

    req.status = 'approved';
    club.pendingMemberIds.remove(req.userId);
    if (!club.memberIds.contains(req.userId)) {
      club.memberIds.add(req.userId);
    }
    onApproved?.call(req.userId, req.clubId);
    notifyListeners();
  }

  void rejectMembership(String requestId) {
    final req = _requests.firstWhere((r) => r.id == requestId, orElse: () => throw StateError(''));
    final club = findById(req.clubId);
    if (club == null) return;

    req.status = 'rejected';
    club.pendingMemberIds.remove(req.userId);
    notifyListeners();
  }

  void removeMember(String clubId, String userId) {
    final club = findById(clubId);
    if (club == null) return;
    club.memberIds.remove(userId);
    notifyListeners();
  }

  void leaveClub(String clubId, String userId) {
    final club = findById(clubId);
    if (club == null) return;
    club.memberIds.remove(userId);
    club.pendingMemberIds.remove(userId);
    notifyListeners();
  }

  List<MembershipRequest> pendingRequests(String clubId) =>
      _requests.where((r) => r.clubId == clubId && r.status == 'pending').toList();

  List<MembershipRequest> allRequests(String clubId) =>
      _requests.where((r) => r.clubId == clubId).toList();

  MembershipRequest? userRequest(String clubId, String userId) {
    try {
      return _requests.lastWhere((r) => r.clubId == clubId && r.userId == userId);
    } catch (_) {
      return null;
    }
  }

  int totalPendingForLeader(String leaderId) {
    final leaderClubIds = leaderClubs(leaderId).map((c) => c.id).toSet();
    return _requests
        .where((r) => leaderClubIds.contains(r.clubId) && r.status == 'pending')
        .length;
  }
}

typedef AuthCallback = void Function(String userId, String clubId);

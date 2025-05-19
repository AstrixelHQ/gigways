import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';

part 'tracking_repository.g.dart';

/// Repository for managing tracking sessions in Firestore
class TrackingRepository {
  final FirebaseFirestore _firestore;

  TrackingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference for tracking sessions
  CollectionReference<Map<String, dynamic>> _userSessionsCollection(
      String userId) {
    return _firestore.collection('users/$userId/tracking_sessions');
  }

  // Start a new tracking session
  Future<TrackingSession> startSession({
    required String userId,
    required LocationPoint initialLocation,
  }) async {
    // Check if there's an active session
    final activeSession = await getActiveSession(userId);
    if (activeSession != null) {
      // End the active session first
      await endSession(
        userId: userId,
        sessionId: activeSession.id,
        endTime: DateTime.now(),
        skipEarningsEntry: true,
      );
    }

    // Create a new session
    final session = TrackingSession.start(
      userId: userId,
      startTime: DateTime.now(),
      initialLocation: initialLocation,
    );

    // Save to Firestore
    await _userSessionsCollection(userId).doc(session.id).set(session.toMap());

    return session;
  }

  // Update session with new location and distance
  Future<TrackingSession> updateSession({
    required String userId,
    required String sessionId,
    required LocationPoint newLocation,
    required double miles,
    required int durationInSeconds,
  }) async {
    // Get the current session
    final docRef = _userSessionsCollection(userId).doc(sessionId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Tracking session not found');
    }

    // Get current session data
    final session = TrackingSession.fromMap(doc.data()!);

    // Add new location to the list
    final updatedLocations = List<LocationPoint>.from(session.locations)
      ..add(newLocation);

    // Create updated session
    final updatedSession = session.copyWith(
      miles: miles,
      durationInSeconds: durationInSeconds,
      locations: updatedLocations,
    );

    // Update Firestore
    await docRef.update({
      'miles': miles,
      'durationInSeconds': durationInSeconds,
      'locations': updatedLocations.map((loc) => loc.toMap()).toList(),
    });

    return updatedSession;
  }

  // End a tracking session
  Future<TrackingSession> endSession({
    required String userId,
    required String sessionId,
    required DateTime endTime,
    double? earnings,
    double? expenses,
    bool skipEarningsEntry = false,
  }) async {
    // Get the current session
    final docRef = _userSessionsCollection(userId).doc(sessionId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Tracking session not found');
    }

    // Get current session data
    final session = TrackingSession.fromMap(doc.data()!);

    // Create updated session with end time
    final updatedSession = session.copyWith(
      endTime: endTime,
      isActive: false,
      earnings: earnings,
      expenses: expenses,
    );

    // Update Firestore
    await docRef.update({
      'endTime': Timestamp.fromDate(endTime),
      'isActive': false,
      if (earnings != null) 'earnings': earnings,
      if (expenses != null) 'expenses': expenses,
    });

    return updatedSession;
  }

  // Get currently active session
  Future<TrackingSession?> getActiveSession(String userId) async {
    final querySnapshot = await _userSessionsCollection(userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return TrackingSession.fromMap(querySnapshot.docs.first.data());
  }

  // Get sessions for a specific time range
  Future<List<TrackingSession>> getSessionsForTimeRange({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final querySnapshot = await _userSessionsCollection(userId)
        .where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endTime))
        .orderBy('startTime', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => TrackingSession.fromMap(doc.data()))
        .toList();
  }

  // Get sessions for today
  Future<List<TrackingSession>> getSessionsForToday(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getSessionsForTimeRange(
      userId: userId,
      startTime: startOfDay,
      endTime: endOfDay,
    );
  }

  // Get sessions for this week
  Future<List<TrackingSession>> getSessionsForWeek(String userId) async {
    final now = DateTime.now();
    // Get the start of the week (Sunday)
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    return getSessionsForTimeRange(
      userId: userId,
      startTime: startOfWeek,
      endTime: endOfWeek,
    );
  }

  // Get sessions for this month
  Future<List<TrackingSession>> getSessionsForMonth(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return getSessionsForTimeRange(
      userId: userId,
      startTime: startOfMonth,
      endTime: endOfMonth,
    );
  }

  // Get sessions for this year
  Future<List<TrackingSession>> getSessionsForYear(String userId) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    return getSessionsForTimeRange(
      userId: userId,
      startTime: startOfYear,
      endTime: endOfYear,
    );
  }

  // Delete a tracking session
  Future<void> deleteSession(
      {required String userId, required String sessionId}) async {
    await _userSessionsCollection(userId).doc(sessionId).delete();
  }
}

@Riverpod(keepAlive: true)
TrackingRepository trackingRepository(Ref ref) {
  return TrackingRepository();
}

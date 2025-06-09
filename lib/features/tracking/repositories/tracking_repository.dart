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
    try {
      final querySnapshot = await _userSessionsCollection(userId)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endTime))
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TrackingSession.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // Handle error
      print('Error fetching sessions: $e');
      return [];
    }
  }

  // Get sessions for today
  Future<List<TrackingSession>> getSessionsForToday(String userId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    return getSessionsForTimeRange(
      userId: userId,
      startTime: start,
      endTime: end,
    );
  }

  // Delete a tracking session
  Future<void> deleteSession(
      {required String userId, required String sessionId}) async {
    await _userSessionsCollection(userId).doc(sessionId).delete();
  }

  // Update session data (miles, durationInSeconds, earnings, expenses)
  Future<TrackingSession> updateSessionData({
    required String userId,
    required String sessionId,
    double? miles,
    int? durationInSeconds,
    double? earnings,
    double? expenses,
  }) async {
    // Get the current session
    final docRef = _userSessionsCollection(userId).doc(sessionId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Tracking session not found');
    }

    // Get current session data
    final session = TrackingSession.fromMap(doc.data()!);

    // Create updated session
    final updatedSession = session.copyWith(
      miles: miles ?? session.miles,
      durationInSeconds: durationInSeconds ?? session.durationInSeconds,
      earnings: earnings ?? session.earnings,
      expenses: expenses ?? session.expenses,
    );

    // Update Firestore
    await docRef.update({
      if (miles != null) 'miles': miles,
      if (durationInSeconds != null) 'durationInSeconds': durationInSeconds,
      if (earnings != null) 'earnings': earnings,
      if (expenses != null) 'expenses': expenses,
    });

    return updatedSession;
  }

  Future<List<TrackingSession>> getAllActiveSessions(String userId) async {
    final querySnapshot = await _userSessionsCollection(userId)
        .where('isActive', isEqualTo: true)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    return querySnapshot.docs
        .map((doc) => TrackingSession.fromMap(doc.data()))
        .toList();
  }

// Add this method to TrackingRepository class
  Future<void> endAllActiveSessions(
    String userId, {
    DateTime? endTime,
    double? earnings,
    double? expenses,
  }) async {
    final activeSessions = await getAllActiveSessions(userId);

    if (activeSessions.isEmpty) {
      return;
    }

    // End all active sessions - use the provided endTime for all
    final now = endTime ?? DateTime.now();

    // For multiple sessions, we'll distribute earnings/expenses proportionally
    // based on session duration if they're provided
    final bool distributeFinancials = earnings != null || expenses != null;
    final double totalDuration = activeSessions
        .fold(0, (sum, session) => sum + session.durationInSeconds)
        .toDouble();

    for (final session in activeSessions) {
      final sessionId = session.id;
      final docRef = _userSessionsCollection(userId).doc(sessionId);

      double? sessionEarnings;
      double? sessionExpenses;

      // If we need to distribute financials, calculate each session's portion
      if (distributeFinancials && totalDuration > 0) {
        final ratio = session.durationInSeconds / totalDuration;
        sessionEarnings = earnings != null ? earnings * ratio : null;
        sessionExpenses = expenses != null ? expenses * ratio : null;
      } else if (activeSessions.length == 1) {
        // If there's only one session, assign all earnings/expenses to it
        sessionEarnings = earnings;
        sessionExpenses = expenses;
      }

      // Update Firestore
      await docRef.update({
        'endTime': Timestamp.fromDate(now),
        'isActive': false,
        if (sessionEarnings != null) 'earnings': sessionEarnings,
        if (sessionExpenses != null) 'expenses': sessionExpenses,
      });
    }
  }
}

@Riverpod(keepAlive: true)
TrackingRepository trackingRepository(Ref ref) {
  return TrackingRepository();
}

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
    print('TrackingRepository: Ending session $sessionId for user $userId');
    print('TrackingRepository: skipEarningsEntry = $skipEarningsEntry');
    
    // Get the current session
    final docRef = _userSessionsCollection(userId).doc(sessionId);
    final doc = await docRef.get();

    if (!doc.exists) {
      print('TrackingRepository: Session $sessionId not found in Firestore');
      throw Exception('Tracking session not found');
    }

    // Get current session data
    final session = TrackingSession.fromMap(doc.data()!);
    print('TrackingRepository: Current session data - miles: ${session.miles}, duration: ${session.durationInSeconds}s, isActive: ${session.isActive}');

    // Create updated session with end time
    final updatedSession = session.copyWith(
      endTime: endTime,
      isActive: false,
      earnings: earnings,
      expenses: expenses,
    );

    // Prepare update data
    final updateData = {
      'endTime': Timestamp.fromDate(endTime),
      'isActive': false,
    };
    
    // Only add earnings/expenses if provided (not when skipping)
    if (!skipEarningsEntry) {
      if (earnings != null) updateData['earnings'] = earnings;
      if (expenses != null) updateData['expenses'] = expenses;
    }
    
    print('TrackingRepository: Updating Firestore with data: $updateData');

    // Update Firestore
    await docRef.update(updateData);
    
    print('TrackingRepository: Session $sessionId successfully ended');

    return updatedSession;
  }

  // Get currently active session
  Future<TrackingSession?> getActiveSession(String userId) async {
    print('TrackingRepository: Checking for active sessions for user $userId');
    final querySnapshot = await _userSessionsCollection(userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    print('TrackingRepository: Found ${querySnapshot.docs.length} active sessions');
    
    if (querySnapshot.docs.isEmpty) {
      print('TrackingRepository: No active sessions found');
      return null;
    }

    final sessionData = querySnapshot.docs.first.data();
    print('TrackingRepository: Found active session with ID: ${sessionData['id']}, isActive: ${sessionData['isActive']}');
    
    return TrackingSession.fromMap(sessionData);
  }

  // Get sessions for a specific time range with pagination
  Future<List<TrackingSession>> getSessionsForTimeRange({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    int? limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      var query = _userSessionsCollection(userId)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endTime))
          .orderBy('startTime', descending: true);
      
      // Add pagination if provided
      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => TrackingSession.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // Handle error
      print('Error fetching sessions: $e');
      return [];
    }
  }

  // Get sessions with cursor-based pagination for cost efficiency
  Future<({List<TrackingSession> sessions, DocumentSnapshot? lastDoc, bool hasMore})> getSessionsPaginated({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _userSessionsCollection(userId)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endTime))
          .orderBy('startTime', descending: true)
          .limit(limit + 1); // Get one extra to check if there are more
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      final docs = querySnapshot.docs;
      
      // Check if there are more documents
      final hasMore = docs.length > limit;
      final sessionsToReturn = hasMore ? docs.take(limit).toList() : docs;
      
      final sessions = sessionsToReturn
          .map((doc) => TrackingSession.fromMap(doc.data()))
          .toList();
      
      final lastDoc = sessionsToReturn.isNotEmpty ? sessionsToReturn.last : null;
      
      return (sessions: sessions, lastDoc: lastDoc, hasMore: hasMore);
    } catch (e) {
      print('Error fetching paginated sessions: $e');
      return (sessions: <TrackingSession>[], lastDoc: null, hasMore: false);
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
    print('TrackingRepository: Ending all active sessions for user $userId');
    final activeSessions = await getAllActiveSessions(userId);

    print('TrackingRepository: Found ${activeSessions.length} active sessions to end');
    if (activeSessions.isEmpty) {
      print('TrackingRepository: No active sessions to end');
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
      
      print('TrackingRepository: Ending session $sessionId');

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
      final updateData = {
        'endTime': Timestamp.fromDate(now),
        'isActive': false,
      };
      
      if (sessionEarnings != null) updateData['earnings'] = sessionEarnings;
      if (sessionExpenses != null) updateData['expenses'] = sessionExpenses;
      
      print('TrackingRepository: Updating session $sessionId with: $updateData');
      await docRef.update(updateData);
    }
    
    print('TrackingRepository: All active sessions ended successfully');
  }
}

@Riverpod(keepAlive: true)
TrackingRepository trackingRepository(Ref ref) {
  return TrackingRepository();
}

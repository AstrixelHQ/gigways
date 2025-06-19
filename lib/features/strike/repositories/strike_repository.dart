// lib/features/strike/repositories/strike_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/features/strike/models/strike_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'strike_repository.g.dart';

class StrikeRepository {
  final FirebaseFirestore _firestore;

  StrikeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Reference to the strikes collection
  CollectionReference<Map<String, dynamic>> get _strikesCollection =>
      _firestore.collection('strikes');

  // Create a new strike
  Future<String> createStrike({
    required String userId,
    required DateTime date,
    required String state,
    String? userName,
  }) async {
    // Format date string
    final dateString = StrikeModel.formatDateString(date);

    // Create the strike document
    final strikeData = StrikeModel(
      id: '', // Will be set after creation
      userId: userId,
      dateString: dateString,
      date: date,
      state: state,
      createdAt: DateTime.now(),
      userName: userName,
    );

    final docRef = await _strikesCollection.add(strikeData.toFirestore());
    return docRef.id;
  }

  // Get user's scheduled strike (if any)
  Future<StrikeModel?> getUserStrike(String userId) async {
    try {
      final now = DateTime.now();
      final todayString = StrikeModel.formatDateString(now);

      // Optimized query: only fetch strikes for today or future dates
      final querySnap = await _strikesCollection
          .where('userId', isEqualTo: userId)
          .where('dateString', isGreaterThanOrEqualTo: todayString)
          .limit(1) // Only need one active strike
          .get();

      if (querySnap.docs.isEmpty) {
        return null;
      }

      // Return the first (and should be only) strike
      return StrikeModel.fromFirestore(querySnap.docs.first);
    } catch (e) {
      print('Error fetching user strike: $e');
      return null; // Return null if there's an error
    }
  }

  // Get strike count for a specific date
  Future<StrikeCountResult> getStrikeCountForDate(
      DateTime date, String userState) async {
    final dateString = StrikeModel.formatDateString(date);

    try {
      // Get count for the specific date (nationwide)
      final totalCountQuery = await _strikesCollection
          .where('dateString', isEqualTo: dateString)
          .count()
          .get();

      // Get count for the user's state
      final stateCountQuery = await _strikesCollection
          .where('dateString', isEqualTo: dateString)
          .where('state', isEqualTo: userState)
          .count()
          .get();

      return StrikeCountResult(
        date: date,
        dateString: dateString,
        totalCount: totalCountQuery.count ?? 0,
        stateCount: stateCountQuery.count ?? 0,
      );
    } catch (e) {
      // Fallback if count() method is not supported
      final querySnap = await _strikesCollection
          .where('dateString', isEqualTo: dateString)
          .get();

      // Calculate the counts manually
      final totalCount = querySnap.docs.length;
      final stateCount = querySnap.docs
          .where((doc) => (doc.data()['state'] as String?) == userState)
          .length;

      return StrikeCountResult(
        date: date,
        dateString: dateString,
        totalCount: totalCount,
        stateCount: stateCount,
      );
    }
  }

  // Get the most popular upcoming strike date
  Future<StrikeCountResult?> getMostPopularUpcomingStrikeDate(
      String userState) async {
    final now = DateTime.now();
    final todayString = StrikeModel.formatDateString(now);

    try {
      // Get upcoming strikes
      final querySnap = await _strikesCollection
          .where('dateString', isGreaterThanOrEqualTo: todayString)
          .limit(50)
          .get();

      if (querySnap.docs.isEmpty) {
        // Return a universal default date (7 days from now) if no popular dates exist
        final universalDate = DateTime(now.year, now.month, now.day + 7);
        return StrikeCountResult(
          date: universalDate,
          dateString: StrikeModel.formatDateString(universalDate),
          totalCount: 0,
          stateCount: 0,
        );
      }

      // Group documents by date
      final Map<String, List<DocumentSnapshot>> strikesByDate = {};

      for (final doc in querySnap.docs) {
        final dateString = doc.data()['dateString'] as String;

        if (!strikesByDate.containsKey(dateString)) {
          strikesByDate[dateString] = [];
        }

        strikesByDate[dateString]!.add(doc);
      }

      // Find the date with most strikes
      String? mostPopularDateKey;
      int maxStrikes = 0;

      strikesByDate.forEach((dateKey, strikes) {
        if (strikes.length > maxStrikes) {
          maxStrikes = strikes.length;
          mostPopularDateKey = dateKey;
        }
      });

      if (mostPopularDateKey == null) {
        // Return a universal default date (7 days from now) if no popular dates exist
        final universalDate = DateTime(now.year, now.month, now.day + 7);
        return StrikeCountResult(
          date: universalDate,
          dateString: StrikeModel.formatDateString(universalDate),
          totalCount: 0,
          stateCount: 0,
        );
      }

      // Parse the date
      final parts = mostPopularDateKey!.split('-');
      final popularDate = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      // Calculate state count for this date
      final stateCount = strikesByDate[mostPopularDateKey]!
          .where((doc) =>
              (doc.data() as Map<String, dynamic>)['state'] == userState)
          .length;

      return StrikeCountResult(
        date: popularDate,
        dateString: mostPopularDateKey!,
        totalCount: maxStrikes,
        stateCount: stateCount,
      );
    } catch (e) {
      print('Error getting most popular strike date: $e');
      // Return a universal default date (7 days from now) on error
      final universalDate = DateTime(now.year, now.month, now.day + 7);
      return StrikeCountResult(
        date: universalDate,
        dateString: StrikeModel.formatDateString(universalDate),
        totalCount: 0,
        stateCount: 0,
      );
    }
  }

  // Get strike counts for the next few days
  Future<List<StrikeCountResult>> getUpcomingStrikeCounts(String userState,
      {int daysToFetch = 3}) async {
    final results = <StrikeCountResult>[];
    final now = DateTime.now();

    for (int i = 0; i < daysToFetch; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      final result = await getStrikeCountForDate(date, userState);
      results.add(result);
    }

    // Sort by total count (most popular first)
    results.sort((a, b) => b.totalCount.compareTo(a.totalCount));
    return results;
  }

  // Get total number of users in the system
  Future<int> getTotalUserCount() async {
    try {
      final userCount = await _firestore.collection('users').count().get();
      return userCount.count ?? 0;
    } catch (e) {
      // Fallback
      final usersSnapshot = await _firestore.collection('users').get();
      return usersSnapshot.docs.length > 0
          ? usersSnapshot.docs.length
          : 100; // Default to 100 if empty
    }
  }

  // Get number of users in a specific state
  Future<int> getStateUserCount(String state) async {
    try {
      final stateUserCount = await _firestore
          .collection('users')
          .where('state', isEqualTo: state)
          .count()
          .get();
      return stateUserCount.count ?? 0;
    } catch (e) {
      // Fallback
      final stateUsersSnapshot = await _firestore
          .collection('users')
          .where('state', isEqualTo: state)
          .get();
      return stateUsersSnapshot.docs.length > 0
          ? stateUsersSnapshot.docs.length
          : 10; // Default to 10 if empty
    }
  }

  Future<void> cancelStrike({
    required String userId,
    required String strikeId,
  }) async {
    try {
      print('Attempting to cancel strike with ID: $strikeId');

      // Check if document exists before attempting to delete
      final docSnapshot =
          await _firestore.collection('strikes').doc(strikeId).get();
      if (!docSnapshot.exists) {
        print('Strike document does not exist: $strikeId');
        throw Exception('Strike document not found');
      }

      print('Strike document found, proceeding with deletion');
      await _firestore.collection('strikes').doc(strikeId).delete();
      print('Strike successfully deleted: $strikeId');
    } catch (e) {
      print('Error canceling strike: $e');
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
StrikeRepository strikeRepository(Ref ref) {
  return StrikeRepository();
}

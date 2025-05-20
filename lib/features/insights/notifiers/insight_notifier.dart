import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gigways/features/insights/models/insight_period.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';
import 'package:gigways/features/tracking/repositories/tracking_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'insight_notifier.g.dart';
part "insight_notifier.freezed.dart";

@freezed
class InsightState with _$InsightState {
  const factory InsightState.initial() = _Initial;
  const factory InsightState.loading() = _Loading;
  const factory InsightState.success({
    required List<TrackingSession> sessions,
    required TrackingInsights insights,
  }) = _Success;
  const factory InsightState.error(String message) = _Error;

  // maybewhen
  const InsightState._();

  // method of maybewhen
  bool get isLoading => this is _Loading;
  bool get isSuccess => this is _Success;
  bool get isError => this is _Error;
  bool get isInitial => this is _Initial;

  TrackingInsights? get insights =>
      this is _Success ? (this as _Success).insights : null;

  List<TrackingSession>? get sessions =>
      this is _Success ? (this as _Success).sessions : null;
}

@Riverpod(keepAlive: true)
class InsightNotifier extends _$InsightNotifier {
  @override
  InsightState build(InsightPeriod period) => const InsightState.initial();

  TrackingRepository get _repository => ref.read(trackingRepositoryProvider);

  Future<void> fetchInsights() async {
    state = const InsightState.loading();
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;
    try {
      if (period == InsightPeriod.today) {
        final startTime = DateTime.now().subtract(
          const Duration(days: 1),
        );
        final endTime = DateTime.now();
        final sessions = await _repository.getSessionsForTimeRange(
          endTime: endTime,
          startTime: startTime,
          userId: userId!,
        );
        final insights = extractInsights(sessions);

        state = InsightState.success(
          sessions: sessions,
          insights: insights,
        );
      } else if (period == InsightPeriod.monthly) {
        final startTime = DateTime.now().subtract(
          const Duration(days: 30),
        );
        final endTime = DateTime.now();
        final sessions = await _repository.getSessionsForTimeRange(
          endTime: endTime,
          startTime: startTime,
          userId: userId!,
        );
        final insights = extractInsights(sessions);

        state = InsightState.success(
          sessions: sessions,
          insights: insights,
        );
      } else if (period == InsightPeriod.weekly) {
        final startTime = DateTime.now().subtract(
          const Duration(days: 7),
        );
        final endTime = DateTime.now();
        final sessions = await _repository.getSessionsForTimeRange(
          endTime: endTime,
          startTime: startTime,
          userId: userId!,
        );
        final insights = extractInsights(sessions);

        state = InsightState.success(
          sessions: sessions,
          insights: insights,
        );
      } else if (period == InsightPeriod.yearly) {
        final startTime = DateTime.now().subtract(
          const Duration(days: 365),
        );
        final endTime = DateTime.now();
        final sessions = await _repository.getSessionsForTimeRange(
          endTime: endTime,
          startTime: startTime,
          userId: userId!,
        );
        final insights = extractInsights(sessions);

        state = InsightState.success(
          sessions: sessions,
          insights: insights,
        );
      } else {
        state = const InsightState.error("Invalid period");
      }
    } catch (e) {
      state = InsightState.error(e.toString());
    }
  }

  TrackingInsights extractInsights(
    List<TrackingSession> sessions,
  ) {
    return TrackingInsights(
      totalMiles: sessions.fold(
        0,
        (previousValue, element) => previousValue + element.miles,
      ),
      totalDurationInSeconds: sessions.fold(
        0,
        (previousValue, element) => previousValue + element.durationInSeconds,
      ),
      totalEarnings: sessions.fold(
        0,
        (previousValue, element) => previousValue + (element.earnings ?? 0),
      ),
      totalExpenses: sessions.fold(
        0,
        (previousValue, element) => previousValue + (element.expenses ?? 0),
      ),
      sessionCount: sessions.length,
    );
  }

  Future<void> updateInsight(
    TrackingSession session, {
    double? miles,
    int? durationInSeconds,
    double? earnings,
    double? expenses,
  }) async {
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      state = const InsightState.error('User not authenticated');
      return;
    }

    try {
      // First update the state immediately for responsive UI
      if (state is _Success) {
        final currentState = state as _Success;

        // Create updated session
        final updatedSession = session.copyWith(
          miles: miles ?? session.miles,
          durationInSeconds: durationInSeconds ?? session.durationInSeconds,
          earnings: earnings ?? session.earnings,
          expenses: expenses ?? session.expenses,
        );

        // Update session in state
        final sessions = currentState.sessions.map((s) {
          if (s.id == session.id) {
            return updatedSession;
          }
          return s;
        }).toList();

        // Recalculate insights
        final insights = extractInsights(sessions);

        // Update state immediately
        state = InsightState.success(
          sessions: sessions,
          insights: insights,
        );
      }

      // Then update Firestore (don't wait for this to complete before updating UI)
      _repository.updateSessionData(
        userId: userId,
        sessionId: session.id,
        miles: miles,
        durationInSeconds: durationInSeconds,
        earnings: earnings,
        expenses: expenses,
      );
    } catch (e) {
      state = InsightState.error(e.toString());
    }
  }

// Delete an insight from the state and Firestore
  Future<void> deleteInsight(TrackingSession session) async {
    final auth = FirebaseAuth.instance;
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      state = const InsightState.error('User not authenticated');
      return;
    }

    try {
      // First update state immediately for responsive UI
      if (state is _Success) {
        final currentState = state as _Success;

        // Remove session from state
        final sessions =
            currentState.sessions.where((s) => s.id != session.id).toList();

        // Recalculate insights
        final insights = extractInsights(sessions);

        // Update state immediately
        state = InsightState.success(
          sessions: sessions,
          insights: insights,
        );
      }

      // Then delete from Firestore (don't wait for this to complete before updating UI)
      _repository.deleteSession(
        userId: userId,
        sessionId: session.id,
      );
    } catch (e) {
      state = InsightState.error(e.toString());
    }
  }
}

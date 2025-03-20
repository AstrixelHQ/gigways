import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';
import 'package:gigways/features/tracking/repositories/tracking_repository.dart';
import 'package:gigways/features/tracking/services/location_service.dart';

part 'tracking_notifier.g.dart';

// Enum for tracking status
enum TrackingStatus {
  initial,
  loading,
  active,
  inactive,
  endingShift,
  error,
}

// Define tracking state
class TrackingState {
  final TrackingStatus status;
  final TrackingSession? activeSession;
  final String? errorMessage;
  final List<LocationPoint> currentLocations;
  final TrackingInsights? todayInsights;
  final TrackingInsights? weeklyInsights;
  final TrackingInsights? monthlyInsights;
  final TrackingInsights? yearlyInsights;
  final String selectedInsightPeriod;
  final int drivingNow; // Mock value to show in UI
  final int totalDrivers; // Mock value to show in UI

  TrackingState({
    this.status = TrackingStatus.initial,
    this.activeSession,
    this.errorMessage,
    this.currentLocations = const [],
    this.todayInsights,
    this.weeklyInsights,
    this.monthlyInsights, 
    this.yearlyInsights,
    this.selectedInsightPeriod = 'Today',
    this.drivingNow = 4000, // Default mock value
    this.totalDrivers = 70000, // Default mock value
  });

  TrackingState copyWith({
    TrackingStatus? status,
    TrackingSession? activeSession,
    String? errorMessage,
    List<LocationPoint>? currentLocations,
    TrackingInsights? todayInsights,
    TrackingInsights? weeklyInsights,
    TrackingInsights? monthlyInsights,
    TrackingInsights? yearlyInsights,
    String? selectedInsightPeriod,
    int? drivingNow,
    int? totalDrivers,
  }) {
    return TrackingState(
      status: status ?? this.status,
      activeSession: activeSession ?? this.activeSession,
      errorMessage: errorMessage ?? this.errorMessage,
      currentLocations: currentLocations ?? this.currentLocations,
      todayInsights: todayInsights ?? this.todayInsights,
      weeklyInsights: weeklyInsights ?? this.weeklyInsights,
      monthlyInsights: monthlyInsights ?? this.monthlyInsights,
      yearlyInsights: yearlyInsights ?? this.yearlyInsights,
      selectedInsightPeriod: selectedInsightPeriod ?? this.selectedInsightPeriod,
      drivingNow: drivingNow ?? this.drivingNow,
      totalDrivers: totalDrivers ?? this.totalDrivers,
    );
  }

  // Get currently selected insights based on period
  TrackingInsights? get selectedInsights {
    switch (selectedInsightPeriod) {
      case 'Today':
        return todayInsights;
      case 'Weekly':
        return weeklyInsights;
      case 'Monthly':
        return monthlyInsights;
      case 'Yearly':
        return yearlyInsights;
      default:
        return todayInsights;
    }
  }
}

@Riverpod(keepAlive: true)
class TrackingNotifier extends _$TrackingNotifier {
  Timer? _trackingTimer;
  StreamSubscription? _locationSubscription;
  DateTime? _trackingStartTime;
  List<LocationPoint> _locationPoints = [];

  TrackingRepository get _repository => ref.read(trackingRepositoryProvider);
  LocationService get _locationService => ref.read(locationServiceProvider);

  @override
  TrackingState build() {
    // Clean up resources when provider is disposed
    ref.onDispose(() {
      _trackingTimer?.cancel();
      _locationSubscription?.cancel();
    });

    // Initialize tracking state
    _initializeTrackingState();
    
    return TrackingState();
  }

  // Initialize tracking state
  Future<void> _initializeTrackingState() async {
    await SchedulerBinding.instance.endOfFrame;

    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) {
      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: 'User not authenticated',
      );
      return;
    }

    state = state.copyWith(status: TrackingStatus.loading);

    try {
      // Check for active session
      final userId = authState.user!.uid;
      final activeSession = await _repository.getActiveSession(userId);

      if (activeSession != null) {
        // If there's an active session, resume tracking
        await _resumeTracking(activeSession);
      }

      // Load insights
      await refreshInsights();

      state = state.copyWith(
        status: activeSession != null ? TrackingStatus.active : TrackingStatus.inactive,
        activeSession: activeSession,
      );
    } catch (e) {
      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Start tracking
  Future<void> startTracking() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) {
      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: 'User not authenticated',
      );
      return;
    }

    state = state.copyWith(status: TrackingStatus.loading);

    try {
      // Start location tracking
      final initialLocation = await _locationService.startTracking();
      if (initialLocation == null) {
        throw Exception('Failed to get initial location');
      }

      final userId = authState.user!.uid;
      
      // Start a new session in the repository
      final session = await _repository.startSession(
        userId: userId,
        initialLocation: initialLocation,
      );

      // Set up location subscription
      _locationSubscription?.cancel();
      _locationSubscription = _locationService.locationStream.listen(_handleLocationUpdate);

      // Set up tracking timer for duration
      _trackingStartTime = DateTime.now();
      _locationPoints = [initialLocation];
      _setupTrackingTimer();

      state = state.copyWith(
        status: TrackingStatus.active,
        activeSession: session,
        currentLocations: _locationPoints,
      );
    } catch (e) {
      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Resume tracking for an active session
  Future<void> _resumeTracking(TrackingSession session) async {
    try {
      // Start location tracking
      await _locationService.startTracking();

      // Set up location subscription
      _locationSubscription?.cancel();
      _locationSubscription = _locationService.locationStream.listen(_handleLocationUpdate);

      // Set up tracking timer for duration
      _trackingStartTime = DateTime.now().subtract(Duration(seconds: session.durationInSeconds));
      _locationPoints = session.locations;
      _setupTrackingTimer();

      state = state.copyWith(
        status: TrackingStatus.active,
        activeSession: session,
        currentLocations: _locationPoints,
      );
    } catch (e) {
      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Handle location update
  void _handleLocationUpdate(LocationPoint location) async {
    if (state.status != TrackingStatus.active || state.activeSession == null) {
      return;
    }

    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) return;

    final userId = authState.user!.uid;
    final activeSession = state.activeSession!;

    // Add location to the list
    _locationPoints.add(location);

    // Calculate miles
    final miles = LocationService.calculateTotalDistance(_locationPoints);

    // Calculate duration
    final durationInSeconds = DateTime.now().difference(_trackingStartTime!).inSeconds;

    try {
      // Update session in repository
      final updatedSession = await _repository.updateSession(
        userId: userId,
        sessionId: activeSession.id,
        newLocation: location,
        miles: miles,
        durationInSeconds: durationInSeconds,
      );

      state = state.copyWith(
        activeSession: updatedSession,
        currentLocations: _locationPoints,
      );
    } catch (e) {
      print('Error updating tracking session: $e');
    }
  }

  // Set up timer for tracking
  void _setupTrackingTimer() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status != TrackingStatus.active || state.activeSession == null || _trackingStartTime == null) {
        return;
      }

      final durationInSeconds = DateTime.now().difference(_trackingStartTime!).inSeconds;
      
      // Update state with new duration
      state = state.copyWith(
        activeSession: state.activeSession!.copyWith(
          durationInSeconds: durationInSeconds,
        ),
      );
    });
  }

  // Stop tracking
  Future<void> stopTracking() async {
    if (state.status != TrackingStatus.active || state.activeSession == null) {
      return;
    }

    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) {
      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: 'User not authenticated',
      );
      return;
    }

    // Stop location tracking
    await _locationService.stopTracking();
    
    // Cancel timer and subscription
    _trackingTimer?.cancel();
    _locationSubscription?.cancel();

    // Change state to ending shift
    state = state.copyWith(
      status: TrackingStatus.endingShift,
    );
  }

  // End shift with earnings and expenses
  Future<void> endShift({
    double? earnings,
    double? expenses,
  }) async {
    if (state.activeSession == null) {
      return;
    }

    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) {
      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: 'User not authenticated',
      );
      return;
    }

    final userId = authState.user!.uid;
    final sessionId = state.activeSession!.id;

    try {
      // End session in repository
      await _repository.endSession(
        userId: userId,
        sessionId: sessionId,
        endTime: DateTime.now(),
        earnings: earnings,
        expenses: expenses,
      );

      // Refresh insights
      await refreshInsights();

      // Reset state
      state = state.copyWith(
        status: TrackingStatus.inactive,
        activeSession: null,
        currentLocations: [],
      );
    } catch (e) {
      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Skip earnings entry
  Future<void> skipEarningsEntry() async {
    await endShift();
  }

  // Refresh insights for all periods
  Future<void> refreshInsights() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) return;

    final userId = authState.user!.uid;

    try {
      // Get sessions for different periods
      final todaySessions = await _repository.getSessionsForToday(userId);
      final weekSessions = await _repository.getSessionsForWeek(userId);
      final monthSessions = await _repository.getSessionsForMonth(userId);
      final yearSessions = await _repository.getSessionsForYear(userId);

      // Calculate insights
      final todayInsights = TrackingInsights.fromSessions(todaySessions);
      final weeklyInsights = TrackingInsights.fromSessions(weekSessions);
      final monthlyInsights = TrackingInsights.fromSessions(monthSessions);
      final yearlyInsights = TrackingInsights.fromSessions(yearSessions);

      // Update state
      state = state.copyWith(
        todayInsights: todayInsights,
        weeklyInsights: weeklyInsights,
        monthlyInsights: monthlyInsights,
        yearlyInsights: yearlyInsights,
      );
    } catch (e) {
      print('Error refreshing insights: $e');
    }
  }

  // Change selected insight period
  void setInsightPeriod(String period) {
    state = state.copyWith(selectedInsightPeriod: period);
  }
}
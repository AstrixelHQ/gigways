import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/tracking/models/tracking_model.dart';
import 'package:gigways/features/tracking/repositories/tracking_repository.dart';
import 'package:gigways/features/tracking/services/location_service.dart';
import 'package:gigways/core/services/notification_service.dart';
import 'package:gigways/core/services/driving_detection_service.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';

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
      selectedInsightPeriod:
          selectedInsightPeriod ?? this.selectedInsightPeriod,
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
  Timer? _inactivityTimer;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _appLifecycleSubscription;
  StreamSubscription? _activitySubscription;
  DateTime? _trackingStartTime;
  List<LocationPoint> _locationPoints = [];
  bool _isHandlingClosure = false;
  ActivityType? _lastActivityType;
  DateTime? _lastActivityChangeTime;
  DateTime? _lastLocationUpdateTime;

  // Constants
  static const int _inactivityThresholdMinutes = 5; // 5 minutes of inactivity
  static const int _inactivityCheckIntervalSeconds = 60; // Check every minute

  TrackingRepository get _repository => ref.read(trackingRepositoryProvider);
  LocationService get _locationService => ref.read(locationServiceProvider);
  NotificationService get _notificationService =>
      ref.read(notificationServiceProvider);
  DrivingDetectionService get _drivingDetectionService =>
      ref.read(drivingDetectionServiceProvider);

  @override
  TrackingState build() {
    // Clean up resources when provider is disposed
    ref.onDispose(() {
      _trackingTimer?.cancel();
      _locationSubscription?.cancel();
      _appLifecycleSubscription?.cancel();
      _activitySubscription?.cancel();
      _inactivityTimer?.cancel();
    });

    // Initialize tracking state
    _initializeTrackingState();
    _setupAppLifecycleListener();

    return TrackingState();
  }

  void _setupAppLifecycleListener() {
    _appLifecycleSubscription?.cancel();
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == AppLifecycleState.inactive.toString() ||
          msg == AppLifecycleState.paused.toString()) {
        if (state.status == TrackingStatus.active && !_isHandlingClosure) {
          // Don't stop tracking here, just set a flag to know the app went to background
          _isHandlingClosure = true;

          // Don't end the session - just make sure we have a notification
          // to remind the user that tracking is still active
          _showTrackingActiveNotification();
        }
      } else if (msg == AppLifecycleState.resumed.toString()) {
        _isHandlingClosure = false;

        // Remove any background tracking notifications when app is resumed
        _notificationService
            .cancel(102); // ID for background tracking notification
      }
      return null;
    });
  }

  // Show notification that tracking is still active in background
  void _showTrackingActiveNotification() {
    // Only show if we have an active session
    if (state.activeSession == null) return;

    _notificationService.show(
      NotificationData(
        id: 102, // Fixed ID for background tracking notification
        title: 'Tracking Active',
        body: 'Your trip is still being tracked. Tap to return to GigWays.',
        channel: NotificationChannel.driving,
        ongoing: true,
        autoCancel: false,
        payload: 'tracking_active',
      ),
    );
  }

  Future<void> _handleAppClosure() async {
    if (state.activeSession == null) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) return;

    try {
      // Stop tracking
      await _locationService.stopTracking();
      _trackingTimer?.cancel();
      _locationSubscription?.cancel();

      // End session in repository
      await _repository.endSession(
        userId: authState.user!.uid,
        sessionId: state.activeSession!.id,
        endTime: DateTime.now(),
      );

      // Send notification
      await _notificationService.show(
        NotificationData(
          id: 103, // Fixed ID for tracker stopped notification
          title: 'Tracker Stopped',
          body:
              'Your tracker was active and has been stopped since the app was closed. Your data has been saved.',
          channel: NotificationChannel.system,
          ongoing: false,
          autoCancel: true,
        ),
      );

      // Update state
      state = state.copyWith(
        status: TrackingStatus.inactive,
        activeSession: null,
        currentLocations: [],
      );
    } catch (e) {
      debugPrint('Error handling app closure: $e');
    }
  }

  void handleNotificationTap(String? payload) {
    if (payload == 'driving_detected') {
      // Auto-start tracking when notification is tapped
      startTracking();
    } else if (payload == 'inactivity_detected') {
      // Stop tracking when inactivity notification is tapped
      stopTracking();
    }
    // for tracking_active, we just go back to the app
  }

  // Initialize tracking state
  Future<void> _initializeTrackingState() async {
    await SchedulerBinding.instance.endOfFrame;

    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) {
      print('TrackingNotifier: User not authenticated during initialization');
      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: 'User not authenticated',
      );
      return;
    }

    print('TrackingNotifier: Initializing tracking state for user ${authState.user!.uid}');
    state = state.copyWith(status: TrackingStatus.loading);

    try {
      // Check for active session
      final userId = authState.user!.uid;
      final activeSession = await _repository.getActiveSession(userId);
      
      print('TrackingNotifier: Active session found: ${activeSession?.id}');
      print('TrackingNotifier: Session is active: ${activeSession?.isActive}');

      if (activeSession != null) {
        print('TrackingNotifier: Resuming tracking for session ${activeSession.id}');
        // If there's an active session, resume tracking
        await _resumeTracking(activeSession);
      } else {
        print('TrackingNotifier: No active session found');
      }

      state = state.copyWith(
        status: activeSession != null
            ? TrackingStatus.active
            : TrackingStatus.inactive,
        activeSession: activeSession,
      );
      
      print('TrackingNotifier: Initialization complete, status: ${state.status}');
    } catch (e) {
      print('TrackingNotifier: Error during initialization: $e');
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
      // Disable driving detection notifications while tracking is active
      _drivingDetectionService.setDetectionEnabled(false);

      // Cancel any inactivity notifications that might be showing
      _notificationService.cancel(104); // ID for inactivity notification

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
      _locationSubscription =
          _locationService.locationStream.listen(_handleLocationUpdate);

      // Set up activity recognition
      _setupActivityRecognition();

      // Set up tracking timer for duration
      _trackingStartTime = DateTime.now();
      _lastLocationUpdateTime = DateTime.now();
      _locationPoints = [initialLocation];
      _setupTrackingTimer();
      _setupInactivityDetection();

      state = state.copyWith(
        status: TrackingStatus.active,
        activeSession: session,
        currentLocations: _locationPoints,
      );
    } catch (e) {
      // Re-enable driving detection on error
      _drivingDetectionService.setDetectionEnabled(true);

      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Resume tracking for an active session
  Future<void> _resumeTracking(TrackingSession session) async {
    try {
      // Disable driving detection notifications while tracking is active
      _drivingDetectionService.setDetectionEnabled(false);

      // Cancel any inactivity notifications that might be showing
      _notificationService.cancel(104); // ID for inactivity notification

      // Start location tracking
      await _locationService.startTracking();

      // Set up location subscription
      _locationSubscription?.cancel();
      _locationSubscription =
          _locationService.locationStream.listen(_handleLocationUpdate);

      // Set up tracking timer for duration
      _trackingStartTime =
          DateTime.now().subtract(Duration(seconds: session.durationInSeconds));
      _lastLocationUpdateTime = DateTime.now();
      _locationPoints = session.locations;
      _setupTrackingTimer();
      _setupInactivityDetection();

      state = state.copyWith(
        status: TrackingStatus.active,
        activeSession: session,
        currentLocations: _locationPoints,
      );
    } catch (e) {
      // Re-enable driving detection on error
      _drivingDetectionService.setDetectionEnabled(true);

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

    // Update last location update time for inactivity detection
    _lastLocationUpdateTime = DateTime.now();

    // Add location to the list
    _locationPoints.add(location);

    // Calculate miles
    final miles = LocationService.calculateTotalDistance(_locationPoints);

    // Calculate duration
    final durationInSeconds =
        DateTime.now().difference(_trackingStartTime!).inSeconds;

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
      debugPrint('Error updating tracking session: $e');
    }
  }

  // Set up timer for tracking
  void _setupTrackingTimer() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status != TrackingStatus.active ||
          state.activeSession == null ||
          _trackingStartTime == null) {
        return;
      }

      final durationInSeconds =
          DateTime.now().difference(_trackingStartTime!).inSeconds;

      // Update state with new duration
      state = state.copyWith(
        activeSession: state.activeSession!.copyWith(
          durationInSeconds: durationInSeconds,
        ),
      );
    });
  }

  // Set up inactivity detection
  void _setupInactivityDetection() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(
        Duration(seconds: _inactivityCheckIntervalSeconds),
        (_) => _checkInactivity());
  }

  // Check for inactivity
  void _checkInactivity() {
    if (state.status != TrackingStatus.active ||
        _lastLocationUpdateTime == null) {
      return;
    }

    final now = DateTime.now();
    final inactivityDuration = now.difference(_lastLocationUpdateTime!);

    // If inactive for threshold duration (4-5 minutes)
    if (inactivityDuration.inMinutes >= _inactivityThresholdMinutes) {
      _notifyInactivity();
    }
  }

  // Notify user of inactivity
  void _notifyInactivity() {
    _notificationService.show(
      NotificationData(
        id: 104, // Fixed ID for inactivity notification
        title: 'Are You Still Driving?',
        body:
            'We haven\'t detected movement for ${_inactivityThresholdMinutes} minutes. Tap to end tracking if you\'ve stopped driving.',
        channel: NotificationChannel.driving,
        payload: 'inactivity_detected',
        autoCancel: false,
        ongoing: true, // Make it persistent
      ),
    );
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

    // Cancel timers and subscriptions
    _trackingTimer?.cancel();
    _locationSubscription?.cancel();
    _inactivityTimer?.cancel();

    // Cancel any ongoing notifications
    _notificationService.cancel(102); // Background tracking notification
    _notificationService.cancel(104); // Inactivity notification

    // Re-enable driving detection service
    _drivingDetectionService.setDetectionEnabled(true);

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

      // Cancel any ongoing notifications
      _notificationService.cancel(102); // Background tracking notification
      _notificationService.cancel(104); // Inactivity notification

      // Re-enable driving detection
      _drivingDetectionService.setDetectionEnabled(true);

      await _repository.endAllActiveSessions(
        userId,
        endTime: DateTime.now(),
        earnings: earnings,
        expenses: expenses,
      );

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

  // Skip earnings entry and force end shift
  Future<void> skipEarningsEntry() async {
    await endShift(earnings: 0.0, expenses: 0.0);
  }
  
  // Force end shift immediately (used when user turns off tracker or skips)
  Future<void> forceEndShift() async {
    print('forceEndShift called');
    
    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) {
      print('User not authenticated');
      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: 'User not authenticated',
      );
      return;
    }

    if (state.activeSession == null) {
      print('No active session found, resetting state');
      // If no active session but state shows endingShift, reset to inactive
      state = state.copyWith(
        status: TrackingStatus.inactive,
        activeSession: null,
        currentLocations: [],
      );
      return;
    }

    print('Setting loading state');
    state = state.copyWith(status: TrackingStatus.loading);

    final userId = authState.user!.uid;
    final sessionId = state.activeSession!.id;
    
    print('Ending session - User: $userId, Session: $sessionId');

    try {
      // Stop all location tracking and timers first
      await _locationService.stopTracking();
      _trackingTimer?.cancel();
      _locationSubscription?.cancel();
      _inactivityTimer?.cancel();
      
      print('Stopped tracking services');

      // End session in repository - store miles and duration, skip earnings/expenses
      await _repository.endSession(
        userId: userId,
        sessionId: sessionId,
        endTime: DateTime.now(),
        skipEarningsEntry: true, // This tells repository we're skipping earnings
      );
      
      print('Session ended in repository');

      // Cancel any ongoing notifications
      _notificationService.cancel(102); // Background tracking notification
      _notificationService.cancel(104); // Inactivity notification

      // Re-enable driving detection
      _drivingDetectionService.setDetectionEnabled(true);
      
      print('Cleaned up notifications and re-enabled driving detection');

      // Also ensure all other active sessions are ended
      await _repository.endAllActiveSessions(
        userId,
        endTime: DateTime.now(),
      );
      
      print('Ended all active sessions');

      // Reset state to inactive
      state = state.copyWith(
        status: TrackingStatus.inactive,
        activeSession: null,
        currentLocations: [],
      );
      
      print('State reset to inactive');
    } catch (e) {
      print('Error in forceEndShift: $e');
      state = state.copyWith(
        status: TrackingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void setInsightPeriod(String period) {
    state = state.copyWith(selectedInsightPeriod: period);
  }

  void _setupActivityRecognition() {
    _activitySubscription?.cancel();

    // We're using the activity stream from LocationService to avoid duplicate subscriptions
    _activitySubscription =
        _locationService.activityStream.listen(_handleActivityChange);
  }

  void _handleActivityChange(ActivityEvent event) {
    if (state.status != TrackingStatus.active) return;

    final now = DateTime.now();
    _lastActivityType = event.type;
    _lastActivityChangeTime = now;

    // For inactivity detection
    // If the user is STILL, we need to monitor this for inactivity
    // If they're DRIVING, we reset the inactivity timer
    if (event.type == ActivityType.IN_VEHICLE) {
      _lastLocationUpdateTime = now;
    }
  }
}

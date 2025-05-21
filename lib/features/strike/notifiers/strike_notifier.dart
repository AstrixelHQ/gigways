import 'package:flutter/scheduler.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/strike/models/strike_model.dart';
import 'package:gigways/features/strike/repositories/strike_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'strike_notifier.g.dart';

enum StrikeStatus {
  initial,
  loading,
  success,
  error,
}

class StrikeState {
  final StrikeStatus status;
  final String? errorMessage;
  final StrikeModel? userStrike;
  final DateTime? selectedDate;
  final StrikeCountResult? selectedDateStats;
  final StrikeCountResult? mostPopularDate;
  final List<StrikeCountResult> upcomingStrikeDates;
  final int totalUsers;
  final int stateUsers;
  final String userState;

  StrikeState({
    this.status = StrikeStatus.initial,
    this.errorMessage,
    this.userStrike,
    this.selectedDate,
    this.selectedDateStats,
    this.mostPopularDate,
    this.upcomingStrikeDates = const [],
    this.totalUsers = 0,
    this.stateUsers = 0,
    required this.userState,
  });

  StrikeState copyWith({
    StrikeStatus? status,
    String? errorMessage,
    StrikeModel? userStrike,
    DateTime? selectedDate,
    StrikeCountResult? selectedDateStats,
    StrikeCountResult? mostPopularDate,
    List<StrikeCountResult>? upcomingStrikeDates,
    int? totalUsers,
    int? stateUsers,
    String? userState,
  }) {
    return StrikeState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userStrike: userStrike ?? this.userStrike,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedDateStats: selectedDateStats ?? this.selectedDateStats,
      mostPopularDate: mostPopularDate ?? this.mostPopularDate,
      upcomingStrikeDates: upcomingStrikeDates ?? this.upcomingStrikeDates,
      totalUsers: totalUsers ?? this.totalUsers,
      stateUsers: stateUsers ?? this.stateUsers,
      userState: userState ?? this.userState,
    );
  }

  // Recommended time for a strike based on the date
  String getRecommendedTime(DateTime date) {
    // Get the day of week (1-7, Monday is 1)
    final dayOfWeek = date.weekday;

    // Determine if weekend or weekday
    final isWeekend =
        dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday;

    if (isWeekend) {
      // For weekends, recommend midday
      return '12:00 PM';
    } else {
      // For weekdays, recommend a time during busy hours
      // 8-10 AM or 4-8 PM (pick middle)
      final now = DateTime.now();
      final hour = now.hour;

      if (hour >= 8 && hour <= 10) {
        // Morning busy hours - pick 9 AM
        return '09:00 AM';
      } else if (hour >= 16 && hour <= 20) {
        // Evening busy hours - pick 6 PM
        return '06:00 PM';
      } else {
        // Default to morning rush hour
        return '09:00 AM';
      }
    }
  }
}

@Riverpod(keepAlive: true)
class StrikeNotifier extends _$StrikeNotifier {
  StrikeRepository get _repository => ref.read(strikeRepositoryProvider);

  @override
  StrikeState build() {
    final authState = ref.watch(authNotifierProvider);
    final userState = authState.userData?.state ?? 'Unknown';

    final initialState = StrikeState(userState: userState);

    // Initialize the strike data
    _initializeStrikeData();

    return initialState;
  }

  Future<void> _initializeStrikeData() async {
    await SchedulerBinding.instance.endOfFrame;
    final authState = ref.read(authNotifierProvider);
    if (authState.user == null || authState.userData == null) {
      return;
    }

    state = state.copyWith(status: StrikeStatus.loading);

    try {
      // Get user's active strike
      final userStrike = await _repository.getUserStrike(authState.user!.uid);

      // If user has an active strike, set it as the selected date
      DateTime? selectedDate;
      StrikeCountResult? selectedDateStats;

      if (userStrike != null) {
        selectedDate = userStrike.date;
        selectedDateStats = await _repository.getStrikeCountForDate(
            selectedDate, state.userState);
      }

      // Get most popular strike date in the user's state
      final mostPopularDate =
          await _repository.getMostPopularUpcomingStrikeDate(state.userState);

      // Get upcoming strike dates sorted by state count
      final upcomingStrikeCounts =
          await _repository.getUpcomingStrikeCounts(state.userState);

      // Get user counts
      final totalUsers = await _repository.getTotalUserCount();
      final stateUsers = await _repository.getStateUserCount(state.userState);

      state = state.copyWith(
        status: StrikeStatus.success,
        userStrike: userStrike,
        selectedDate: selectedDate,
        selectedDateStats: selectedDateStats,
        mostPopularDate: mostPopularDate,
        upcomingStrikeDates: upcomingStrikeCounts,
        totalUsers: totalUsers,
        stateUsers: stateUsers,
      );
    } catch (e) {
      state = state.copyWith(
        status: StrikeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Fetch stats for currently selected date
  Future<void> fetchSelectedDateStats() async {
    if (state.selectedDate == null) return;

    state = state.copyWith(status: StrikeStatus.loading);

    try {
      final statsForSelectedDate = await _repository.getStrikeCountForDate(
          state.selectedDate!, state.userState);

      state = state.copyWith(
        status: StrikeStatus.success,
        selectedDateStats: statsForSelectedDate,
      );
    } catch (e) {
      state = state.copyWith(
        status: StrikeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Schedule a strike
  Future<void> scheduleStrike(DateTime date) async {
    final authState = ref.read(authNotifierProvider);
    if (authState.user == null || authState.userData == null) {
      state = state.copyWith(
        status: StrikeStatus.error,
        errorMessage: 'User not authenticated',
      );
      return;
    }

    // Validate date is in the future
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isBefore(today)) {
      state = state.copyWith(
        status: StrikeStatus.error,
        errorMessage: 'Cannot schedule a strike for a past date',
      );
      return;
    }

    state = state.copyWith(status: StrikeStatus.loading);

    try {
      // Create a new strike
      await _repository.createStrike(
        userId: authState.user!.uid,
        date: date,
        state: authState.userData!.state!,
        userName: authState.userData!.fullName,
      );

      // Refresh all data
      await _initializeStrikeData();
    } catch (e) {
      state = state.copyWith(
        status: StrikeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Refresh all strike data
  Future<void> refreshStrikeData() async {
    await _initializeStrikeData();
  }

  Future<void> rescheduleStrike(DateTime newDate) async {
    final authState = ref.read(authNotifierProvider);
    if (authState.user == null || authState.userData == null) {
      state = state.copyWith(
        status: StrikeStatus.error,
        errorMessage: 'User not authenticated',
      );
      return;
    }

    // Validate date is in the future
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (newDate.isBefore(today)) {
      state = state.copyWith(
        status: StrikeStatus.error,
        errorMessage: 'Cannot schedule a strike for a past date',
      );
      return;
    }

    state = state.copyWith(status: StrikeStatus.loading);

    try {
      final userId = authState.user!.uid;

      // Check if there's an existing strike to cancel
      if (state.userStrike != null) {
        // Cancel the existing strike
        await _repository.cancelStrike(
          userId: userId,
          strikeId: state.userStrike!.id,
        );
      }

      // Create a new strike
      await _repository.createStrike(
        userId: userId,
        date: newDate,
        state: authState.userData!.state!,
        userName: authState.userData!.fullName,
      );

      await _initializeStrikeData();
    } catch (e) {
      state = state.copyWith(
        status: StrikeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cancelStrike() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.user == null || state.userStrike == null) {
      state = state.copyWith(
        status: StrikeStatus.error,
        errorMessage: 'User not authenticated or no strike to cancel',
      );
      return;
    }

    state = state.copyWith(status: StrikeStatus.loading);

    try {
      final userId = authState.user!.uid;
      final strikeId = state.userStrike!.id;

      // Cancel the strike
      await _repository.cancelStrike(
        userId: userId,
        strikeId: strikeId,
      );

      await refreshStrikeData();
    } catch (e) {
      state = state.copyWith(
        status: StrikeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

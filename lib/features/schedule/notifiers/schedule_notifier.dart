import 'package:flutter/material.dart';
import 'package:gigways/features/auth/models/user_model.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/auth/repositories/user_repository.dart';
import 'package:gigways/features/schedule/models/schedule_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_notifier.g.dart';

enum ScheduleStatus {
  initial,
  loading,
  success,
  error,
}

class ScheduleState {
  final ScheduleStatus status;
  final String? errorMessage;
  final ScheduleModel? schedule;
  final bool isDirty; // Tracks if there are unsaved changes

  ScheduleState({
    this.status = ScheduleStatus.initial,
    this.errorMessage,
    this.schedule,
    this.isDirty = false,
  });

  ScheduleState copyWith({
    ScheduleStatus? status,
    String? errorMessage,
    ScheduleModel? schedule,
    bool? isDirty,
  }) {
    return ScheduleState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      schedule: schedule ?? this.schedule,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

@Riverpod(keepAlive: true)
class ScheduleNotifier extends _$ScheduleNotifier {
  late UserRepository _userRepository;

  @override
  ScheduleState build() {
    _userRepository = ref.read(userRepositoryProvider);

    // Initialize with user's existing schedule (if any)
    final userData = ref.watch(authNotifierProvider).userData;
    final userSchedule = userData?.schedule ?? ScheduleModel.defaultSchedule();

    return ScheduleState(schedule: userSchedule);
  }

  // Update employment type
  void updateEmploymentType(String employmentType) {
    if (state.schedule == null) return;

    final updatedSchedule = state.schedule!.copyWith(
      employmentType: employmentType,
    );

    state = state.copyWith(
      schedule: updatedSchedule,
      isDirty: true,
    );
  }

  // Update shift preference
  void updateShiftPreference(String shiftPreference) {
    if (state.schedule == null) return;

    final updatedSchedule = state.schedule!.copyWith(
      shiftPreference: shiftPreference,
    );

    state = state.copyWith(
      schedule: updatedSchedule,
      isDirty: true,
    );
  }

  // Update a specific day's schedule
  void updateDaySchedule(String day, TimeOfDay? startTime, TimeOfDay? endTime) {
    if (state.schedule == null) return;

    final currentSchedule =
        Map<String, DayScheduleModel?>.from(state.schedule!.weeklySchedule);

    // If both times are null, set the day's schedule to null (day not selected)
    if (startTime == null || endTime == null) {
      currentSchedule[day] = null;
    } else {
      // Create a time range for the day
      final timeRange = TimeRangeModel(
        start: TimeOfDayModel(hour: startTime.hour, minute: startTime.minute),
        end: TimeOfDayModel(hour: endTime.hour, minute: endTime.minute),
      );

      // Update the day's schedule
      currentSchedule[day] = DayScheduleModel(timeRange: timeRange);
    }

    final updatedSchedule = state.schedule!.copyWith(
      weeklySchedule: currentSchedule,
    );

    state = state.copyWith(
      schedule: updatedSchedule,
      isDirty: true,
    );
  }

  // Save the schedule to Firestore
  Future<void> saveSchedule() async {
    if (state.schedule == null) return;

    final user = ref.read(authNotifierProvider);
    if (user.user == null || user.userData == null) {
      state = state.copyWith(
        status: ScheduleStatus.error,
        errorMessage: 'User not authenticated',
      );
      return;
    }

    state = state.copyWith(status: ScheduleStatus.loading);

    try {
      // Update user model with new schedule
      final updatedUserData = user.userData!.copyWith(
        schedule: state.schedule,
      );

      // Save to repository
      await _userRepository.updateUser(updatedUserData);

      // Update auth state with new user data
      ref.read(authNotifierProvider.notifier).updateUserData(updatedUserData);

      state = state.copyWith(
        status: ScheduleStatus.success,
        isDirty: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: ScheduleStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Reset schedule to last saved version
  void resetSchedule() {
    final userData = ref.read(authNotifierProvider).userData;
    final savedSchedule = userData?.schedule ?? ScheduleModel.defaultSchedule();

    state = state.copyWith(
      schedule: savedSchedule,
      isDirty: false,
      status: ScheduleStatus.initial,
    );
  }
}

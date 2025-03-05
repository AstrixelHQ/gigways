import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gigways/features/auth/models/user_model.dart';
import 'package:gigways/features/auth/notifiers/auth_notifier.dart';
import 'package:gigways/features/auth/repositories/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_notifier.g.dart';

enum ProfileUpdateStatus { initial, loading, success, error }

class ProfileState {
  final ProfileUpdateStatus status;
  final String? errorMessage;
  final UserModel? userData;

  ProfileState({
    this.status = ProfileUpdateStatus.initial,
    this.errorMessage,
    this.userData,
  });

  ProfileState copyWith({
    ProfileUpdateStatus? status,
    String? errorMessage,
    UserModel? userData,
  }) {
    return ProfileState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userData: userData ?? this.userData,
    );
  }
}

@Riverpod(keepAlive: true)
class ProfileNotifier extends _$ProfileNotifier {
  UserRepository get _userRepository => ref.read(userRepositoryProvider);
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  ProfileState build() {
    // Get the current user data from auth notifier
    final authState = ref.watch(authNotifierProvider);
    if (authState.userData != null) {
      return ProfileState(
        status: ProfileUpdateStatus.initial,
        userData: authState.userData,
      );
    }

    return ProfileState();
  }

  // Update profile information
  Future<void> updateProfile({
    required String fullName,
    required String email,
    String? phoneNumber,
    String? countryState,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(
        status: ProfileUpdateStatus.error,
        errorMessage: 'User not authenticated',
      );
      return;
    }

    state = state.copyWith(status: ProfileUpdateStatus.loading);

    try {
      await _userRepository.updateUserProfile(
        userId: user.uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        state: countryState,
      );

      // Fetch updated user data
      final updatedUserData = await _userRepository.getUser(user.uid);

      state = state.copyWith(
        status: ProfileUpdateStatus.success,
        userData: updatedUserData,
      );

      // Update auth state with new user data
      final authNotifier = ref.read(authNotifierProvider.notifier);
      if (updatedUserData != null) {
        authNotifier.updateUserData(updatedUserData);
      }
    } catch (e) {
      state = state.copyWith(
        status: ProfileUpdateStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Upload profile image
  Future<void> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(
        status: ProfileUpdateStatus.error,
        errorMessage: 'User not authenticated',
      );
      return;
    }

    state = state.copyWith(status: ProfileUpdateStatus.loading);

    try {
      final imageUrl = await _userRepository.uploadProfileImage(
        user.uid,
        imageFile,
      );

      if (imageUrl != null) {
        // Fetch updated user data
        final updatedUserData = await _userRepository.getUser(user.uid);

        state = state.copyWith(
          status: ProfileUpdateStatus.success,
          userData: updatedUserData,
        );

        // Update auth state with new user data
        final authNotifier = ref.read(authNotifierProvider.notifier);
        if (updatedUserData != null) {
          authNotifier.updateUserData(updatedUserData);
        }
      } else {
        state = state.copyWith(
          status: ProfileUpdateStatus.error,
          errorMessage: 'Failed to upload image',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ProfileUpdateStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Reset status (call after handling success/error)
  void resetStatus() {
    state = state.copyWith(status: ProfileUpdateStatus.initial);
  }
}

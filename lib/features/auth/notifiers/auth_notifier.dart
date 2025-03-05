import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:gigways/features/auth/models/user_model.dart';
import 'package:gigways/features/auth/repositories/user_repository.dart';

part 'auth_notifier.g.dart';

enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  loading,
  needsState,
  error,
}

class AuthData {
  final AuthState state;
  final User? user;
  final UserModel? userData;
  final String? errorMessage;

  AuthData({
    required this.state,
    this.user,
    this.userData,
    this.errorMessage,
  });

  AuthData copyWith({
    AuthState? state,
    User? user,
    UserModel? userData,
    String? errorMessage,
  }) {
    return AuthData(
      state: state ?? this.state,
      user: user ?? this.user,
      userData: userData ?? this.userData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  late final FirebaseAuth _auth;
  late final UserRepository _userRepository;

  // Add a stream controller to expose state changes as a stream
  final _controller = StreamController<AuthData>.broadcast();
  Stream<AuthData> get stream => _controller.stream;

  @override
  AuthData build() {
    _auth = FirebaseAuth.instance;
    _userRepository = ref.read(userRepositoryProvider);

    // Check if user is already logged in
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _loadUserData(currentUser);
    }

    ref.onDispose(() {
      _controller.close();
    });

    return AuthData(
      state:
          currentUser != null ? AuthState.loading : AuthState.unauthenticated,
      user: currentUser,
    );
  }

  // Listen to auth state changes
  void listenToAuthChanges() {
    _auth.userChanges().listen((User? user) {
      if (user == null) {
        state = AuthData(state: AuthState.unauthenticated);
        _controller.add(state);
      } else {
        _loadUserData(user);
      }
    });
  }

  // Load user data from Firestore
  Future<void> _loadUserData(User user) async {
    state = state.copyWith(state: AuthState.loading, user: user);
    _controller.add(state);

    try {
      final userData = await _userRepository.getUser(user.uid);

      if (userData == null) {
        state = state.copyWith(
          state: AuthState.error,
          errorMessage: 'User data not found',
        );
        _controller.add(state);
        return;
      }

      // Check if user has state
      if (userData.state == null) {
        state = state.copyWith(
          state: AuthState.needsState,
          userData: userData,
        );
      } else {
        state = state.copyWith(
          state: AuthState.authenticated,
          userData: userData,
        );
      }
      _controller.add(state);
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
      _controller.add(state);
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(state: AuthState.loading);
    _controller.add(state);

    try {
      // Start the sign-in flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        state = state.copyWith(state: AuthState.unauthenticated);
        _controller.add(state);
        return;
      }

      // Obtain the auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to sign in with Google');
      }

      await _handleUserSignIn(
        user,
        name: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
      );
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
      _controller.add(state);
    }
  }

  // Sign in with Facebook
  Future<void> signInWithFacebook() async {
    state = state.copyWith(state: AuthState.loading);
    _controller.add(state);

    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login failed: ${result.message}');
      }

      // Create credential
      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.token,
      );

      // Get user profile
      final userData = await FacebookAuth.instance.getUserData();

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to sign in with Facebook');
      }

      await _handleUserSignIn(
        user,
        name: userData['name'],
        email: userData['email'],
        photoUrl: userData['picture']['data']['url'],
      );
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
      _controller.add(state);
    }
  }

  // Sign in with Apple
  Future<void> signInWithApple() async {
    state = state.copyWith(state: AuthState.loading);
    _controller.add(state);

    try {
      // Start the sign-in flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuthCredential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to sign in with Apple');
      }

      // For Apple, we need to combine first and last name as Apple might not always provide them
      String? fullName;
      if (credential.givenName != null && credential.familyName != null) {
        fullName = '${credential.givenName} ${credential.familyName}';
      }

      await _handleUserSignIn(
        user,
        name: fullName ?? user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
      );
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
      _controller.add(state);
    }
  }

  // Common method to handle user sign in and check/create user data
  Future<void> _handleUserSignIn(
    User user, {
    String? name,
    String? email,
    String? photoUrl,
  }) async {
    try {
      final userExists = await _userRepository.checkUserExists(user.uid);

      if (!userExists) {
        // Create new user in Firestore
        final newUser = UserModel(
          id: user.uid,
          fullName: name ?? 'User',
          email: email ?? 'No email',
          profileImageUrl: photoUrl,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );

        await _userRepository.createUser(newUser);

        state = state.copyWith(
          state: AuthState.needsState,
          user: user,
          userData: newUser,
        );
        _controller.add(state);
      } else {
        // User exists, load their data
        await _loadUserData(user);
      }
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
      _controller.add(state);
    }
  }

  // Update user state
  Future<void> updateUserState(String state) async {
    if (this.state.user == null || this.state.userData == null) {
      return;
    }

    final userId = this.state.user!.uid;
    final currentUserData = this.state.userData!;

    await _userRepository.updateUserState(userId, state);

    final updatedUserData = currentUserData.copyWith(state: state);

    this.state = this.state.copyWith(
          state: AuthState.authenticated,
          userData: updatedUserData,
        );
    _controller.add(this.state);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      await FacebookAuth.instance.logOut();

      state = AuthData(state: AuthState.unauthenticated);
      _controller.add(state);
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
      _controller.add(state);
    }
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigways/features/auth/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository.g.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Reference to the users collection
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // Get user document reference by ID
  DocumentReference<Map<String, dynamic>> userDoc(String userId) =>
      _usersCollection.doc(userId);

  // Check if a user exists
  Future<bool> checkUserExists(String userId) async {
    final doc = await userDoc(userId).get();
    return doc.exists;
  }

  // Get user data
  Future<UserModel?> getUser(String userId) async {
    final doc = await userDoc(userId).get();

    if (!doc.exists) {
      return null;
    }

    return UserModel.fromFirestore(doc);
  }

  // Create a new user
  Future<void> createUser(UserModel user) async {
    await userDoc(user.id).set(user.toFirestore());
  }

  // Update user state
  Future<void> updateUserState(String userId, String state) async {
    await userDoc(userId).update({
      'state': state,
      'lastActiveAt': DateTime.now(),
    });
  }

  // Update user profile data
  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    required String email,
    String? phoneNumber,
    String? state,
  }) async {
    await userDoc(userId).update({
      'fullName': fullName,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (state != null) 'state': state,
      'lastActiveAt': DateTime.now(),
    });
  }

  // Upload profile image
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');

      // Upload image
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update user document with profile image URL
      await userDoc(userId).update({
        'profileImageUrl': downloadUrl,
        'lastActiveAt': DateTime.now(),
      });

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Update user data
  Future<void> updateUser(UserModel user) async {
    await userDoc(user.id).update({
      ...user.toFirestore(),
      'lastActiveAt': DateTime.now(),
    });
  }
}

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) {
  return UserRepository();
}

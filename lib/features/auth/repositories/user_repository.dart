import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gigways/features/auth/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository.g.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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

  // Update user data
  Future<void> updateUser(UserModel user) async {
    await userDoc(user.id).update({
      ...user.toFirestore(),
      'lastActiveAt': DateTime.now(),
    });
  }
}

@Riverpod(keepAlive: true)
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository();
}

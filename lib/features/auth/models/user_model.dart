import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gigways/features/schedule/models/schedule_models.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? state;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final ScheduleModel? schedule;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.state,
    required this.createdAt,
    required this.lastActiveAt,
    this.schedule,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse schedule data if available
    ScheduleModel? scheduleData;
    if (data['schedule'] != null) {
      scheduleData = ScheduleModel.fromMap(data['schedule']);
    }

    return UserModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      state: data['state'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp).toDate(),
      schedule: scheduleData,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'state': state,
      'createdAt': createdAt,
      'lastActiveAt': lastActiveAt,
      'id': id,
      'schedule': schedule?.toMap(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? state,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    ScheduleModel? schedule,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      schedule: schedule ?? this.schedule,
    );
  }
}

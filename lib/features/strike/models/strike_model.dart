import 'package:cloud_firestore/cloud_firestore.dart';

class StrikeModel {
  final String id;
  final String userId;
  final String dateString; // Store as YYYY-MM-DD
  final DateTime date; // Keep DateTime for UI convenience
  final String state;
  final DateTime createdAt;
  final String? userName;

  StrikeModel({
    required this.id,
    required this.userId,
    required this.dateString,
    required this.date,
    required this.state,
    required this.createdAt,
    this.userName,
  });

  factory StrikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse date from string format
    final dateString = data['dateString'] as String;
    final dateParts = dateString.split('-');
    final date = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]),
        int.parse(dateParts[2]));

    return StrikeModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      dateString: dateString,
      date: date,
      state: data['state'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userName: data['userName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'dateString': dateString,
      'state': state,
      'createdAt': createdAt,
      'userName': userName,
    };
  }

  // Helper method to format date as string
  static String formatDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Strike count result model with enhanced state-specific information
class StrikeCountResult {
  final DateTime date;
  final String dateString;
  final int totalCount;
  final int stateCount;

  StrikeCountResult({
    required this.date,
    required this.dateString,
    this.totalCount = 0,
    this.stateCount = 0,
  });

  // Helper to create a copy with updated values
  StrikeCountResult copyWith({
    DateTime? date,
    String? dateString,
    int? totalCount,
    int? stateCount,
  }) {
    return StrikeCountResult(
      date: date ?? this.date,
      dateString: dateString ?? this.dateString,
      totalCount: totalCount ?? this.totalCount,
      stateCount: stateCount ?? this.stateCount,
    );
  }

  // Calculate state percentage
  double get statePercentage {
    if (totalCount == 0) return 0.0;
    return stateCount / totalCount;
  }
}

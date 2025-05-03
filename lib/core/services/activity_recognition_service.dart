import 'dart:async';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'activity_recognition_service.g.dart';

@riverpod
ActivityRecognitionService activityRecognitionService(
    ActivityRecognitionServiceRef ref) {
  return ActivityRecognitionService();
}

class ActivityRecognitionService {
  static final ActivityRecognitionService _instance =
      ActivityRecognitionService._internal();
  factory ActivityRecognitionService() => _instance;
  ActivityRecognitionService._internal();

  final ActivityRecognition _activityRecognition = ActivityRecognition();
  StreamSubscription<ActivityEvent>? _subscription;
  final _activityController = StreamController<ActivityEvent>.broadcast();

  Stream<ActivityEvent> get activityStream => _activityController.stream;

  void initialize() {
    _subscription?.cancel();
    _subscription = _activityRecognition.activityStream().listen((event) {
      _activityController.add(event);
    });
  }

  void dispose() {
    _subscription?.cancel();
    _activityController.close();
  }
}

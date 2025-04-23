import 'package:flutter/services.dart';

class MotionPermission {
  static const MethodChannel _channel = MethodChannel('motion_permission');

  static Future<bool> checkStatus() async {
    return await _channel.invokeMethod('checkMotionPermissionStatus');
  }

  static Future<bool> request() async {
    return await _channel.invokeMethod('requestMotionPermission');
  }
}

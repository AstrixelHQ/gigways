import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'resend_otp_timer_notifier.g.dart';

@Riverpod(keepAlive: false)
class ResendTimerNotifier extends _$ResendTimerNotifier {
  Timer? _timer;

  @override
  int build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    startTimer();
    return 60;
  }

  void startTimer() {
    _timer?.cancel();
    state = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state > 0) {
        state--;
      } else {
        _timer?.cancel();
      }
    });
  }
}

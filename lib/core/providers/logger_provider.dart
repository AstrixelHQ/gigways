import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

part 'logger_provider.g.dart';

@riverpod
Talker logger(Ref ref) {
  return Talker();
}

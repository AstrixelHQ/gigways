import 'dart:ui';

enum AppColorToken {
  primary(Color(0xFF2196F3)),
  secondary(Color(0xFF03DAC6)),
  error(Color(0xFFB00020)),
  success(Color(0xFF4CAF50)),
  warning(Color(0xFFFFC107)),
  info(Color(0xFF2196F3)),
  textPrimary(Color(0xFF1C1B1F)),
  textSecondary(Color(0xFF49454F)),
  textDisabled(Color(0xFF9E9E9E)),
  background(Color(0xFFFFFBFE)),
  surface(Color(0xFFFFFBFE)),
  black(Color(0xFF000000)),
  lightDark(Color(0xFF1A1A1A)),
  surfaceVariant(Color(0xFFE7E0EC));


  final Color color;
  const AppColorToken(this.color);

  // Helper method to get color by name
  static Color? fromName(String name) {
    try {
      return AppColorToken.values
          .firstWhere((element) => element.name == name)
          .color;
    } catch (_) {
      return null;
    }
  }
}

extension AppColorTokenExtension on AppColorToken {
  Color get value => color;
}

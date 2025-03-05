extension StringExtension on String {
  String get initials {
    if (isEmpty) return '';

    final names = trim().split(' ');
    String result = '';

    // Add the first letter of the first name
    if (names.isNotEmpty && names[0].isNotEmpty) {
      result += names[0][0].toUpperCase();
    }

    // Add the first letter of the last name (if available)
    if (names.length > 1 && names[names.length - 1].isNotEmpty) {
      result += names[names.length - 1][0].toUpperCase();
    } else if (names.length > 1 && names[1].isNotEmpty) {
      // If last name is empty but second name exists
      result += names[1][0].toUpperCase();
    }

    return result;
  }

  bool get isValidEmail {
    // Simple email validation regex
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(this);
  }

  bool get isValidPhone {
    // Basic phone validation - can be expanded for different formats
    final phoneRegExp = RegExp(r'^\([0-9]{3}\) [0-9]{3}-[0-9]{4}$');
    return phoneRegExp.hasMatch(this);
  }
}

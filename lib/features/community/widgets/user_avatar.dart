import 'package:flutter/material.dart';
import 'package:gigways/core/theme/themes.dart';

class UserAvatar extends StatelessWidget {
  final String userName;
  final String? imageUrl;
  final double size;

  const UserAvatar({
    super.key,
    required this.userName,
    required this.imageUrl,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: imageUrl == null ? AppColorToken.primary.value : null,
        border: Border.all(
          color: AppColorToken.golden.value,
          width: 2,
        ),
      ),
      child: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    // Extract initials from the user name
    final nameParts = userName.split(' ');
    String initials = '';
    
    if (nameParts.isNotEmpty) {
      initials += nameParts[0][0];
      if (nameParts.length > 1) {
        initials += nameParts[1][0];
      }
    }

    return Center(
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: AppColorToken.white.value,
          fontWeight: FontWeight.bold,
          fontSize: size / 2.5,
        ),
      ),
    );
  }
}
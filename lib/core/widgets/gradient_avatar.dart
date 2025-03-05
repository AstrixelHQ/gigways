import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gigways/core/extensions/string_extension.dart';
import 'package:gigways/core/theme/themes.dart';

class GradientAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool isEditable;
  final VoidCallback? onEdit;

  // Custom cache manager for avatars
  static final customCacheManager = CacheManager(
    Config(
      'avatarCacheKey',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  );

  const GradientAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 60,
    this.isEditable = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Avatar container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: imageUrl == null ? _getGradientForName(name) : null,
            border: Border.all(
              color: AppColorToken.golden.value,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    cacheManager: customCacheManager,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: size / 3,
                        height: size / 3,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColorToken.golden.value,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildInitials(),
                  )
                : _buildInitials(),
          ),
        ),

        // Edit button
        if (isEditable)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColorToken.golden.value,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColorToken.black.value,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  size: size / 5,
                  color: AppColorToken.black.value,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        name.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size / 2.5,
        ),
      ),
    );
  }

  LinearGradient _getGradientForName(String name) {
    // Generate a deterministic seed based on the name
    final seed = name.hashCode;
    final random = Random(seed);

    // Create a random gradient using the golden color as one of the colors
    final baseColor = AppColorToken.golden.value;

    // Generate a complementary or contrasting color
    final complementaryHue = (HSLColor.fromColor(baseColor).hue + 180) % 360;
    final secondColor = HSLColor.fromAHSL(
      1.0,
      complementaryHue,
      0.7 + random.nextDouble() * 0.3, // Saturation
      0.4 + random.nextDouble() * 0.3, // Lightness
    ).toColor();

    return LinearGradient(
      colors: [baseColor, secondColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../models/channel_user.dart';

/// Avatar for a channel user.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.nickname,
    this.mode = UserMode.regular,
    this.isAway = false,
    this.size = AvatarSize.medium,
  });

  /// User's nickname.
  final String nickname;

  /// User's mode in the channel.
  final UserMode mode;

  /// Whether the user is away.
  final bool isAway;

  /// Avatar size.
  final AvatarSize size;

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final radius = size.radius;
    final fontSize = size.fontSize;

    return Stack(
      children: [
        // Main avatar
        CircleAvatar(
          radius: radius,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: isAway ? AppColors.textTertiary : color,
            ),
          ),
        ),

        // Mode indicator
        if (mode != UserMode.regular)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size.indicatorSize,
              height: size.indicatorSize,
              decoration: BoxDecoration(
                color: _getModeColor(),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  mode.prefix,
                  style: TextStyle(
                    fontSize: size.indicatorFontSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ),
          ),

        // Away indicator
        if (isAway && mode == UserMode.regular)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size.indicatorSize,
              height: size.indicatorSize,
              decoration: BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.schedule,
                size: size.indicatorFontSize,
                color: AppColors.textInverse,
              ),
            ),
          ),
      ],
    );
  }

  Color _getColor() {
    if (isAway) return AppColors.textTertiary;

    return switch (mode) {
      UserMode.operator => AppColors.operator,
      UserMode.halfOp => AppColors.warning,
      UserMode.voice => AppColors.voice,
      UserMode.regular => AppColors.nickColor(nickname),
    };
  }

  Color _getModeColor() {
    return switch (mode) {
      UserMode.operator => AppColors.operator,
      UserMode.halfOp => AppColors.warning,
      UserMode.voice => AppColors.voice,
      UserMode.regular => Colors.transparent,
    };
  }
}

/// Avatar size presets.
enum AvatarSize {
  small(12, 10, 10, 6),
  medium(16, 12, 14, 8),
  large(20, 14, 18, 10);

  const AvatarSize(this.radius, this.fontSize, this.indicatorSize, this.indicatorFontSize);

  final double radius;
  final double fontSize;
  final double indicatorSize;
  final double indicatorFontSize;
}

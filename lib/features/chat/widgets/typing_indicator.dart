import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Displays who is currently typing in the channel.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({
    super.key,
    required this.typingUsers,
  });

  /// List of nicknames currently typing.
  final List<String> typingUsers;

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Container(
          key: ValueKey(typingUsers.join(',')),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.divider),
            ),
          ),
          child: Row(
            children: [
              // Animated dots
              const TypingDots(),
              AppSpacing.gapSm,
              // Typing text
              Expanded(
                child: Text(
                  _buildTypingText(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTypingText() {
    if (typingUsers.isEmpty) return '';

    if (typingUsers.length == 1) {
      return '${typingUsers[0]} is typing...';
    } else if (typingUsers.length == 2) {
      return '${typingUsers[0]} and ${typingUsers[1]} are typing...';
    } else if (typingUsers.length == 3) {
      return '${typingUsers[0]}, ${typingUsers[1]}, and ${typingUsers[2]} are typing...';
    } else {
      return '${typingUsers[0]}, ${typingUsers[1]}, and ${typingUsers.length - 2} others are typing...';
    }
  }
}

/// Animated typing dots.
class TypingDots extends StatefulWidget {
  const TypingDots({
    super.key,
    this.color,
    this.size = 6.0,
  });

  /// Color of the dots.
  final Color? color;

  /// Size of each dot.
  final double size;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Stagger the animation for each dot
            final delay = index * 0.2;
            final progress = (_controller.value - delay) % 1.0;

            // Create a bouncing effect
            double scale;
            double opacity;

            if (progress < 0.5) {
              // Going up
              scale = 1.0 + (progress * 0.6);
              opacity = 0.4 + (progress * 1.2);
            } else {
              // Going down
              scale = 1.3 - ((progress - 0.5) * 0.6);
              opacity = 1.0 - ((progress - 0.5) * 1.2);
            }

            opacity = opacity.clamp(0.4, 1.0);
            scale = scale.clamp(1.0, 1.3);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.25),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Compact typing indicator for inline use.
class TypingIndicatorCompact extends StatelessWidget {
  const TypingIndicatorCompact({
    super.key,
    required this.typingUsers,
  });

  /// List of nicknames currently typing.
  final List<String> typingUsers;

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const TypingDots(size: 4),
        AppSpacing.gapXs,
        Text(
          typingUsers.length == 1
              ? typingUsers[0]
              : '${typingUsers.length} people',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Wave-style typing indicator.
class TypingWave extends StatefulWidget {
  const TypingWave({
    super.key,
    this.color,
    this.barCount = 4,
    this.barWidth = 3.0,
    this.barHeight = 16.0,
  });

  /// Color of the bars.
  final Color? color;

  /// Number of bars.
  final int barCount;

  /// Width of each bar.
  final double barWidth;

  /// Maximum height of bars.
  final double barHeight;

  @override
  State<TypingWave> createState() => _TypingWaveState();
}

class _TypingWaveState extends State<TypingWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;

    return SizedBox(
      height: widget.barHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Create wave effect with staggered timing
              final delay = index / widget.barCount;
              final progress = (_controller.value + delay) % 1.0;

              // Sinusoidal wave
              final height = widget.barHeight *
                  (0.3 + 0.7 * ((1 + math.sin(progress * 2 * math.pi)) / 2));

              return Container(
                margin: EdgeInsets.symmetric(horizontal: widget.barWidth * 0.3),
                width: widget.barWidth,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(widget.barWidth / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}


import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Preview of a message being replied to.
class ReplyPreview extends StatelessWidget {
  const ReplyPreview({
    super.key,
    required this.senderNickname,
    required this.content,
    this.onTap,
    this.onDismiss,
    this.isInline = false,
  });

  /// Nickname of the original message sender.
  final String senderNickname;

  /// Content of the original message (truncated).
  final String content;

  /// Called when the preview is tapped (to scroll to original).
  final VoidCallback? onTap;

  /// Called when dismiss button is pressed (for input preview).
  final VoidCallback? onDismiss;

  /// Whether this is inline in a message bubble (smaller style).
  final bool isInline;

  @override
  Widget build(BuildContext context) {
    final nickColor = AppColors.nickColor(senderNickname);

    if (isInline) {
      return _buildInlinePreview(nickColor);
    }

    return _buildInputPreview(nickColor);
  }

  Widget _buildInlinePreview(Color nickColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: nickColor,
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              senderNickname,
              style: AppTextStyles.labelSmall.copyWith(
                color: nickColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              content,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPreview(Color nickColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(
          left: BorderSide(
            color: nickColor,
            width: 3,
          ),
          bottom: const BorderSide(
            color: AppColors.divider,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: AppColors.textTertiary,
          ),
          AppSpacing.gapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to $senderNickname',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: nickColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  content,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }
}

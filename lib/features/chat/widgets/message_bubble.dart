import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';
import '../models/chat_message.dart';
import 'reply_preview.dart';

/// A message bubble displaying a chat message.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.replyTo,
    this.currentUserNick,
    this.isCompact = false,
    this.showTimestamp = true,
    this.onReply,
    this.onTapReply,
    this.onUserTap,
  });

  /// The message to display.
  final ChatMessage message;

  /// The message being replied to (if any).
  final ChatMessage? replyTo;

  /// Current user's nickname for mention highlighting.
  final String? currentUserNick;

  /// Whether to use compact display mode.
  final bool isCompact;

  /// Whether to show timestamp.
  final bool showTimestamp;

  /// Called when reply action is triggered.
  final VoidCallback? onReply;

  /// Called when reply preview is tapped.
  final VoidCallback? onTapReply;

  /// Called when sender nickname is tapped.
  final void Function(String nickname)? onUserTap;

  bool get _isMention =>
      currentUserNick != null &&
      message.content.toLowerCase().contains(currentUserNick!.toLowerCase());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: isCompact ? 1 : AppSpacing.xxs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: _isMention ? AppColors.mentionBackground : null,
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (message.type) {
      case MessageType.event:
        return _buildEventMessage();
      case MessageType.notice:
        return _buildNoticeMessage();
      case MessageType.error:
        return _buildErrorMessage();
      case MessageType.normal:
        if (message.isAction) {
          return _buildActionMessage();
        }
        return isCompact
            ? _buildCompactMessage(context)
            : _buildExpandedMessage(context);
    }
  }

  Widget _buildExpandedMessage(BuildContext context) {
    final nickColor = AppColors.nickColor(message.sender);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reply preview
        if (replyTo != null) ...[
          ReplyPreview(
            senderNickname: replyTo!.sender,
            content: replyTo!.content,
            isInline: true,
            onTap: onTapReply,
          ),
          AppSpacing.gapVerticalXs,
        ],

        // Header row: avatar, nickname, timestamp
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            GestureDetector(
              onTap: () => onUserTap?.call(message.sender),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: nickColor.withValues(alpha: 0.2),
                child: Text(
                  message.sender.isNotEmpty
                      ? message.sender[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: nickColor,
                  ),
                ),
              ),
            ),
            AppSpacing.gapSm,

            // Nickname
            GestureDetector(
              onTap: () => onUserTap?.call(message.sender),
              child: Text(
                message.sender,
                style: AppTextStyles.nicknameColored(nickColor),
              ),
            ),

            AppSpacing.gapSm,

            // Timestamp
            if (showTimestamp)
              Text(
                _formatTime(message.timestamp),
                style: AppTextStyles.timestamp,
              ),

            const Spacer(),

            // Reply button
            if (onReply != null)
              IconButton(
                onPressed: onReply,
                icon: const Icon(Icons.reply, size: 16),
                visualDensity: VisualDensity.compact,
                color: AppColors.textTertiary,
                tooltip: 'Reply',
              ),
          ],
        ),

        AppSpacing.gapVerticalXs,

        // Message content
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: _buildFormattedContent(),
        ),
      ],
    );
  }

  Widget _buildCompactMessage(BuildContext context) {
    final nickColor = AppColors.nickColor(message.sender);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timestamp
        if (showTimestamp)
          SizedBox(
            width: 48,
            child: Text(
              _formatTime(message.timestamp),
              style: AppTextStyles.timestamp,
            ),
          ),

        // Nickname
        SizedBox(
          width: 100,
          child: GestureDetector(
            onTap: () => onUserTap?.call(message.sender),
            child: Text(
              message.sender,
              style: AppTextStyles.nicknameColored(nickColor),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        AppSpacing.gapSm,

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (replyTo != null) ...[
                ReplyPreview(
                  senderNickname: replyTo!.sender,
                  content: replyTo!.content,
                  isInline: true,
                  onTap: onTapReply,
                ),
                AppSpacing.gapVerticalXs,
              ],
              _buildFormattedContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionMessage() {
    final nickColor = AppColors.nickColor(message.sender);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTimestamp)
          SizedBox(
            width: 48,
            child: Text(
              _formatTime(message.timestamp),
              style: AppTextStyles.timestamp,
            ),
          ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '* ${message.sender} ',
                  style: AppTextStyles.message.copyWith(
                    color: nickColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextSpan(
                  text: message.content,
                  style: AppTextStyles.message.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventMessage() {
    return Row(
      children: [
        if (showTimestamp)
          SizedBox(
            width: 48,
            child: Text(
              _formatTime(message.timestamp),
              style: AppTextStyles.timestamp,
            ),
          ),
        Icon(
          Icons.arrow_forward,
          size: 14,
          color: AppColors.success,
        ),
        AppSpacing.gapSm,
        Expanded(
          child: Text(
            message.content,
            style: AppTextStyles.serverMessage.copyWith(
              color: AppColors.success,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeMessage() {
    return Row(
      children: [
        if (showTimestamp)
          SizedBox(
            width: 48,
            child: Text(
              _formatTime(message.timestamp),
              style: AppTextStyles.timestamp,
            ),
          ),
        Icon(
          Icons.info_outline,
          size: 14,
          color: AppColors.info,
        ),
        AppSpacing.gapSm,
        Expanded(
          child: Text(
            '-${message.sender}- ${message.content}',
            style: AppTextStyles.serverMessage.copyWith(
              color: AppColors.info,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Row(
      children: [
        if (showTimestamp)
          SizedBox(
            width: 48,
            child: Text(
              _formatTime(message.timestamp),
              style: AppTextStyles.timestamp,
            ),
          ),
        Icon(
          Icons.error_outline,
          size: 14,
          color: AppColors.error,
        ),
        AppSpacing.gapSm,
        Expanded(
          child: Text(
            message.content,
            style: AppTextStyles.serverMessage.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormattedContent() {
    // Parse and display IRC formatting and links
    return IrcFormattedText(
      text: message.content,
      currentUserNick: currentUserNick,
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            ),

            // Message preview
            Padding(
              padding: AppSpacing.paddingLg,
              child: Text(
                message.content,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const Divider(height: 1),

            // Actions
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('View ${message.sender}'),
              onTap: () {
                Navigator.pop(context);
                onUserTap?.call(message.sender);
              },
            ),
            AppSpacing.gapVerticalSm,
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// Widget that renders IRC-formatted text with links and mentions.
class IrcFormattedText extends StatelessWidget {
  const IrcFormattedText({
    super.key,
    required this.text,
    this.currentUserNick,
  });

  final String text;
  final String? currentUserNick;

  static final _urlRegex = RegExp(
    r'https?://[^\s<>\[\]{}|\\^]+',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final spans = _parseText();

    return Text.rich(
      TextSpan(children: spans),
      style: AppTextStyles.message,
    );
  }

  List<InlineSpan> _parseText() {
    final spans = <InlineSpan>[];
    var currentIndex = 0;
    var isBold = false;
    var isItalic = false;
    var isUnderline = false;
    var currentFgColor = AppColors.textPrimary;

    // Find all URLs
    final urlMatches = _urlRegex.allMatches(text).toList();

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final charCode = char.codeUnitAt(0);

      // Check for IRC control codes
      switch (charCode) {
        case 0x02: // Bold
          if (currentIndex < i) {
            spans.add(_createSpan(
              text.substring(currentIndex, i),
              isBold,
              isItalic,
              isUnderline,
              currentFgColor,
            ));
          }
          isBold = !isBold;
          currentIndex = i + 1;
          continue;

        case 0x1D: // Italic
          if (currentIndex < i) {
            spans.add(_createSpan(
              text.substring(currentIndex, i),
              isBold,
              isItalic,
              isUnderline,
              currentFgColor,
            ));
          }
          isItalic = !isItalic;
          currentIndex = i + 1;
          continue;

        case 0x1F: // Underline
          if (currentIndex < i) {
            spans.add(_createSpan(
              text.substring(currentIndex, i),
              isBold,
              isItalic,
              isUnderline,
              currentFgColor,
            ));
          }
          isUnderline = !isUnderline;
          currentIndex = i + 1;
          continue;

        case 0x0F: // Reset
          if (currentIndex < i) {
            spans.add(_createSpan(
              text.substring(currentIndex, i),
              isBold,
              isItalic,
              isUnderline,
              currentFgColor,
            ));
          }
          isBold = false;
          isItalic = false;
          isUnderline = false;
          currentFgColor = AppColors.textPrimary;
          currentIndex = i + 1;
          continue;

        case 0x03: // Color
          if (currentIndex < i) {
            spans.add(_createSpan(
              text.substring(currentIndex, i),
              isBold,
              isItalic,
              isUnderline,
              currentFgColor,
            ));
          }
          // Parse color code (simplified - just skip digits)
          var j = i + 1;
          while (j < text.length && j < i + 3) {
            if (text.codeUnitAt(j) >= 0x30 && text.codeUnitAt(j) <= 0x39) {
              j++;
            } else {
              break;
            }
          }
          if (j > i + 1) {
            final colorCode = int.tryParse(text.substring(i + 1, j)) ?? 0;
            currentFgColor = AppColors.getIrcColor(colorCode);
          }
          // Skip background color if present
          if (j < text.length && text[j] == ',') {
            j++;
            while (j < text.length && j < i + 6) {
              if (text.codeUnitAt(j) >= 0x30 && text.codeUnitAt(j) <= 0x39) {
                j++;
              } else {
                break;
              }
            }
          }
          i = j - 1;
          currentIndex = j;
          continue;
      }

      // Check for URL at current position
      for (final match in urlMatches) {
        if (match.start == i && currentIndex <= i) {
          // Add text before URL
          if (currentIndex < i) {
            spans.add(_createSpan(
              text.substring(currentIndex, i),
              isBold,
              isItalic,
              isUnderline,
              currentFgColor,
            ));
          }
          // Add URL with link styling
          spans.add(TextSpan(
            text: match.group(0),
            style: AppTextStyles.message.copyWith(
              color: AppColors.info,
              decoration: TextDecoration.underline,
            ),
          ));
          currentIndex = match.end;
          i = match.end - 1;
          break;
        }
      }
    }

    // Add remaining text
    if (currentIndex < text.length) {
      final remaining = text.substring(currentIndex);
      spans.add(_createSpan(
        remaining,
        isBold,
        isItalic,
        isUnderline,
        currentFgColor,
      ));
    }

    // Highlight mentions
    if (currentUserNick != null) {
      return _highlightMentions(spans);
    }

    return spans;
  }

  TextSpan _createSpan(
    String text,
    bool bold,
    bool italic,
    bool underline,
    Color color,
  ) {
    return TextSpan(
      text: text,
      style: AppTextStyles.message.copyWith(
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        decoration: underline ? TextDecoration.underline : TextDecoration.none,
        color: color,
      ),
    );
  }

  List<InlineSpan> _highlightMentions(List<InlineSpan> spans) {
    if (currentUserNick == null) return spans;

    final result = <InlineSpan>[];
    final nickLower = currentUserNick!.toLowerCase();

    for (final span in spans) {
      if (span is TextSpan && span.text != null) {
        final text = span.text!;
        final textLower = text.toLowerCase();
        var lastEnd = 0;

        for (var i = 0; i <= textLower.length - nickLower.length; i++) {
          if (textLower.substring(i, i + nickLower.length) == nickLower) {
            // Check word boundaries
            final before = i > 0 ? textLower[i - 1] : ' ';
            final after = i + nickLower.length < textLower.length
                ? textLower[i + nickLower.length]
                : ' ';

            if (!RegExp(r'[a-z0-9]').hasMatch(before) &&
                !RegExp(r'[a-z0-9]').hasMatch(after)) {
              // Add text before mention
              if (lastEnd < i) {
                result.add(TextSpan(
                  text: text.substring(lastEnd, i),
                  style: span.style,
                ));
              }
              // Add highlighted mention
              result.add(TextSpan(
                text: text.substring(i, i + nickLower.length),
                style: span.style?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  backgroundColor: AppColors.mentionBackground,
                ),
              ));
              lastEnd = i + nickLower.length;
            }
          }
        }

        // Add remaining text
        if (lastEnd < text.length) {
          result.add(TextSpan(
            text: text.substring(lastEnd),
            style: span.style,
          ));
        }
      } else {
        result.add(span);
      }
    }

    return result;
  }
}

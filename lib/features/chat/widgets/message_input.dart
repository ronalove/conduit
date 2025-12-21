import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';

/// Message input field with send button and action buttons.
class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    this.onSend,
    this.onTyping,
    this.placeholder = 'Message',
    this.enabled = true,
  });

  /// Called when user sends a message.
  final void Function(String message)? onSend;

  /// Called when user starts/stops typing.
  final void Function(bool isTyping)? onTyping;

  /// Placeholder text.
  final String placeholder;

  /// Whether input is enabled.
  final bool enabled;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isTyping = _controller.text.isNotEmpty;
    if (isTyping != _isTyping) {
      _isTyping = isTyping;
      widget.onTyping?.call(isTyping);
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend?.call(text);
      _controller.clear();
      _isTyping = false;
      widget.onTyping?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          // Send on Enter (without Shift)
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              !HardwareKeyboard.instance.isShiftPressed) {
            _send();
          }
        },
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          maxLines: null,
          textInputAction: TextInputAction.newline,
          style: AppTextStyles.input,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: AppTextStyles.inputHint,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
      ),
    );
  }
}

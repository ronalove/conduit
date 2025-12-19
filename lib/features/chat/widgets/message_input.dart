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
  bool _showFormatting = false;

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

  void _insertFormatting(String prefix, [String? suffix]) {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.isValid && selection.start != selection.end) {
      // Wrap selection
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText${suffix ?? prefix}',
      );
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.end + prefix.length + (suffix?.length ?? prefix.length),
        ),
      );
    } else {
      // Insert at cursor
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        prefix,
      );
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length,
        ),
      );
    }
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Formatting toolbar
        if (_showFormatting) _buildFormattingBar(),

        // Main input row
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.divider),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Action buttons
              _buildActionButton(
                icon: Icons.add,
                tooltip: 'Attach',
                onPressed: () {
                  // TODO: Implement file attachment
                },
              ),
              _buildActionButton(
                icon: Icons.format_bold,
                tooltip: 'Formatting',
                isActive: _showFormatting,
                onPressed: () {
                  setState(() {
                    _showFormatting = !_showFormatting;
                  });
                },
              ),

              AppSpacing.gapSm,

              // Text input
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: AppSpacing.borderRadiusMd,
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
                        contentPadding: AppSpacing.inputPadding,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),

              AppSpacing.gapSm,

              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                child: IconButton(
                  onPressed: _controller.text.isNotEmpty ? _send : null,
                  icon: Icon(
                    Icons.send,
                    color: _controller.text.isNotEmpty
                        ? AppColors.primary
                        : AppColors.textDisabled,
                  ),
                  tooltip: 'Send',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    bool isActive = false,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: widget.enabled ? onPressed : null,
      icon: Icon(
        icon,
        size: 22,
        color: isActive
            ? AppColors.primary
            : (widget.enabled ? AppColors.textSecondary : AppColors.textDisabled),
      ),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildFormattingBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          _buildFormatButton(
            icon: Icons.format_bold,
            tooltip: 'Bold (Ctrl+B)',
            onPressed: () => _insertFormatting('\x02'),
          ),
          _buildFormatButton(
            icon: Icons.format_italic,
            tooltip: 'Italic (Ctrl+I)',
            onPressed: () => _insertFormatting('\x1D'),
          ),
          _buildFormatButton(
            icon: Icons.format_underlined,
            tooltip: 'Underline (Ctrl+U)',
            onPressed: () => _insertFormatting('\x1F'),
          ),
          _buildFormatButton(
            icon: Icons.strikethrough_s,
            tooltip: 'Strikethrough',
            onPressed: () => _insertFormatting('\x1E'),
          ),
          const VerticalDivider(
            width: AppSpacing.lg,
            indent: AppSpacing.sm,
            endIndent: AppSpacing.sm,
          ),
          _buildFormatButton(
            icon: Icons.code,
            tooltip: 'Monospace',
            onPressed: () => _insertFormatting('\x11'),
          ),
          _buildFormatButton(
            icon: Icons.palette,
            tooltip: 'Color',
            onPressed: () {
              // TODO: Show color picker
            },
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _insertFormatting('\x0F'),
            child: Text(
              'Reset',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      color: AppColors.textSecondary,
    );
  }
}

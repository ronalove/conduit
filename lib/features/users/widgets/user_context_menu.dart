import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../models/channel_user.dart';

/// Actions available in the user context menu.
enum UserAction {
  /// Open a private message with the user.
  privateMessage,

  /// View user information (WHOIS).
  whois,

  /// Give operator status to user.
  op,

  /// Remove operator status from user.
  deop,

  /// Give voice to user.
  voice,

  /// Remove voice from user.
  devoice,

  /// Kick user from channel.
  kick,

  /// Ban user from channel.
  ban,
}

/// Context menu for user actions.
///
/// Shows a popup menu with actions like PM, WHOIS, and moderator actions.
class UserContextMenu {
  const UserContextMenu._();

  /// Shows the context menu at the given position.
  ///
  /// Returns the selected [UserAction] or null if cancelled.
  static Future<UserAction?> show({
    required BuildContext context,
    required ChannelUser user,
    required Offset position,
    bool hasOperatorPrivileges = false,
    bool isCurrentUser = false,
  }) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    final items = <PopupMenuEntry<UserAction>>[];

    // Always show PM and WHOIS (except for self)
    if (!isCurrentUser) {
      items.add(_buildMenuItem(
        value: UserAction.privateMessage,
        icon: Icons.chat_bubble_outline,
        label: 'Message prive',
      ));
    }

    items.add(_buildMenuItem(
      value: UserAction.whois,
      icon: Icons.person_outline,
      label: 'Informations',
    ));

    // Moderator actions (only if we have privileges and not targeting ourselves)
    if (hasOperatorPrivileges && !isCurrentUser) {
      items.add(const PopupMenuDivider());

      // Op/Deop
      if (user.mode == UserMode.operator) {
        items.add(_buildMenuItem(
          value: UserAction.deop,
          icon: Icons.remove_moderator_outlined,
          label: 'Retirer operateur',
        ));
      } else {
        items.add(_buildMenuItem(
          value: UserAction.op,
          icon: Icons.shield_outlined,
          label: 'Donner operateur',
        ));
      }

      // Voice/Devoice
      if (user.mode == UserMode.voice) {
        items.add(_buildMenuItem(
          value: UserAction.devoice,
          icon: Icons.mic_off_outlined,
          label: 'Retirer voice',
        ));
      } else if (user.mode != UserMode.operator && user.mode != UserMode.halfOp) {
        items.add(_buildMenuItem(
          value: UserAction.voice,
          icon: Icons.mic_outlined,
          label: 'Donner voice',
        ));
      }

      items.add(const PopupMenuDivider());

      // Kick and ban
      items.add(_buildMenuItem(
        value: UserAction.kick,
        icon: Icons.exit_to_app,
        label: 'Expulser',
        isDestructive: true,
      ));

      items.add(_buildMenuItem(
        value: UserAction.ban,
        icon: Icons.block,
        label: 'Bannir',
        isDestructive: true,
      ));
    }

    return showMenu<UserAction>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: items,
      elevation: 8,
      color: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
    );
  }

  static PopupMenuItem<UserAction> _buildMenuItem({
    required UserAction value,
    required IconData icon,
    required String label,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return PopupMenuItem<UserAction>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  /// Shows the context menu for a long press on mobile.
  static Future<UserAction?> showForLongPress({
    required BuildContext context,
    required ChannelUser user,
    required LongPressStartDetails details,
    bool hasOperatorPrivileges = false,
    bool isCurrentUser = false,
  }) {
    return show(
      context: context,
      user: user,
      position: details.globalPosition,
      hasOperatorPrivileges: hasOperatorPrivileges,
      isCurrentUser: isCurrentUser,
    );
  }

  /// Shows the context menu for a right click on desktop.
  static Future<UserAction?> showForRightClick({
    required BuildContext context,
    required ChannelUser user,
    required TapDownDetails details,
    bool hasOperatorPrivileges = false,
    bool isCurrentUser = false,
  }) {
    return show(
      context: context,
      user: user,
      position: details.globalPosition,
      hasOperatorPrivileges: hasOperatorPrivileges,
      isCurrentUser: isCurrentUser,
    );
  }
}

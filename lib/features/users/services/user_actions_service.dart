import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/irc/commands/channel_commands.dart';
import '../../../core/irc/commands/connection_commands.dart';
import '../../channels/providers/channels_provider.dart';
import '../../connection/providers/connection_provider.dart';
import '../../connection/providers/irc_session_manager.dart';
import '../models/channel_user.dart';
import '../widgets/user_context_menu.dart';
import '../widgets/user_info_dialog.dart';

/// Service to handle user-related actions from the UI.
class UserActionsService {
  const UserActionsService._();

  /// Handles user tap - shows context menu on desktop, info dialog on mobile.
  static Future<void> handleUserTap({
    required BuildContext context,
    required WidgetRef ref,
    required ChannelUser user,
    required String channelName,
    required TapUpDetails details,
  }) async {
    // Show context menu at tap position
    final action = await UserContextMenu.show(
      context: context,
      user: user,
      position: details.globalPosition,
      hasOperatorPrivileges: _hasOperatorPrivileges(ref, channelName),
      isCurrentUser: _isCurrentUser(ref, user.nickname),
    );

    if (action != null && context.mounted) {
      await _handleAction(
        context: context,
        ref: ref,
        action: action,
        user: user,
        channelName: channelName,
      );
    }
  }

  /// Handles user long press - shows context menu.
  static Future<void> handleUserLongPress({
    required BuildContext context,
    required WidgetRef ref,
    required ChannelUser user,
    required String channelName,
    required LongPressStartDetails details,
  }) async {
    final action = await UserContextMenu.showForLongPress(
      context: context,
      user: user,
      details: details,
      hasOperatorPrivileges: _hasOperatorPrivileges(ref, channelName),
      isCurrentUser: _isCurrentUser(ref, user.nickname),
    );

    if (action != null && context.mounted) {
      await _handleAction(
        context: context,
        ref: ref,
        action: action,
        user: user,
        channelName: channelName,
      );
    }
  }

  /// Handles the selected action from the context menu.
  static Future<void> _handleAction({
    required BuildContext context,
    required WidgetRef ref,
    required UserAction action,
    required ChannelUser user,
    required String channelName,
  }) async {
    switch (action) {
      case UserAction.privateMessage:
        _openPrivateMessage(ref, user.nickname);

      case UserAction.whois:
        await _showUserInfo(context, ref, user);

      case UserAction.op:
        _setUserMode(ref, channelName, user.nickname, '+o');

      case UserAction.deop:
        _setUserMode(ref, channelName, user.nickname, '-o');

      case UserAction.voice:
        _setUserMode(ref, channelName, user.nickname, '+v');

      case UserAction.devoice:
        _setUserMode(ref, channelName, user.nickname, '-v');

      case UserAction.kick:
        await _showKickDialog(context, ref, channelName, user.nickname);

      case UserAction.ban:
        await _showBanDialog(context, ref, channelName, user);
    }
  }

  /// Opens a private message with the user.
  static void _openPrivateMessage(WidgetRef ref, String nickname) {
    // For now, just select the channel as a PM target
    // TODO: Implement proper PM/query support
    final channelsNotifier = ref.read(channelsProvider.notifier);
    channelsNotifier.selectChannel(nickname);
  }

  /// Shows user info dialog with WHOIS data.
  static Future<void> _showUserInfo(
    BuildContext context,
    WidgetRef ref,
    ChannelUser user,
  ) async {
    // Send WHOIS command
    _sendCommand(ref, WhoisCommand(user.nickname).toRaw());

    // Show dialog with current info (WHOIS response will update it)
    await UserInfoDialog.show(
      context: context,
      user: user,
      onRefresh: () {
        _sendCommand(ref, WhoisCommand(user.nickname).toRaw());
      },
    );
  }

  /// Sets a mode on a user in a channel.
  static void _setUserMode(
    WidgetRef ref,
    String channelName,
    String nickname,
    String mode,
  ) {
    final cmd = ModeCommand.channel(channelName, mode, args: [nickname]);
    _sendCommand(ref, cmd.toRaw());
  }

  /// Shows kick confirmation dialog.
  static Future<void> _showKickDialog(
    BuildContext context,
    WidgetRef ref,
    String channelName,
    String nickname,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Expulser $nickname'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Raison (optionnel)',
            hintText: 'Entrez une raison...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Expulser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.isEmpty ? null : reasonController.text;
      final cmd = KickCommand(
        channel: channelName,
        nick: nickname,
        reason: reason,
      );
      _sendCommand(ref, cmd.toRaw());
    }

    reasonController.dispose();
  }

  /// Shows ban dialog.
  static Future<void> _showBanDialog(
    BuildContext context,
    WidgetRef ref,
    String channelName,
    ChannelUser user,
  ) async {
    // Generate ban mask from user info
    final banMask = user.hostname != null
        ? '*!*@${user.hostname}'
        : '${user.nickname}!*@*';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bannir ${user.nickname}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masque de ban:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                banMask,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Voulez-vous aussi expulser l\'utilisateur?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          OutlinedButton(
            onPressed: () {
              // Ban only
              final cmd = ModeCommand.channel(channelName, '+b', args: [banMask]);
              _sendCommand(ref, cmd.toRaw());
              Navigator.of(context).pop(false);
            },
            child: const Text('Bannir seulement'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Bannir et expulser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Ban and kick
      final banCmd = ModeCommand.channel(channelName, '+b', args: [banMask]);
      final kickCmd = KickCommand(
        channel: channelName,
        nick: user.nickname,
        reason: 'Banned',
      );
      _sendCommand(ref, banCmd.toRaw());
      _sendCommand(ref, kickCmd.toRaw());
    }
  }

  /// Checks if the current user has operator privileges in the channel.
  static bool _hasOperatorPrivileges(WidgetRef ref, String channelName) {
    final session = ref.read(ircSessionProvider);
    final myNick = session.nickname;
    if (myNick == null) return false;

    final channelsState = ref.read(channelsProvider);
    final channel = channelsState.getChannel(channelName);
    if (channel == null) return false;

    final myUser = channel.getUser(myNick);
    return myUser?.hasPrivileges ?? false;
  }

  /// Checks if the given nickname is the current user.
  static bool _isCurrentUser(WidgetRef ref, String nickname) {
    final session = ref.read(ircSessionProvider);
    return session.nickname?.toLowerCase() == nickname.toLowerCase();
  }

  /// Sends a raw IRC command.
  static void _sendCommand(WidgetRef ref, String command) {
    try {
      ref.read(connectionProvider.notifier).send(command);
    } catch (_) {
      // Ignore send errors
    }
  }
}

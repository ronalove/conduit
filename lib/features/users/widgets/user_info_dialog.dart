import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';
import '../models/channel_user.dart';
import 'user_avatar.dart';

/// Information about a user from WHOIS response.
class WhoisInfo {
  const WhoisInfo({
    required this.nickname,
    this.username,
    this.hostname,
    this.realname,
    this.server,
    this.serverInfo,
    this.isOperator = false,
    this.isAway = false,
    this.awayMessage,
    this.idleSeconds,
    this.signonTime,
    this.channels = const [],
    this.account,
    this.isSecure = false,
  });

  /// User's nickname.
  final String nickname;

  /// User's username (ident).
  final String? username;

  /// User's hostname.
  final String? hostname;

  /// User's real name (gecos).
  final String? realname;

  /// Server the user is connected to.
  final String? server;

  /// Server info text.
  final String? serverInfo;

  /// Whether the user is an IRC operator.
  final bool isOperator;

  /// Whether the user is away.
  final bool isAway;

  /// Away message if set.
  final String? awayMessage;

  /// Idle time in seconds.
  final int? idleSeconds;

  /// Signon time as Unix timestamp.
  final DateTime? signonTime;

  /// Channels the user is in.
  final List<String> channels;

  /// Account name if logged in.
  final String? account;

  /// Whether user is using a secure connection.
  final bool isSecure;

  /// Format idle time as human readable string.
  String get idleTimeFormatted {
    if (idleSeconds == null) return 'Inconnu';

    final seconds = idleSeconds!;
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
    if (seconds < 86400) {
      final hours = seconds ~/ 3600;
      final mins = (seconds % 3600) ~/ 60;
      return '${hours}h ${mins}m';
    }
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    return '${days}j ${hours}h';
  }

  /// Create WhoisInfo from a ChannelUser (partial info).
  factory WhoisInfo.fromChannelUser(ChannelUser user) {
    return WhoisInfo(
      nickname: user.nickname,
      hostname: user.hostname,
      realname: user.realname,
      account: user.account,
      isAway: user.isAway,
      awayMessage: user.awayMessage,
    );
  }
}

/// Dialog showing detailed user information.
class UserInfoDialog extends StatelessWidget {
  const UserInfoDialog({
    super.key,
    required this.user,
    this.whoisInfo,
    this.channelMode,
    this.isLoading = false,
    this.onRefresh,
  });

  /// Basic user info from channel.
  final ChannelUser user;

  /// Extended WHOIS info (optional).
  final WhoisInfo? whoisInfo;

  /// User's mode in the current channel.
  final UserMode? channelMode;

  /// Whether WHOIS info is currently loading.
  final bool isLoading;

  /// Callback to refresh WHOIS info.
  final VoidCallback? onRefresh;

  /// Shows the dialog.
  static Future<void> show({
    required BuildContext context,
    required ChannelUser user,
    WhoisInfo? whoisInfo,
    UserMode? channelMode,
    bool isLoading = false,
    VoidCallback? onRefresh,
  }) {
    return showDialog(
      context: context,
      builder: (context) => UserInfoDialog(
        user: user,
        whoisInfo: whoisInfo,
        channelMode: channelMode,
        isLoading: isLoading,
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = whoisInfo ?? WhoisInfo.fromChannelUser(user);
    final mode = channelMode ?? user.mode;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with avatar and name
            _buildHeader(info, mode),

            const Divider(height: 1),

            // Info sections
            Flexible(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (info.isAway && info.awayMessage != null) ...[
                      _buildInfoSection(
                        icon: Icons.schedule,
                        label: 'Absent',
                        value: info.awayMessage!,
                        color: AppColors.warning,
                      ),
                      AppSpacing.gapMd,
                    ],

                    if (info.realname != null) ...[
                      _buildInfoSection(
                        icon: Icons.badge_outlined,
                        label: 'Nom reel',
                        value: info.realname!,
                      ),
                      AppSpacing.gapMd,
                    ],

                    if (info.account != null) ...[
                      _buildInfoSection(
                        icon: Icons.account_circle_outlined,
                        label: 'Compte',
                        value: info.account!,
                        canCopy: true,
                      ),
                      AppSpacing.gapMd,
                    ],

                    if (info.hostname != null) ...[
                      _buildInfoSection(
                        icon: Icons.dns_outlined,
                        label: 'Hote',
                        value: info.hostname!,
                        canCopy: true,
                      ),
                      AppSpacing.gapMd,
                    ],

                    if (info.server != null) ...[
                      _buildInfoSection(
                        icon: Icons.cloud_outlined,
                        label: 'Serveur',
                        value: info.server!,
                        subtitle: info.serverInfo,
                      ),
                      AppSpacing.gapMd,
                    ],

                    if (info.idleSeconds != null) ...[
                      _buildInfoSection(
                        icon: Icons.access_time,
                        label: 'Inactif depuis',
                        value: info.idleTimeFormatted,
                      ),
                      AppSpacing.gapMd,
                    ],

                    if (info.signonTime != null) ...[
                      _buildInfoSection(
                        icon: Icons.login,
                        label: 'Connecte depuis',
                        value: _formatDateTime(info.signonTime!),
                      ),
                      AppSpacing.gapMd,
                    ],

                    if (info.channels.isNotEmpty) ...[
                      _buildInfoSection(
                        icon: Icons.tag,
                        label: 'Canaux',
                        value: info.channels.join(', '),
                      ),
                      AppSpacing.gapMd,
                    ],

                    // Status badges
                    if (info.isOperator || info.isSecure) ...[
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          if (info.isOperator)
                            _buildBadge('IRC Operator', AppColors.operator),
                          if (info.isSecure)
                            _buildBadge('Connexion securisee', AppColors.success),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: AppSpacing.paddingSm,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onRefresh != null)
                    TextButton.icon(
                      onPressed: isLoading ? null : onRefresh,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 18),
                      label: const Text('Actualiser'),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(WhoisInfo info, UserMode mode) {
    return Padding(
      padding: AppSpacing.paddingMd,
      child: Row(
        children: [
          UserAvatar(
            nickname: info.nickname,
            mode: mode,
            isAway: info.isAway,
            size: AvatarSize.large,
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.nickname,
                  style: AppTextStyles.headlineMedium,
                ),
                if (info.username != null && info.hostname != null)
                  Text(
                    '${info.username}@${info.hostname}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    Color? color,
    bool canCopy = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? AppColors.textSecondary,
        ),
        AppSpacing.gapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: color ?? AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (canCopy)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: value));
                      },
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Copier',
                    ),
                ],
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}j ${diff.inHours % 24}h';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    } else {
      return '${diff.inMinutes}m';
    }
  }
}

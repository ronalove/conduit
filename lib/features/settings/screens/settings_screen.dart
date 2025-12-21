import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

/// Settings screen with all app settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    this.onBack,
  });

  /// Called when back button is pressed.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
      ),
      body: ListView(
        children: [
          // Account section
          _buildSection(
            context,
            title: 'Account',
            children: [
              _AccountTile(ref: ref),
            ],
          ),

          // Appearance section
          _buildSection(
            context,
            title: 'Appearance',
            children: [
              _ThemeColorTile(ref: ref),
              _buildDivider(),
              _SettingsSwitch(
                title: 'Compact Mode',
                subtitle: 'Use compact message display',
                icon: Icons.view_compact,
                value: ref.watch(settingsProvider).compactMode,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setCompactMode(value);
                },
              ),
              _buildDivider(),
              _SettingsSwitch(
                title: 'Show Timestamps',
                subtitle: 'Display message timestamps',
                icon: Icons.access_time,
                value: ref.watch(settingsProvider).showTimestamps,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setShowTimestamps(value);
                },
              ),
            ],
          ),

          // Notifications section
          _buildSection(
            context,
            title: 'Notifications',
            children: [
              _SettingsSwitch(
                title: 'Enable Notifications',
                subtitle: 'Receive push notifications',
                icon: Icons.notifications_outlined,
                value: ref.watch(settingsProvider).notificationsEnabled,
                onChanged: (value) {
                  ref
                      .read(settingsProvider.notifier)
                      .setNotificationsEnabled(value);
                },
              ),
              _buildDivider(),
              _SettingsSwitch(
                title: 'Sound',
                subtitle: 'Play notification sounds',
                icon: Icons.volume_up_outlined,
                value: ref.watch(settingsProvider).soundEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setSoundEnabled(value);
                },
              ),
            ],
          ),

          // Connection section
          _buildSection(
            context,
            title: 'Connection',
            children: [
              _SettingsTile(
                title: 'Server',
                subtitle: 'irc.example.com:6697',
                icon: Icons.dns_outlined,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    'Connected',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ),
              _buildDivider(),
              _SettingsTile(
                title: 'Encryption',
                subtitle: 'TLS 1.3',
                icon: Icons.lock_outline,
                trailing: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
            ],
          ),

          // Data section
          _buildSection(
            context,
            title: 'Data',
            children: [
              _SettingsTile(
                title: 'Export Settings',
                subtitle: 'Save settings to file',
                icon: Icons.upload_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export not implemented yet')),
                  );
                },
              ),
              _buildDivider(),
              _SettingsTile(
                title: 'Import Settings',
                subtitle: 'Load settings from file',
                icon: Icons.download_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Import not implemented yet')),
                  );
                },
              ),
              _buildDivider(),
              _SettingsTile(
                title: 'Clear Local Data',
                subtitle: 'Delete all cached data',
                icon: Icons.delete_outline,
                iconColor: AppColors.error,
                onTap: () => _showClearDataDialog(context, ref),
              ),
            ],
          ),

          // About section
          _buildSection(
            context,
            title: 'About',
            children: [
              _SettingsTile(
                title: 'Version',
                subtitle: '1.0.0 (Build 1)',
                icon: Icons.info_outline,
              ),
              _buildDivider(),
              _SettingsTile(
                title: 'Licenses',
                subtitle: 'Open source licenses',
                icon: Icons.description_outlined,
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'Knights Network',
                    applicationVersion: '1.0.0',
                  );
                },
              ),
              _buildDivider(),
              _SettingsTile(
                title: 'Source Code',
                subtitle: 'github.com/r9r-dev/conduit',
                icon: Icons.code,
              ),
            ],
          ),

          // Logout button
          Padding(
            padding: AppSpacing.paddingLg,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, ref),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                'Logout',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),

          AppSpacing.gapVerticalXxl,
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: AppSpacing.lg + 24 + AppSpacing.md,
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
          'This will delete all cached messages and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).clearSettings();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Local data cleared')),
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to disconnect?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(context);
            },
            child: Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Account tile showing logged in user.
class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final username = authState.username ?? 'Unknown';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(username, style: AppTextStyles.bodyMedium),
      subtitle: Text(
        'Logged in',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.success,
        ),
      ),
    );
  }
}

/// Theme color selection tile.
class _ThemeColorTile extends StatelessWidget {
  const _ThemeColorTile({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider).themeColor;

    return ListTile(
      leading: const Icon(Icons.palette_outlined, size: 24),
      title: const Text('Theme Color'),
      subtitle: Text(currentTheme.displayName),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: ColorPalettes.getPrimary(currentTheme),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.divider,
            width: 2,
          ),
        ),
      ),
      onTap: () => _showColorPicker(context),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
      ),
      builder: (context) => _ColorPickerSheet(ref: ref),
    );
  }
}

/// Color picker bottom sheet.
class _ColorPickerSheet extends ConsumerWidget {
  const _ColorPickerSheet({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider).themeColor;

    return SafeArea(
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

          // Title
          Padding(
            padding: AppSpacing.paddingLg,
            child: Text(
              'Choose Theme Color',
              style: AppTextStyles.headlineMedium,
            ),
          ),

          // Color grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: ColorPalettes.allOptions.map((option) {
                final isSelected = option.theme == currentTheme;

                return GestureDetector(
                  onTap: () {
                    ref.read(themeProvider.notifier).setThemeColor(option.theme);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? option.primary.withValues(alpha: 0.2)
                          : AppColors.surfaceContainer,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: isSelected
                          ? Border.all(color: option.primary, width: 2)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [option.primary, option.secondary],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                        AppSpacing.gapVerticalXs,
                        Text(
                          option.name,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected
                                ? option.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          AppSpacing.gapVerticalXxl,
        ],
      ),
    );
  }
}

/// Generic settings tile.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, size: 24, color: iconColor ?? AppColors.textSecondary)
          : null,
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textTertiary)
              : null),
      onTap: onTap,
    );
  }
}

/// Settings switch tile.
class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, size: 24, color: AppColors.textSecondary)
          : null,
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }
}

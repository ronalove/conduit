import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'features/auth/auth.dart';
import 'features/channels/channels.dart';
import 'features/chat/chat.dart';
import 'features/chat/providers/messages_provider.dart';
import 'features/connection/connection.dart';
import 'features/connection/widgets/irc_logs_view.dart';
import 'features/settings/settings.dart';
import 'features/settings/providers/window_geometry_provider.dart';
import 'features/users/users.dart';
import 'layouts/layouts.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure window on desktop platforms
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();

    final geometry = await WindowGeometryNotifier.loadFromPrefs();

    final windowOptions = WindowOptions(
      size: Size(geometry.width, geometry.height),
      minimumSize: const Size(800, 600),
      center: geometry.x == null || geometry.y == null,
      skipTaskbar: false,
      titleBarStyle: Platform.isMacOS
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (geometry.x != null && geometry.y != null) {
        await windowManager.setPosition(Offset(geometry.x!, geometry.y!));
      }
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    const ProviderScope(
      child: ConduitApp(),
    ),
  );
}

class ConduitApp extends ConsumerWidget {
  const ConduitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Knights Network',
      debugShowCheckedModeBanner: false,
      theme: themeState.themeData,
      home: const _DesktopWrapper(child: AuthGate()),
    );
  }
}

/// Wrapper that adds the custom title bar on desktop platforms.
class _DesktopWrapper extends ConsumerStatefulWidget {
  const _DesktopWrapper({required this.child});

  final Widget child;

  @override
  ConsumerState<_DesktopWrapper> createState() => _DesktopWrapperState();
}

class _DesktopWrapperState extends ConsumerState<_DesktopWrapper>
    with WidgetsBindingObserver {
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Periodically save window geometry on desktop
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      _saveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _saveGeometry();
      });
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save geometry when app goes to background or is closing
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveGeometry();
    }

    // Disconnect IRC session when app is closing
    if (state == AppLifecycleState.detached) {
      _disconnectSession();
    }
  }

  Future<void> _disconnectSession() async {
    debugPrint('[Knights Network] Fermeture de l\'application...');
    try {
      await ref.read(ircSessionProvider.notifier).endSession();
      debugPrint('[Knights Network] Session IRC déconnectée.');
    } catch (_) {
      // Ignore errors during shutdown
    }
    debugPrint('[Knights Network] Au revoir !');
  }

  Future<void> _saveGeometry() async {
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    final position = await windowManager.getPosition();
    final size = await windowManager.getSize();

    ref.read(windowGeometryProvider.notifier).saveGeometry(
          x: position.dx,
          y: position.dy,
          width: size.width,
          height: size.height,
        );
  }

  @override
  Widget build(BuildContext context) {
    // On mobile, just return the child
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
      return widget.child;
    }

    // On desktop, wrap with title bar
    return Column(
      children: [
        const WindowTitleBar(),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Switches between login screen and main app based on auth state.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _checkingCredentials = true;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    try {
      await ref.read(authProvider.notifier).tryAutoLogin();
    } finally {
      if (mounted) {
        setState(() => _checkingCredentials = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show loading while checking stored credentials
    if (_checkingCredentials) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState.isAuthenticated) {
      return const LayoutDemo();
    }

    return const LoginScreen();
  }
}

/// Main app layout with real IRC data.
class LayoutDemo extends ConsumerStatefulWidget {
  const LayoutDemo({super.key});

  @override
  ConsumerState<LayoutDemo> createState() => _LayoutDemoState();
}

class _LayoutDemoState extends ConsumerState<LayoutDemo> {
  bool _showSettings = false;
  bool _showLogs = false;

  @override
  Widget build(BuildContext context) {
    // Watch channel providers
    final channels = ref.watch(channelListProvider);
    final selectedChannel = ref.watch(selectedChannelProvider);
    final session = ref.watch(ircSessionProvider);
    final channelsNotifier = ref.read(channelsProvider.notifier);
    final messagesNotifier = ref.read(messagesProvider.notifier);

    // Watch messages for selected channel
    final messagesState = ref.watch(currentChannelMessagesProvider);

    // Get selected channel name
    final selectedChannelName = selectedChannel?.name;
    final selectedTopic = selectedChannel?.topicText;

    // Load messages when channel is selected
    if (selectedChannelName != null && messagesState == null) {
      Future.microtask(() => messagesNotifier.loadChannelMessages(selectedChannelName));
    }

    // Show settings screen
    if (_showSettings) {
      return SettingsScreen(
        onBack: () => setState(() => _showSettings = false),
      );
    }

    return Scaffold(
      body: AdaptiveLayout(
        mobile: _MobilePlaceholder(
          onOpenSettings: () => setState(() => _showSettings = true),
        ),
        // Tablet uses desktop layout (no tablet parameter = fallback to desktop)
        desktop: DesktopLayout(
          channelsSidebar: Column(
            children: [
              Expanded(
                child: ChannelListScreen(
                  channels: channels,
                  privateMessages: const [], // TODO: implement DMs
                  selectedChannel: selectedChannelName,
                  onChannelTap: (name, type) {
                    if (type == ChannelType.channel) {
                      channelsNotifier.selectChannel(name);
                      channelsNotifier.markAsRead(name);
                      messagesNotifier.markChannelAsRead(name);
                      // Fermer les logs si ouverts
                      if (_showLogs) {
                        setState(() => _showLogs = false);
                      }
                    }
                  },
                  onLeaveChannel: (name) {
                    channelsNotifier.partChannel(name);
                  },
                  onBrowseChannels: () {
                    _showBrowseChannelsDialog(context);
                  },
                  onAddChannel: () {
                    _showJoinChannelDialog(context);
                  },
                ),
              ),
              // Bottom bar with server status and settings
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    // Server status indicator
                    GestureDetector(
                      onTap: () => setState(() => _showLogs = !_showLogs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: session.isReady ? AppColors.success : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'ke.network',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Settings button
                    InkWell(
                      onTap: () => setState(() => _showSettings = true),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.settings, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Paramètres',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          chatArea: _showLogs
              ? _buildLogsView()
              : ChatScreen(
                  channelName: selectedChannelName ?? 'Aucun canal sélectionné',
                  topic: selectedTopic,
                  messages: messagesState?.messages ?? [],
                  isLoadingHistory: messagesState?.isLoadingHistory ?? false,
                  typingUsers: const [], // TODO: connect to typing provider
                  showHeader: false,
                  onSendMessage: (msg) {
                    if (selectedChannelName != null) {
                      messagesNotifier.sendMessage(selectedChannelName, msg);
                    }
                  },
                  onLoadMore: selectedChannelName != null
                      ? () => messagesNotifier.loadMoreHistory(selectedChannelName)
                      : null,
                ),
          usersSidebar: _UserListWithActions(
            users: selectedChannel?.sortedUsers ?? [],
            channelName: selectedChannelName,
          ),
        ),
      ),
    );
  }

  Widget _buildLogsView() {
    final logs = ref.watch(ircLogsProvider);
    final currentNick = ref.watch(authProvider).username;

    return Column(
      children: [
        // Header
        Container(
          height: AppSpacing.appBarHeight,
          padding: AppSpacing.paddingHorizontalLg,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              const Icon(Icons.terminal, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Logs IRC',
                style: AppTextStyles.headlineMedium,
              ),
              const Spacer(),
              Text(
                '${logs.length} lignes',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        // Logs content
        Expanded(
          child: Container(
            color: AppColors.surfaceContainer,
            child: IrcLogsView(logs: logs, currentNick: currentNick),
          ),
        ),
      ],
    );
  }

  void _showJoinChannelDialog(BuildContext context) {
    final controller = TextEditingController();
    final channelsNotifier = ref.read(channelsProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejoindre un canal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '#canal',
            labelText: 'Nom du canal',
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              final channel = value.startsWith('#') ? value : '#$value';
              channelsNotifier.joinChannel(channel);
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text;
              if (value.isNotEmpty) {
                final channel = value.startsWith('#') ? value : '#$value';
                channelsNotifier.joinChannel(channel);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Rejoindre'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBrowseChannelsDialog(BuildContext context) async {
    final channelsNotifier = ref.read(channelsProvider.notifier);

    final channelName = await ChannelListDialog.show(context);
    if (channelName != null) {
      channelsNotifier.joinChannel(channelName);
    }
  }
}

class _MobilePlaceholder extends ConsumerWidget {
  const _MobilePlaceholder({
    this.onOpenSettings,
  });

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch channel providers
    final channels = ref.watch(channelListProvider);
    final selectedChannel = ref.watch(selectedChannelProvider);
    final channelsNotifier = ref.read(channelsProvider.notifier);
    final messagesNotifier = ref.read(messagesProvider.notifier);

    // Watch messages for selected channel
    final messagesState = ref.watch(currentChannelMessagesProvider);

    final selectedChannelName = selectedChannel?.name;
    final selectedTopic = selectedChannel?.topicText;

    // Load messages when channel is selected
    if (selectedChannelName != null && messagesState == null) {
      Future.microtask(() => messagesNotifier.loadChannelMessages(selectedChannelName));
    }

    return MobileLayout(
      channelsPage: ChannelListScreen(
        channels: channels,
        privateMessages: const [], // TODO: implement DMs
        selectedChannel: selectedChannelName,
        onChannelTap: (name, type) {
          if (type == ChannelType.channel) {
            channelsNotifier.selectChannel(name);
            channelsNotifier.markAsRead(name);
            messagesNotifier.markChannelAsRead(name);
          }
        },
        onLeaveChannel: (name) {
          channelsNotifier.partChannel(name);
        },
        onBrowseChannels: () {
          _showBrowseChannelsDialog(context, ref);
        },
        onAddChannel: () {
          _showJoinChannelDialog(context, ref);
        },
      ),
      chatPage: ChatScreen(
        channelName: selectedChannelName ?? 'Aucun canal sélectionné',
        topic: selectedTopic,
        messages: messagesState?.messages ?? [],
        isLoadingHistory: messagesState?.isLoadingHistory ?? false,
        typingUsers: const [], // TODO: connect to typing provider
        showHeader: true,
        onBack: () {},
        onShowUsers: () {},
        onSendMessage: (msg) {
          if (selectedChannelName != null) {
            messagesNotifier.sendMessage(selectedChannelName, msg);
          }
        },
        onLoadMore: selectedChannelName != null
            ? () => messagesNotifier.loadMoreHistory(selectedChannelName)
            : null,
      ),
      usersPage: _UserListWithActions(
        users: selectedChannel?.sortedUsers ?? [],
        channelName: selectedChannelName,
      ),
      settingsPage: SettingsScreen(
        onBack: onOpenSettings,
      ),
    );
  }

  void _showJoinChannelDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final channelsNotifier = ref.read(channelsProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejoindre un canal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '#canal',
            labelText: 'Nom du canal',
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              final channel = value.startsWith('#') ? value : '#$value';
              channelsNotifier.joinChannel(channel);
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text;
              if (value.isNotEmpty) {
                final channel = value.startsWith('#') ? value : '#$value';
                channelsNotifier.joinChannel(channel);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Rejoindre'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBrowseChannelsDialog(BuildContext context, WidgetRef ref) async {
    final channelsNotifier = ref.read(channelsProvider.notifier);

    final channelName = await ChannelListDialog.show(context);
    if (channelName != null) {
      channelsNotifier.joinChannel(channelName);
    }
  }
}

/// UserList widget with integrated context menu actions.
class _UserListWithActions extends ConsumerWidget {
  const _UserListWithActions({
    required this.users,
    this.channelName,
  });

  final List<ChannelUser> users;
  final String? channelName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UserList(
      users: users,
      onUserTapUp: channelName != null
          ? (user, details) => UserActionsService.handleUserTap(
                context: context,
                ref: ref,
                user: user,
                channelName: channelName!,
                details: details,
              )
          : null,
      onUserSecondaryTap: channelName != null
          ? (user, details) async {
              // Convert TapDownDetails to TapUpDetails for the handler
              final tapUpDetails = TapUpDetails(
                kind: PointerDeviceKind.mouse,
                globalPosition: details.globalPosition,
                localPosition: details.localPosition,
              );
              await UserActionsService.handleUserTap(
                context: context,
                ref: ref,
                user: user,
                channelName: channelName!,
                details: tapUpDetails,
              );
            }
          : null,
    );
  }
}

/// Temporary page to showcase the theme.
/// Will be replaced by actual screens in later phases.
class ThemeShowcase extends StatefulWidget {
  const ThemeShowcase({super.key});

  @override
  State<ThemeShowcase> createState() => _ThemeShowcaseState();
}

class _ThemeShowcaseState extends State<ThemeShowcase> {
  bool _switchValue = false;
  bool _checkboxValue = false;
  int _selectedRadio = 0;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knights Network Theme'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adaptive Layout section
            _buildSection('Adaptive Layout'),
            AppSpacing.gapVerticalSm,
            _buildDeviceInfo(context),
            AppSpacing.gapVerticalSm,
            AdaptiveLayout(
              mobile: _buildLayoutCard('Mobile Layout', Icons.phone_android),
              tablet: _buildLayoutCard('Tablet Layout', Icons.tablet_android),
              desktop: _buildLayoutCard('Desktop Layout', Icons.desktop_windows),
            ),
            AppSpacing.gapVerticalSm,
            AdaptiveVisibility.desktopOnly(
              child: Container(
                padding: AppSpacing.paddingSm,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Text(
                  'This is only visible on desktop',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                ),
              ),
            ),
            AdaptiveVisibility.mobileOnly(
              child: Container(
                padding: AppSpacing.paddingSm,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Text(
                  'This is only visible on mobile',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                ),
              ),
            ),

            AppSpacing.gapVerticalXxl,

            // Colors section
            _buildSection('Colors'),
            AppSpacing.gapVerticalSm,
            _buildColorRow('Background', AppColors.background),
            _buildColorRow('Surface', AppColors.surface),
            _buildColorRow('Surface Elevated', AppColors.surfaceElevated),
            _buildColorRow('Primary', AppColors.primary),
            _buildColorRow('Secondary', AppColors.secondary),
            _buildColorRow('Error', AppColors.error),
            _buildColorRow('Success', AppColors.success),
            _buildColorRow('Warning', AppColors.warning),

            AppSpacing.gapVerticalXxl,

            // Typography section
            _buildSection('Typography'),
            AppSpacing.gapVerticalSm,
            Text('Display Large', style: AppTextStyles.displayLarge),
            Text('Display Medium', style: AppTextStyles.displayMedium),
            Text('Display Small', style: AppTextStyles.displaySmall),
            Text('Headline Large', style: AppTextStyles.headlineLarge),
            Text('Headline Medium', style: AppTextStyles.headlineMedium),
            Text('Body Large', style: AppTextStyles.bodyLarge),
            Text('Body Medium', style: AppTextStyles.bodyMedium),
            Text('Body Small', style: AppTextStyles.bodySmall),
            Text('Label Large', style: AppTextStyles.labelLarge),
            Text('Label Small', style: AppTextStyles.labelSmall),

            AppSpacing.gapVerticalXxl,

            // IRC Styles section
            _buildSection('IRC Styles'),
            AppSpacing.gapVerticalSm,
            Row(
              children: [
                Text(
                  'nickname',
                  style: AppTextStyles.nicknameColored(
                    AppColors.nickColor('nickname'),
                  ),
                ),
                AppSpacing.gapSm,
                const Text('Hello everyone!', style: AppTextStyles.message),
              ],
            ),
            AppSpacing.gapVerticalSm,
            const Text('12:34', style: AppTextStyles.timestamp),
            AppSpacing.gapVerticalSm,
            const Text('#channel-name', style: AppTextStyles.channelName),
            AppSpacing.gapVerticalSm,
            const Text(
              '* Server notice message',
              style: AppTextStyles.serverMessage,
            ),

            AppSpacing.gapVerticalXxl,

            // IRC Colors section
            _buildSection('IRC 16 Colors'),
            AppSpacing.gapVerticalSm,
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: List.generate(16, (index) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.getIrcColor(index),
                    borderRadius: AppSpacing.borderRadiusSm,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 10,
                        color: index == 0 || index == 8 || index == 15
                            ? AppColors.textInverse
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
            ),

            AppSpacing.gapVerticalXxl,

            // Buttons section
            _buildSection('Buttons'),
            AppSpacing.gapVerticalSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Elevated'),
                ),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Filled'),
                ),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Outlined'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Text'),
                ),
                ElevatedButton(
                  onPressed: null,
                  child: const Text('Disabled'),
                ),
              ],
            ),

            AppSpacing.gapVerticalXxl,

            // Input section
            _buildSection('Input'),
            AppSpacing.gapVerticalSm,
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                prefixIcon: Icon(Icons.chat_bubble_outline),
              ),
            ),
            AppSpacing.gapVerticalSm,
            TextField(
              decoration: const InputDecoration(
                hintText: 'Error state',
                errorText: 'This field has an error',
              ),
            ),

            AppSpacing.gapVerticalXxl,

            // Controls section
            _buildSection('Controls'),
            AppSpacing.gapVerticalSm,
            Row(
              children: [
                Switch(
                  value: _switchValue,
                  onChanged: (v) => setState(() => _switchValue = v),
                ),
                AppSpacing.gapMd,
                Checkbox(
                  value: _checkboxValue,
                  onChanged: (v) => setState(() => _checkboxValue = v ?? false),
                ),
                AppSpacing.gapMd,
                RadioGroup<int>(
                  groupValue: _selectedRadio,
                  onChanged: (v) => setState(() => _selectedRadio = v ?? 0),
                  child: const Row(
                    children: [
                      Radio<int>(value: 0),
                      Radio<int>(value: 1),
                    ],
                  ),
                ),
              ],
            ),

            AppSpacing.gapVerticalXxl,

            // Cards section
            _buildSection('Cards'),
            AppSpacing.gapVerticalSm,
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Card Title', style: AppTextStyles.headlineMedium),
                    AppSpacing.gapVerticalSm,
                    Text(
                      'Card content with body text styling.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            AppSpacing.gapVerticalXxl,

            // Chips section
            _buildSection('Chips'),
            AppSpacing.gapVerticalSm,
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                const Chip(label: Text('Default')),
                Chip(
                  label: const Text('@operator'),
                  avatar: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.operator,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Chip(
                  label: const Text('+voice'),
                  avatar: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.voice,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),

            AppSpacing.gapVerticalXxl,

            // Nick colors section
            _buildSection('Nick Colors'),
            AppSpacing.gapVerticalSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                'alice',
                'bob',
                'charlie',
                'david',
                'eve',
                'frank',
                'grace',
                'henry',
              ]
                  .map((nick) => Text(
                        nick,
                        style: AppTextStyles.nicknameColored(
                          AppColors.nickColor(nick),
                        ),
                      ))
                  .toList(),
            ),

            AppSpacing.gapVerticalXxl,

            // Snackbar demo
            _buildSection('Snackbar'),
            AppSpacing.gapVerticalSm,
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('This is a snackbar message'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () {},
                    ),
                  ),
                );
              },
              child: const Text('Show Snackbar'),
            ),

            // Bottom padding
            AppSpacing.gapVerticalXxl,
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(title, style: AppTextStyles.displaySmall);
  }

  Widget _buildDeviceInfo(BuildContext context) {
    final deviceType = context.deviceType;
    final width = context.screenWidth;

    return Container(
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Row(
        children: [
          Icon(
            switch (deviceType) {
              DeviceType.mobile => Icons.phone_android,
              DeviceType.tablet => Icons.tablet_android,
              DeviceType.desktop => Icons.desktop_windows,
            },
            color: AppColors.primary,
            size: 20,
          ),
          AppSpacing.gapSm,
          Text(
            '${deviceType.name.toUpperCase()} - ${width.toStringAsFixed(0)}dp',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutCard(String label, IconData icon) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary),
            AppSpacing.gapSm,
            Text(label, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(color: AppColors.divider),
            ),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyMedium),
                Text(
                  '#${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

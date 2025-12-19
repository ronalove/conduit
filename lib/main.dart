import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth.dart';
import 'features/channels/channels.dart';
import 'features/chat/chat.dart';
import 'features/settings/settings.dart';
import 'features/users/users.dart';
import 'layouts/layouts.dart';
import 'theme/theme.dart';

/// Sample users for demo.
final _sampleUsers = [
  const ChannelUser(nickname: 'alice', mode: UserMode.operator),
  const ChannelUser(nickname: 'bob', mode: UserMode.voice),
  const ChannelUser(nickname: 'charlie'),
  const ChannelUser(nickname: 'david'),
  const ChannelUser(nickname: 'eve', isAway: true, awayMessage: 'Be right back'),
  const ChannelUser(nickname: 'frank', mode: UserMode.halfOp),
  const ChannelUser(nickname: 'grace'),
  const ChannelUser(nickname: 'henry', isAway: true),
];

/// Sample messages for demo.
final _sampleMessages = [
  ChatMessage(
    id: '1',
    sender: 'alice',
    content: 'Hello everyone!',
    timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
  ),
  ChatMessage(
    id: '2',
    sender: 'bob',
    content: 'Hey alice, how are you?',
    timestamp: DateTime.now().subtract(const Duration(minutes: 29)),
  ),
  ChatMessage(
    id: '3',
    sender: 'alice',
    content: "I'm doing great, thanks for asking!",
    timestamp: DateTime.now().subtract(const Duration(minutes: 28)),
  ),
  ChatMessage(
    id: '4',
    sender: 'charlie',
    content: 'charlie has joined the channel',
    timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
    type: MessageType.event,
  ),
  ChatMessage(
    id: '5',
    sender: 'charlie',
    content: 'waves at everyone',
    timestamp: DateTime.now().subtract(const Duration(minutes: 19)),
    isAction: true,
  ),
  ChatMessage(
    id: '6',
    sender: 'server',
    content: 'Welcome to Conduit IRC client demo.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    type: MessageType.notice,
  ),
  ChatMessage(
    id: '7',
    sender: 'david',
    content: 'Has anyone tried the new Flutter 3.38?',
    timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
  ),
  ChatMessage(
    id: '8',
    sender: 'eve',
    content: 'Yes! The performance improvements are amazing.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
  ),
  ChatMessage(
    id: '9',
    sender: 'alice',
    content: 'I love the new Dart 3.10 features too!',
    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
];

void main() {
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
      title: 'Conduit',
      debugShowCheckedModeBanner: false,
      theme: themeState.themeData,
      home: const AuthGate(),
    );
  }
}

/// Switches between login screen and main app based on auth state.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isAuthenticated) {
      return const LayoutDemo();
    }

    return const LoginScreen();
  }
}

/// Demo page showing adaptive layouts.
class LayoutDemo extends StatefulWidget {
  const LayoutDemo({super.key});

  @override
  State<LayoutDemo> createState() => _LayoutDemoState();
}

class _LayoutDemoState extends State<LayoutDemo> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
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
                  channels: const [
                    ChannelInfo(name: '#general', topic: 'General discussion'),
                    ChannelInfo(name: '#random', unreadCount: 3),
                    ChannelInfo(name: '#dev', topic: 'Development', hasMention: true),
                    ChannelInfo(name: '#help'),
                    ChannelInfo(name: '#off-topic', unreadCount: 12),
                  ],
                  privateMessages: const [
                    PrivateMessageInfo(nickname: 'alice', unreadCount: 2),
                    PrivateMessageInfo(nickname: 'bob', isAway: true),
                  ],
                  selectedChannel: '#general',
                  serverName: 'irc.example.com',
                  onChannelTap: (name, type) {},
                  onAddChannel: () {},
                ),
              ),
              // Settings button at bottom of sidebar
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.settings, size: 20),
                  title: const Text('Settings'),
                  dense: true,
                  onTap: () => setState(() => _showSettings = true),
                ),
              ),
            ],
          ),
          chatArea: ChatScreen(
            channelName: '#general',
            topic: 'General discussion',
            messages: _sampleMessages,
            typingUsers: const ['alice', 'bob'],
            showHeader: false,
            onSendMessage: (msg) {},
          ),
          usersSidebar: UserList(
            users: _sampleUsers,
            onUserTap: (user) {},
            onUserLongPress: (user) {},
          ),
        ),
      ),
    );
  }
}

class _MobilePlaceholder extends StatelessWidget {
  const _MobilePlaceholder({
    this.onOpenSettings,
  });

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return MobileLayout(
      channelsPage: ChannelListScreen(
        channels: const [
          ChannelInfo(name: '#general', topic: 'General discussion'),
          ChannelInfo(name: '#random', unreadCount: 3),
          ChannelInfo(name: '#dev', topic: 'Development', hasMention: true),
          ChannelInfo(name: '#help'),
          ChannelInfo(name: '#off-topic', unreadCount: 12),
        ],
        privateMessages: const [
          PrivateMessageInfo(nickname: 'alice', unreadCount: 2),
          PrivateMessageInfo(nickname: 'bob', isAway: true),
        ],
        selectedChannel: '#general',
        serverName: 'irc.example.com',
        onChannelTap: (name, type) {},
        onAddChannel: () {},
      ),
      chatPage: ChatScreen(
        channelName: '#general',
        topic: 'General discussion',
        messages: _sampleMessages,
        typingUsers: const ['alice'],
        showHeader: true,
        onBack: () {},
        onShowUsers: () {},
        onSendMessage: (msg) {},
      ),
      usersPage: UserList(
        users: _sampleUsers,
        onUserTap: (user) {},
        onUserLongPress: (user) {},
      ),
      settingsPage: SettingsScreen(
        onBack: onOpenSettings,
      ),
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
        title: const Text('Conduit Theme'),
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

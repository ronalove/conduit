import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/irc/commands/list_command.dart';
import '../../../core/irc/parser/irc_parser.dart';
import '../../../core/irc/protocol/list_handler.dart';
import '../../../theme/theme.dart';
import '../../connection/connection.dart';

/// Sort mode for channel list.
enum ChannelSortMode {
  /// Sort alphabetically by name.
  name,

  /// Sort by user count (descending).
  users,
}

/// Dialog to browse and join channels on the server.
class ChannelListDialog extends ConsumerStatefulWidget {
  const ChannelListDialog({
    super.key,
    this.onJoinChannel,
  });

  /// Called when user selects a channel to join.
  final void Function(String channelName)? onJoinChannel;

  /// Shows the dialog.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => ChannelListDialog(
        onJoinChannel: (name) => Navigator.of(context).pop(name),
      ),
    );
  }

  @override
  ConsumerState<ChannelListDialog> createState() => _ChannelListDialogState();
}

class _ChannelListDialogState extends ConsumerState<ChannelListDialog> {
  final _searchController = TextEditingController();
  final _listHandler = ListHandler();
  StreamSubscription<ChannelListUpdate>? _listSubscription;
  StreamSubscription<String>? _linesSubscription;

  List<ListedChannel> _channels = [];
  List<ListedChannel> _filteredChannels = [];
  bool _isLoading = false;
  String? _error;
  ChannelSortMode _sortMode = ChannelSortMode.users;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterChannels);
    _listSubscription = _listHandler.onListReceived.listen(_handleListUpdate);
    _subscribeToLines();
    _loadChannels();
  }

  void _subscribeToLines() {
    // Subscribe to IRC lines to receive LIST responses
    final connectionNotifier = ref.read(connectionProvider.notifier);
    _linesSubscription = connectionNotifier.lines.listen(_handleLine);
  }

  void _handleLine(String line) {
    final message = IrcParser.parse(line);
    // Route LIST-related messages to the handler
    if (ListHandler.isListMessage(message)) {
      _listHandler.handleMessage(message);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listSubscription?.cancel();
    _linesSubscription?.cancel();
    _listHandler.dispose();
    super.dispose();
  }

  void _loadChannels() {
    final session = ref.read(ircSessionProvider);
    if (!session.isReady) {
      setState(() {
        _error = 'Not connected to server';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _channels = [];
      _filteredChannels = [];
    });

    _listHandler.startListening();

    try {
      final cmd = ListCommand.all();
      ref.read(connectionProvider.notifier).send(cmd.toRaw());
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to send LIST command: $e';
      });
    }
  }

  void _handleListUpdate(ChannelListUpdate update) {
    setState(() {
      _isLoading = false;
      _channels = update.channels;
      _filterChannels();
    });
  }

  void _filterChannels() {
    final query = _searchController.text.toLowerCase();
    var filtered = _channels.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          (c.topic?.toLowerCase().contains(query) ?? false);
    }).toList();

    // Sort channels
    switch (_sortMode) {
      case ChannelSortMode.name:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case ChannelSortMode.users:
        filtered.sort((a, b) => b.userCount.compareTo(a.userCount));
    }

    setState(() {
      _filteredChannels = filtered;
    });
  }

  void _setSortMode(ChannelSortMode mode) {
    setState(() {
      _sortMode = mode;
    });
    _filterChannels();
  }

  void _joinChannel(ListedChannel channel) {
    widget.onJoinChannel?.call(channel.name);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const Divider(height: 1),
            Expanded(child: _buildChannelList()),
            const Divider(height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const Icon(Icons.list, size: 24),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browse Channels',
                  style: AppTextStyles.headlineMedium,
                ),
                if (!_isLoading && _channels.isNotEmpty)
                  Text(
                    '${_channels.length} channels available',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          // Sort button
          PopupMenuButton<ChannelSortMode>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort channels',
            onSelected: _setSortMode,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ChannelSortMode.users,
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 20,
                      color: _sortMode == ChannelSortMode.users
                          ? AppColors.primary
                          : null,
                    ),
                    AppSpacing.gapSm,
                    const Text('Most users'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ChannelSortMode.name,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      size: 20,
                      color: _sortMode == ChannelSortMode.name
                          ? AppColors.primary
                          : null,
                    ),
                    AppSpacing.gapSm,
                    const Text('Alphabetical'),
                  ],
                ),
              ),
            ],
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh list',
            onPressed: _isLoading ? null : _loadChannels,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search channels...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }

  Widget _buildChannelList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Loading channels...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            AppSpacing.gapMd,
            Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapLg,
            FilledButton.icon(
              onPressed: _loadChannels,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_channels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 48, color: AppColors.textTertiary),
            SizedBox(height: AppSpacing.md),
            Text('No channels found'),
          ],
        ),
      );
    }

    if (_filteredChannels.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
            AppSpacing.gapMd,
            Text(
              'No channels match "${_searchController.text}"',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredChannels.length,
      itemBuilder: (context, index) {
        final channel = _filteredChannels[index];
        return _ChannelListItem(
          channel: channel,
          onTap: () => _joinChannel(channel),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Individual channel item in the list.
class _ChannelListItem extends StatelessWidget {
  const _ChannelListItem({
    required this.channel,
    required this.onTap,
  });

  final ListedChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = channel.name.startsWith('#')
        ? channel.name.substring(1)
        : channel.name;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.tag,
                size: 20,
                color: AppColors.textSecondary,
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (channel.topic != null && channel.topic!.isNotEmpty)
                      Text(
                        channel.topic!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              AppSpacing.gapSm,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${channel.userCount}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

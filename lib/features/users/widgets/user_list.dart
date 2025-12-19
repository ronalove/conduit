import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../models/channel_user.dart';
import 'user_avatar.dart';

/// List of users in a channel with grouping by mode.
class UserList extends StatefulWidget {
  const UserList({
    super.key,
    required this.users,
    this.onUserTap,
    this.onUserLongPress,
    this.showSearch = true,
  });

  /// List of users in the channel.
  final List<ChannelUser> users;

  /// Called when a user is tapped.
  final void Function(ChannelUser user)? onUserTap;

  /// Called when a user is long pressed.
  final void Function(ChannelUser user)? onUserLongPress;

  /// Whether to show the search field.
  final bool showSearch;

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChannelUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return widget.users;
    final query = _searchQuery.toLowerCase();
    return widget.users
        .where((user) => user.nickname.toLowerCase().contains(query))
        .toList();
  }

  Map<UserMode, List<ChannelUser>> get _groupedUsers {
    final filtered = _filteredUsers;
    final grouped = <UserMode, List<ChannelUser>>{};

    for (final mode in UserMode.values) {
      final usersWithMode = filtered.where((u) => u.mode == mode).toList();
      if (usersWithMode.isNotEmpty) {
        // Sort alphabetically within each group
        usersWithMode.sort(
            (a, b) => a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase()));
        grouped[mode] = usersWithMode;
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedUsers;

    return Column(
      children: [
        // Header with count
        _buildHeader(),

        // Search field
        if (widget.showSearch) _buildSearch(),

        // User list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: [
              for (final mode in UserMode.values)
                if (grouped.containsKey(mode)) ...[
                  _buildModeHeader(mode, grouped[mode]!.length),
                  ...grouped[mode]!.map((user) => UserListTile(
                        user: user,
                        onTap: () => widget.onUserTap?.call(user),
                        onLongPress: () => widget.onUserLongPress?.call(user),
                      )),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: AppSpacing.appBarHeight,
      padding: AppSpacing.paddingHorizontalLg,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Text('Users', style: AppTextStyles.headlineMedium),
          AppSpacing.gapSm,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: Text(
              '${widget.users.length}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search users...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusMd,
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildModeHeader(UserMode mode, int count) {
    final (title, color) = switch (mode) {
      UserMode.operator => ('Operators', AppColors.operator),
      UserMode.halfOp => ('Half-Operators', AppColors.warning),
      UserMode.voice => ('Voiced', AppColors.voice),
      UserMode.regular => ('Users', AppColors.textSecondary),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.gapSm,
          Text(
            title.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            '($count)',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single user tile in the list.
class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.user,
    this.onTap,
    this.onLongPress,
  });

  final ChannelUser user;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = _getUserColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Avatar
              UserAvatar(
                nickname: user.nickname,
                mode: user.mode,
                isAway: user.isAway,
                size: AvatarSize.medium,
              ),
              AppSpacing.gapMd,

              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.nickname,
                      style: AppTextStyles.nickname.copyWith(
                        color: user.isAway ? AppColors.textTertiary : color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.isAway && user.awayMessage != null)
                      Text(
                        user.awayMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Away icon
              if (user.isAway)
                const Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getUserColor() {
    return switch (user.mode) {
      UserMode.operator => AppColors.operator,
      UserMode.halfOp => AppColors.warning,
      UserMode.voice => AppColors.voice,
      UserMode.regular => AppColors.nickColor(user.nickname),
    };
  }
}

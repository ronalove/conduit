import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../channels/providers/channels_provider.dart';
import '../models/channel_user.dart';

/// Provider that returns sorted users for a specific channel.
///
/// Usage:
/// ```dart
/// final users = ref.watch(channelUsersProvider('#general'));
/// ```
final channelUsersProvider = Provider.family<List<ChannelUser>, String>(
  (ref, channelName) {
    final channelsState = ref.watch(channelsProvider);
    final channel = channelsState.getChannel(channelName);
    return channel?.sortedUsers ?? [];
  },
);

/// Provider that returns a specific user in a channel.
///
/// Usage:
/// ```dart
/// final user = ref.watch(channelUserProvider(('#general', 'nick')));
/// ```
final channelUserProvider = Provider.family<ChannelUser?, (String, String)>(
  (ref, args) {
    final (channelName, nickname) = args;
    final channelsState = ref.watch(channelsProvider);
    final channel = channelsState.getChannel(channelName);
    return channel?.getUser(nickname);
  },
);

/// Provider that returns the user count for a channel.
final channelUserCountProvider = Provider.family<int, String>(
  (ref, channelName) {
    final channelsState = ref.watch(channelsProvider);
    final channel = channelsState.getChannel(channelName);
    return channel?.memberCount ?? 0;
  },
);

/// Provider that returns users grouped by mode for a channel.
final channelUsersGroupedProvider =
    Provider.family<Map<UserMode, List<ChannelUser>>, String>(
  (ref, channelName) {
    final users = ref.watch(channelUsersProvider(channelName));
    final grouped = <UserMode, List<ChannelUser>>{};

    for (final mode in UserMode.values) {
      final usersWithMode = users.where((u) => u.mode == mode).toList();
      if (usersWithMode.isNotEmpty) {
        grouped[mode] = usersWithMode;
      }
    }

    return grouped;
  },
);

/// Provider to check if current user has operator privileges in a channel.
final hasOperatorPrivilegesProvider = Provider.family<bool, String>(
  (ref, channelName) {
    // This would need the current user's nickname from the session
    // For now, return false - will be implemented when session provider is available
    return false;
  },
);

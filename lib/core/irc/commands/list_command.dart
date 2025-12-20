import '../parser/irc_message.dart';
import 'irc_command.dart';

/// LIST command - lists channels on the server.
///
/// Formats:
/// - LIST           : List all channels
/// - LIST #channel  : List specific channel(s)
/// - `LIST >10`     : List channels with more than 10 users (server-dependent)
/// - `LIST <100`    : List channels with fewer than 100 users (server-dependent)
///
/// Response numerics:
/// - 321 (RPL_LISTSTART): Start of channel list
/// - 322 (RPL_LIST): Channel info: #channel <user_count> :<topic>
/// - 323 (RPL_LISTEND): End of channel list
///
/// See: https://modern.ircdocs.horse/#list-message
class ListCommand extends IrcCommand {
  /// Optional channel pattern(s) to filter the list.
  final List<String>? channels;

  /// Optional extended filter (e.g., ">10", "<100").
  final String? filter;

  const ListCommand._({
    this.channels,
    this.filter,
  });

  /// Creates a LIST command to list all channels.
  factory ListCommand.all() {
    return const ListCommand._();
  }

  /// Creates a LIST command to list specific channel(s).
  factory ListCommand.channels(List<String> channels) {
    return ListCommand._(channels: channels);
  }

  /// Creates a LIST command with a filter.
  ///
  /// Common filters (server-dependent):
  /// - `>n` : Channels with more than n users
  /// - `<n` : Channels with fewer than n users
  factory ListCommand.filtered(String filter) {
    return ListCommand._(filter: filter);
  }

  @override
  IrcMessage toMessage() {
    final params = <String>[];

    if (channels != null && channels!.isNotEmpty) {
      params.add(channels!.join(','));
    }

    if (filter != null) {
      params.add(filter!);
    }

    return IrcMessage(
      command: 'LIST',
      params: params,
    );
  }
}

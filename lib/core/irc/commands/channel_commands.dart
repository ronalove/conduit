import '../parser/irc_message.dart';
import 'irc_command.dart';

/// JOIN command - joins a channel.
class JoinCommand extends IrcCommand {
  final List<String> channels;
  final List<String>? keys;

  const JoinCommand._(this.channels, this.keys);

  /// Creates a JOIN command for a single channel.
  factory JoinCommand(String channel, {String? key}) {
    return JoinCommand._([channel], key != null ? [key] : null);
  }

  /// Creates a JOIN command for multiple channels.
  factory JoinCommand.multiple(List<String> channels, {List<String>? keys}) {
    return JoinCommand._(channels, keys);
  }

  @override
  IrcMessage toMessage() {
    final channelList = channels.join(',');
    if (keys != null && keys!.isNotEmpty) {
      return IrcMessage(
        command: 'JOIN',
        params: [channelList, keys!.join(',')],
      );
    }
    return IrcMessage(
      command: 'JOIN',
      params: [channelList],
    );
  }
}

/// PART command - leaves a channel.
class PartCommand extends IrcCommand {
  final List<String> channels;
  final String? message;

  const PartCommand._(this.channels, this.message);

  /// Creates a PART command for a single channel.
  factory PartCommand(String channel, {String? message}) {
    return PartCommand._([channel], message);
  }

  /// Creates a PART command for multiple channels.
  factory PartCommand.multiple(List<String> channels, {String? message}) {
    return PartCommand._(channels, message);
  }

  @override
  IrcMessage toMessage() {
    final channelList = channels.join(',');
    return IrcMessage(
      command: 'PART',
      params: message != null ? [channelList, message!] : [channelList],
    );
  }
}

/// NAMES command - lists users in a channel.
class NamesCommand extends IrcCommand {
  final String channel;

  const NamesCommand(this.channel);

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'NAMES',
        params: [channel],
      );
}

/// TOPIC command - gets or sets channel topic.
class TopicCommand extends IrcCommand {
  final String channel;
  final String? topic;
  final bool _settingTopic;

  const TopicCommand._({
    required this.channel,
    this.topic,
    required bool settingTopic,
  }) : _settingTopic = settingTopic;

  /// Creates a TOPIC query command.
  factory TopicCommand.query(String channel) {
    return TopicCommand._(channel: channel, settingTopic: false);
  }

  /// Creates a TOPIC set command.
  factory TopicCommand.set(String channel, String topic) {
    return TopicCommand._(channel: channel, topic: topic, settingTopic: true);
  }

  @override
  IrcMessage toMessage() {
    if (_settingTopic) {
      return IrcMessage(
        command: 'TOPIC',
        params: [channel, topic ?? ''],
      );
    }
    return IrcMessage(
      command: 'TOPIC',
      params: [channel],
    );
  }
}

/// MODE command - gets or sets channel/user modes.
class ModeCommand extends IrcCommand {
  final String target;
  final String? modeString;
  final List<String>? args;

  const ModeCommand._({
    required this.target,
    this.modeString,
    this.args,
  });

  /// Creates a MODE command for a channel.
  factory ModeCommand.channel(
    String channel,
    String modeString, {
    List<String>? args,
  }) {
    return ModeCommand._(
      target: channel,
      modeString: modeString,
      args: args,
    );
  }

  /// Creates a MODE command for a user.
  factory ModeCommand.user(String nick, String modeString) {
    return ModeCommand._(target: nick, modeString: modeString);
  }

  /// Creates a MODE query command.
  factory ModeCommand.query(String target) {
    return ModeCommand._(target: target);
  }

  @override
  IrcMessage toMessage() {
    final params = <String>[target];
    if (modeString != null) {
      params.add(modeString!);
      if (args != null) {
        params.addAll(args!);
      }
    }
    return IrcMessage(command: 'MODE', params: params);
  }
}

/// KICK command - kicks a user from a channel.
class KickCommand extends IrcCommand {
  final String channel;
  final String nick;
  final String? reason;

  const KickCommand({
    required this.channel,
    required this.nick,
    this.reason,
  });

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'KICK',
        params: reason != null
            ? [channel, nick, reason!]
            : [channel, nick],
      );
}

/// INVITE command - invites a user to a channel.
class InviteCommand extends IrcCommand {
  final String nick;
  final String channel;

  const InviteCommand({
    required this.nick,
    required this.channel,
  });

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'INVITE',
        params: [nick, channel],
      );
}

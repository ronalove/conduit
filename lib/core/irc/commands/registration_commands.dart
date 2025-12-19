import '../parser/irc_message.dart';
import 'irc_command.dart';

/// NICK command - sets or changes nickname.
class NickCommand extends IrcCommand {
  final String nickname;

  const NickCommand(this.nickname);

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'NICK',
        params: [nickname],
      );
}

/// USER command - specifies username and realname.
class UserCommand extends IrcCommand {
  final String username;
  final String realname;
  final int mode;

  const UserCommand({
    required this.username,
    required this.realname,
    this.mode = 0,
  });

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'USER',
        params: [username, mode.toString(), '*', realname],
      );
}

/// PASS command - sends server password.
class PassCommand extends IrcCommand {
  final String password;

  const PassCommand(this.password);

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'PASS',
        params: [password],
      );
}

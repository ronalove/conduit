import '../parser/irc_message.dart';
import 'irc_command.dart';

/// QUIT command - disconnects from the server.
class QuitCommand extends IrcCommand {
  final String? message;

  const QuitCommand({this.message});

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'QUIT',
        params: message != null ? [message!] : [],
      );
}

/// PING command - sends a ping to the server.
class PingCommand extends IrcCommand {
  final String token;

  const PingCommand(this.token);

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'PING',
        params: [token],
      );
}

/// PONG command - responds to a server ping.
class PongCommand extends IrcCommand {
  final String token;

  const PongCommand(this.token);

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'PONG',
        params: [token],
      );
}

/// WHO command - queries users matching a mask.
class WhoCommand extends IrcCommand {
  final String mask;
  final bool operatorsOnly;

  const WhoCommand(this.mask, {this.operatorsOnly = false});

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'WHO',
        params: operatorsOnly ? [mask, 'o'] : [mask],
      );
}

/// WHOIS command - queries detailed user information.
class WhoisCommand extends IrcCommand {
  final String nick;
  final String? server;

  const WhoisCommand(this.nick, {this.server});

  @override
  IrcMessage toMessage() => IrcMessage(
        command: 'WHOIS',
        params: server != null ? [server!, nick] : [nick],
      );
}

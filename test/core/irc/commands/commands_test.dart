import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/commands/commands.dart';

void main() {
  group('IrcCommand', () {
    test('toRaw delegates to toMessage().toRaw()', () {
      final cmd = NickCommand('TestNick');
      expect(cmd.toRaw(), cmd.toMessage().toRaw());
    });
  });

  group('NickCommand', () {
    test('generates correct message', () {
      final cmd = NickCommand('TestNick');
      final msg = cmd.toMessage();

      expect(msg.command, 'NICK');
      expect(msg.params, ['TestNick']);
    });

    test('generates correct raw output', () {
      final cmd = NickCommand('TestNick');
      expect(cmd.toRaw(), 'NICK :TestNick\r\n');
    });
  });

  group('UserCommand', () {
    test('generates correct message with defaults', () {
      final cmd = UserCommand(username: 'testuser', realname: 'Test User');
      final msg = cmd.toMessage();

      expect(msg.command, 'USER');
      expect(msg.params, ['testuser', '0', '*', 'Test User']);
    });

    test('generates correct raw output', () {
      final cmd = UserCommand(username: 'testuser', realname: 'Test User');
      expect(cmd.toRaw(), 'USER testuser 0 * :Test User\r\n');
    });

    test('respects custom mode', () {
      final cmd = UserCommand(
        username: 'testuser',
        realname: 'Test User',
        mode: 8,
      );
      final msg = cmd.toMessage();
      expect(msg.params[1], '8');
    });
  });

  group('PassCommand', () {
    test('generates correct message', () {
      final cmd = PassCommand('secret123');
      final msg = cmd.toMessage();

      expect(msg.command, 'PASS');
      expect(msg.params, ['secret123']);
    });
  });

  group('JoinCommand', () {
    test('joins channel without key', () {
      final cmd = JoinCommand('#test');
      final msg = cmd.toMessage();

      expect(msg.command, 'JOIN');
      expect(msg.params, ['#test']);
    });

    test('joins channel with key', () {
      final cmd = JoinCommand('#test', key: 'secret');
      final msg = cmd.toMessage();

      expect(msg.command, 'JOIN');
      expect(msg.params, ['#test', 'secret']);
    });

    test('joins multiple channels', () {
      final cmd = JoinCommand.multiple(['#chan1', '#chan2']);
      final msg = cmd.toMessage();

      expect(msg.command, 'JOIN');
      expect(msg.params, ['#chan1,#chan2']);
    });

    test('joins multiple channels with keys', () {
      final cmd = JoinCommand.multiple(
        ['#chan1', '#chan2'],
        keys: ['key1', 'key2'],
      );
      final msg = cmd.toMessage();

      expect(msg.command, 'JOIN');
      expect(msg.params, ['#chan1,#chan2', 'key1,key2']);
    });
  });

  group('PartCommand', () {
    test('parts channel without message', () {
      final cmd = PartCommand('#test');
      final msg = cmd.toMessage();

      expect(msg.command, 'PART');
      expect(msg.params, ['#test']);
    });

    test('parts channel with message', () {
      final cmd = PartCommand('#test', message: 'Goodbye!');
      final msg = cmd.toMessage();

      expect(msg.command, 'PART');
      expect(msg.params, ['#test', 'Goodbye!']);
    });

    test('parts multiple channels', () {
      final cmd = PartCommand.multiple(['#chan1', '#chan2']);
      final msg = cmd.toMessage();

      expect(msg.params, ['#chan1,#chan2']);
    });
  });

  group('QuitCommand', () {
    test('quits without message', () {
      final cmd = QuitCommand();
      final msg = cmd.toMessage();

      expect(msg.command, 'QUIT');
      expect(msg.params, isEmpty);
    });

    test('quits with message', () {
      final cmd = QuitCommand(message: 'Bye!');
      final msg = cmd.toMessage();

      expect(msg.command, 'QUIT');
      expect(msg.params, ['Bye!']);
    });
  });

  group('PrivmsgCommand', () {
    test('sends message to channel', () {
      final cmd = PrivmsgCommand(target: '#test', message: 'Hello world');
      final msg = cmd.toMessage();

      expect(msg.command, 'PRIVMSG');
      expect(msg.params, ['#test', 'Hello world']);
    });

    test('sends message to user', () {
      final cmd = PrivmsgCommand(target: 'nick', message: 'Hi there');
      final msg = cmd.toMessage();

      expect(msg.params, ['nick', 'Hi there']);
    });

    test('includes tags when provided', () {
      final cmd = PrivmsgCommand(
        target: '#test',
        message: 'Hello',
        tags: {'+draft/reply': 'msgid123'},
      );
      final msg = cmd.toMessage();

      expect(msg.tags['+draft/reply'], 'msgid123');
    });
  });

  group('NoticeCommand', () {
    test('sends notice to target', () {
      final cmd = NoticeCommand(target: '#test', message: 'Notice text');
      final msg = cmd.toMessage();

      expect(msg.command, 'NOTICE');
      expect(msg.params, ['#test', 'Notice text']);
    });
  });

  group('PingCommand', () {
    test('pings with token', () {
      final cmd = PingCommand('server.example.com');
      final msg = cmd.toMessage();

      expect(msg.command, 'PING');
      expect(msg.params, ['server.example.com']);
    });
  });

  group('PongCommand', () {
    test('responds with same token', () {
      final cmd = PongCommand('server.example.com');
      final msg = cmd.toMessage();

      expect(msg.command, 'PONG');
      expect(msg.params, ['server.example.com']);
    });

    test('generates correct raw output', () {
      final cmd = PongCommand('token123');
      expect(cmd.toRaw(), 'PONG :token123\r\n');
    });
  });

  group('ModeCommand', () {
    test('sets channel mode', () {
      final cmd = ModeCommand.channel('#test', '+o', args: ['nick']);
      final msg = cmd.toMessage();

      expect(msg.command, 'MODE');
      expect(msg.params, ['#test', '+o', 'nick']);
    });

    test('sets user mode', () {
      final cmd = ModeCommand.user('nick', '+i');
      final msg = cmd.toMessage();

      expect(msg.params, ['nick', '+i']);
    });

    test('queries mode without setting', () {
      final cmd = ModeCommand.query('#test');
      final msg = cmd.toMessage();

      expect(msg.params, ['#test']);
    });
  });

  group('TopicCommand', () {
    test('queries topic', () {
      final cmd = TopicCommand.query('#test');
      final msg = cmd.toMessage();

      expect(msg.command, 'TOPIC');
      expect(msg.params, ['#test']);
    });

    test('sets topic', () {
      final cmd = TopicCommand.set('#test', 'New topic');
      final msg = cmd.toMessage();

      expect(msg.params, ['#test', 'New topic']);
    });

    test('clears topic with empty string', () {
      final cmd = TopicCommand.set('#test', '');
      final msg = cmd.toMessage();

      expect(msg.params, ['#test', '']);
    });
  });

  group('KickCommand', () {
    test('kicks user from channel', () {
      final cmd = KickCommand(channel: '#test', nick: 'baduser');
      final msg = cmd.toMessage();

      expect(msg.command, 'KICK');
      expect(msg.params, ['#test', 'baduser']);
    });

    test('kicks user with reason', () {
      final cmd = KickCommand(
        channel: '#test',
        nick: 'baduser',
        reason: 'Spamming',
      );
      final msg = cmd.toMessage();

      expect(msg.params, ['#test', 'baduser', 'Spamming']);
    });
  });

  group('InviteCommand', () {
    test('invites user to channel', () {
      final cmd = InviteCommand(nick: 'friend', channel: '#private');
      final msg = cmd.toMessage();

      expect(msg.command, 'INVITE');
      expect(msg.params, ['friend', '#private']);
    });
  });

  group('NamesCommand', () {
    test('queries names for channel', () {
      final cmd = NamesCommand('#test');
      final msg = cmd.toMessage();

      expect(msg.command, 'NAMES');
      expect(msg.params, ['#test']);
    });
  });

  group('WhoCommand', () {
    test('queries who for mask', () {
      final cmd = WhoCommand('#test');
      final msg = cmd.toMessage();

      expect(msg.command, 'WHO');
      expect(msg.params, ['#test']);
    });

    test('supports operators only flag', () {
      final cmd = WhoCommand('#test', operatorsOnly: true);
      final msg = cmd.toMessage();

      expect(msg.params, ['#test', 'o']);
    });
  });

  group('WhoisCommand', () {
    test('queries whois for nick', () {
      final cmd = WhoisCommand('nick');
      final msg = cmd.toMessage();

      expect(msg.command, 'WHOIS');
      expect(msg.params, ['nick']);
    });

    test('queries whois with server', () {
      final cmd = WhoisCommand('nick', server: 'irc.example.com');
      final msg = cmd.toMessage();

      expect(msg.params, ['irc.example.com', 'nick']);
    });
  });
}

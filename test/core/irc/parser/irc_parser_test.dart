import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/parser/irc_parser.dart';
import 'package:conduit/core/irc/parser/irc_message.dart';

void main() {
  group('IrcParser', () {
    group('parse', () {
      test('parses simple command', () {
        final msg = IrcParser.parse('PING :server.example.com');
        expect(msg.command, 'PING');
        expect(msg.params, ['server.example.com']);
        expect(msg.source, isNull);
        expect(msg.tags, isEmpty);
      });

      test('parses command without params', () {
        final msg = IrcParser.parse('QUIT');
        expect(msg.command, 'QUIT');
        expect(msg.params, isEmpty);
      });

      test('parses message with source', () {
        final msg = IrcParser.parse(':nick!user@host PRIVMSG #channel :Hello world');
        expect(msg.source, 'nick!user@host');
        expect(msg.command, 'PRIVMSG');
        expect(msg.params, ['#channel', 'Hello world']);
      });

      test('parses message with tags', () {
        final msg = IrcParser.parse('@msgid=abc;time=2024-01-01 :nick PRIVMSG #chan :Hi');
        expect(msg.tags['msgid'], 'abc');
        expect(msg.tags['time'], '2024-01-01');
        expect(msg.command, 'PRIVMSG');
        expect(msg.params, ['#chan', 'Hi']);
      });

      test('parses message with tags only (no source)', () {
        final msg = IrcParser.parse('@msgid=123 PING :token');
        expect(msg.tags['msgid'], '123');
        expect(msg.source, isNull);
        expect(msg.command, 'PING');
        expect(msg.params, ['token']);
      });

      test('parses numeric reply', () {
        final msg = IrcParser.parse(':server.com 001 nick :Welcome to IRC');
        expect(msg.source, 'server.com');
        expect(msg.command, '001');
        expect(msg.params, ['nick', 'Welcome to IRC']);
      });

      test('parses 005 ISUPPORT with multiple params', () {
        final msg = IrcParser.parse(':server 005 nick CHANTYPES=#& CHANMODES=b,k,l,imnpst :are supported');
        expect(msg.command, '005');
        expect(msg.params, ['nick', 'CHANTYPES=#&', 'CHANMODES=b,k,l,imnpst', 'are supported']);
      });

      test('handles empty trailing parameter', () {
        final msg = IrcParser.parse('PRIVMSG #chan :');
        expect(msg.params, ['#chan', '']);
      });

      test('preserves spaces in trailing', () {
        final msg = IrcParser.parse('PRIVMSG #chan :hello   world');
        expect(msg.params.last, 'hello   world');
      });

      test('parses NAMES reply (353)', () {
        final msg = IrcParser.parse(':server 353 nick = #channel :@op +voice user');
        expect(msg.command, '353');
        expect(msg.params, ['nick', '=', '#channel', '@op +voice user']);
      });

      test('parses JOIN without trailing', () {
        final msg = IrcParser.parse(':nick!user@host JOIN #channel');
        expect(msg.command, 'JOIN');
        expect(msg.params, ['#channel']);
      });

      test('parses PART with reason', () {
        final msg = IrcParser.parse(':nick!user@host PART #channel :Goodbye!');
        expect(msg.command, 'PART');
        expect(msg.params, ['#channel', 'Goodbye!']);
      });

      test('parses QUIT with message', () {
        final msg = IrcParser.parse(':nick!user@host QUIT :Connection closed');
        expect(msg.command, 'QUIT');
        expect(msg.params, ['Connection closed']);
      });

      test('parses MODE change', () {
        final msg = IrcParser.parse(':nick!user@host MODE #channel +o target');
        expect(msg.command, 'MODE');
        expect(msg.params, ['#channel', '+o', 'target']);
      });

      test('parses NICK change', () {
        final msg = IrcParser.parse(':oldnick!user@host NICK newnick');
        expect(msg.command, 'NICK');
        expect(msg.params, ['newnick']);
      });

      test('handles CAP response', () {
        final msg = IrcParser.parse(':server CAP * LS :multi-prefix sasl');
        expect(msg.command, 'CAP');
        expect(msg.params, ['*', 'LS', 'multi-prefix sasl']);
      });

      test('handles escaped tags', () {
        final msg = IrcParser.parse(r'@msg=hello\sworld :nick PRIVMSG #chan :test');
        expect(msg.tags['msg'], 'hello world');
      });

      test('handles tag without value', () {
        final msg = IrcParser.parse('@+typing :nick PRIVMSG #chan :...');
        expect(msg.tags['+typing'], isNull);
        expect(msg.tags.containsKey('+typing'), isTrue);
      });
    });

    group('serialize', () {
      test('serializes simple message', () {
        final msg = IrcMessage(
          command: 'PING',
          params: ['token'],
        );
        expect(IrcParser.serialize(msg), 'PING :token\r\n');
      });

      test('serializes message with source', () {
        final msg = IrcMessage(
          source: 'nick!user@host',
          command: 'PRIVMSG',
          params: ['#channel', 'Hello world'],
        );
        expect(IrcParser.serialize(msg), ':nick!user@host PRIVMSG #channel :Hello world\r\n');
      });

      test('serializes message with tags', () {
        final msg = IrcMessage(
          tags: {'msgid': 'abc', '+typing': null},
          command: 'PRIVMSG',
          params: ['#chan', 'Hi'],
        );
        final serialized = IrcParser.serialize(msg);
        expect(serialized, startsWith('@'));
        expect(serialized, contains('msgid=abc'));
        expect(serialized, contains('+typing'));
        expect(serialized, endsWith('\r\n'));
      });

      test('serializes single param with trailing for safety', () {
        final msg = IrcMessage(
          command: 'JOIN',
          params: ['#channel'],
        );
        // Single param always uses trailing format for IRC compatibility
        expect(IrcParser.serialize(msg), 'JOIN :#channel\r\n');
      });

      test('uses trailing for param with spaces', () {
        final msg = IrcMessage(
          command: 'PRIVMSG',
          params: ['#chan', 'hello world'],
        );
        expect(IrcParser.serialize(msg), 'PRIVMSG #chan :hello world\r\n');
      });

      test('uses trailing for empty last param', () {
        final msg = IrcMessage(
          command: 'PRIVMSG',
          params: ['#chan', ''],
        );
        expect(IrcParser.serialize(msg), 'PRIVMSG #chan :\r\n');
      });

      test('serializes command only', () {
        final msg = IrcMessage(command: 'QUIT');
        expect(IrcParser.serialize(msg), 'QUIT\r\n');
      });
    });

    group('round-trip', () {
      test('simple message round-trip', () {
        const raw = 'PING :server.example.com\r\n';
        final parsed = IrcParser.parse(raw.trim());
        final serialized = IrcParser.serialize(parsed);
        expect(serialized, raw);
      });

      test('complex message round-trip', () {
        const raw = ':nick!user@host PRIVMSG #channel :Hello world\r\n';
        final parsed = IrcParser.parse(raw.trim());
        final serialized = IrcParser.serialize(parsed);
        expect(serialized, raw);
      });
    });
  });

  group('IrcMessage', () {
    group('convenience getters', () {
      test('hasTags returns true when tags present', () {
        final msg = IrcMessage(command: 'PING', tags: {'key': 'value'});
        expect(msg.hasTags, isTrue);
      });

      test('hasTags returns false when no tags', () {
        final msg = IrcMessage(command: 'PING');
        expect(msg.hasTags, isFalse);
      });

      test('hasSource returns true when source present', () {
        final msg = IrcMessage(command: 'PING', source: 'nick');
        expect(msg.hasSource, isTrue);
      });

      test('hasSource returns false when no source', () {
        final msg = IrcMessage(command: 'PING');
        expect(msg.hasSource, isFalse);
      });

      test('trailing returns last param', () {
        final msg = IrcMessage(command: 'PRIVMSG', params: ['#chan', 'Hello']);
        expect(msg.trailing, 'Hello');
      });

      test('trailing returns null when no params', () {
        final msg = IrcMessage(command: 'QUIT');
        expect(msg.trailing, isNull);
      });

      test('parsedSource returns IrcSource', () {
        final msg = IrcMessage(command: 'PRIVMSG', source: 'nick!user@host');
        final source = msg.parsedSource;
        expect(source, isNotNull);
        expect(source!.nick, 'nick');
        expect(source.user, 'user');
        expect(source.host, 'host');
      });

      test('parsedSource returns null when no source', () {
        final msg = IrcMessage(command: 'PING');
        expect(msg.parsedSource, isNull);
      });
    });

    group('isNumeric', () {
      test('returns true for numeric command', () {
        final msg = IrcMessage(command: '001');
        expect(msg.isNumeric, isTrue);
      });

      test('returns false for text command', () {
        final msg = IrcMessage(command: 'PRIVMSG');
        expect(msg.isNumeric, isFalse);
      });
    });

    group('numericValue', () {
      test('returns int for numeric command', () {
        final msg = IrcMessage(command: '353');
        expect(msg.numericValue, 353);
      });

      test('returns null for text command', () {
        final msg = IrcMessage(command: 'PRIVMSG');
        expect(msg.numericValue, isNull);
      });
    });

    group('toRaw', () {
      test('delegates to IrcParser.serialize', () {
        final msg = IrcMessage(command: 'PING', params: ['token']);
        expect(msg.toRaw(), 'PING :token\r\n');
      });
    });

    group('equality', () {
      test('equal messages are equal', () {
        final a = IrcMessage(command: 'PING', params: ['token']);
        final b = IrcMessage(command: 'PING', params: ['token']);
        expect(a, equals(b));
      });

      test('different messages are not equal', () {
        final a = IrcMessage(command: 'PING');
        final b = IrcMessage(command: 'PONG');
        expect(a, isNot(equals(b)));
      });
    });
  });
}

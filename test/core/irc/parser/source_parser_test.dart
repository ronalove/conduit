import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/parser/source_parser.dart';

void main() {
  group('IrcSource', () {
    group('parse', () {
      test('parses full nick!user@host format', () {
        final source = IrcSource.parse('nick!user@host.example.com');
        expect(source.nick, 'nick');
        expect(source.user, 'user');
        expect(source.host, 'host.example.com');
      });

      test('parses nick@host format (no user)', () {
        final source = IrcSource.parse('nick@host.example.com');
        expect(source.nick, 'nick');
        expect(source.user, isNull);
        expect(source.host, 'host.example.com');
      });

      test('parses nick!user format (no host)', () {
        final source = IrcSource.parse('nick!user');
        expect(source.nick, 'nick');
        expect(source.user, 'user');
        expect(source.host, isNull);
      });

      test('parses nick only', () {
        final source = IrcSource.parse('nick');
        expect(source.nick, 'nick');
        expect(source.user, isNull);
        expect(source.host, isNull);
      });

      test('parses server name (with dots, no user/host)', () {
        final source = IrcSource.parse('irc.example.com');
        expect(source.nick, 'irc.example.com');
        expect(source.user, isNull);
        expect(source.host, isNull);
        expect(source.isServer, isTrue);
      });

      test('handles complex host with dots', () {
        final source = IrcSource.parse('nick!~user@192.168.1.1');
        expect(source.nick, 'nick');
        expect(source.user, '~user');
        expect(source.host, '192.168.1.1');
      });

      test('handles tilde prefix in user', () {
        final source = IrcSource.parse('john!~john@cloak.example.com');
        expect(source.nick, 'john');
        expect(source.user, '~john');
        expect(source.host, 'cloak.example.com');
      });

      test('handles IPv6 host', () {
        final source = IrcSource.parse('nick!user@2001:db8::1');
        expect(source.nick, 'nick');
        expect(source.user, 'user');
        expect(source.host, '2001:db8::1');
      });
    });

    group('isServer', () {
      test('returns true for server-like source', () {
        final source = IrcSource.parse('irc.libera.chat');
        expect(source.isServer, isTrue);
      });

      test('returns false for user source', () {
        final source = IrcSource.parse('nick!user@host');
        expect(source.isServer, isFalse);
      });

      test('returns false for nick only', () {
        final source = IrcSource.parse('nick');
        expect(source.isServer, isFalse);
      });
    });

    group('toRaw', () {
      test('serializes full source', () {
        final source = IrcSource(nick: 'nick', user: 'user', host: 'host.com');
        expect(source.toRaw(), 'nick!user@host.com');
      });

      test('serializes nick@host', () {
        final source = IrcSource(nick: 'nick', host: 'host.com');
        expect(source.toRaw(), 'nick@host.com');
      });

      test('serializes nick!user', () {
        final source = IrcSource(nick: 'nick', user: 'user');
        expect(source.toRaw(), 'nick!user');
      });

      test('serializes nick only', () {
        final source = IrcSource(nick: 'nick');
        expect(source.toRaw(), 'nick');
      });
    });

    group('equality', () {
      test('equal sources are equal', () {
        final a = IrcSource(nick: 'nick', user: 'user', host: 'host');
        final b = IrcSource(nick: 'nick', user: 'user', host: 'host');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different sources are not equal', () {
        final a = IrcSource(nick: 'nick1');
        final b = IrcSource(nick: 'nick2');
        expect(a, isNot(equals(b)));
      });
    });
  });
}

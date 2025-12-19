import 'package:conduit/core/irc/parser/user_prefix.dart';
import 'package:test/test.dart';

void main() {
  group('UserPrefix', () {
    test('has correct standard prefixes', () {
      expect(UserPrefix.owner.symbol, equals('~'));
      expect(UserPrefix.owner.mode, equals('q'));

      expect(UserPrefix.admin.symbol, equals('&'));
      expect(UserPrefix.admin.mode, equals('a'));

      expect(UserPrefix.op.symbol, equals('@'));
      expect(UserPrefix.op.mode, equals('o'));

      expect(UserPrefix.halfop.symbol, equals('%'));
      expect(UserPrefix.halfop.mode, equals('h'));

      expect(UserPrefix.voice.symbol, equals('+'));
      expect(UserPrefix.voice.mode, equals('v'));
    });

    test('fromSymbol returns correct prefix', () {
      expect(UserPrefix.fromSymbol('@'), equals(UserPrefix.op));
      expect(UserPrefix.fromSymbol('+'), equals(UserPrefix.voice));
      expect(UserPrefix.fromSymbol('~'), equals(UserPrefix.owner));
      expect(UserPrefix.fromSymbol('x'), isNull);
    });

    test('fromMode returns correct prefix', () {
      expect(UserPrefix.fromMode('o'), equals(UserPrefix.op));
      expect(UserPrefix.fromMode('v'), equals(UserPrefix.voice));
      expect(UserPrefix.fromMode('q'), equals(UserPrefix.owner));
      expect(UserPrefix.fromMode('x'), isNull);
    });

    test('compareTo orders by precedence', () {
      final prefixes = [
        UserPrefix.voice,
        UserPrefix.op,
        UserPrefix.owner,
        UserPrefix.halfop,
        UserPrefix.admin,
      ];

      prefixes.sort();

      expect(prefixes[0], equals(UserPrefix.owner));
      expect(prefixes[1], equals(UserPrefix.admin));
      expect(prefixes[2], equals(UserPrefix.op));
      expect(prefixes[3], equals(UserPrefix.halfop));
      expect(prefixes[4], equals(UserPrefix.voice));
    });

    test('standardPrefixes is in correct order', () {
      expect(UserPrefix.standardPrefixes[0], equals(UserPrefix.owner));
      expect(UserPrefix.standardPrefixes[4], equals(UserPrefix.voice));
    });
  });

  group('PrefixedUser', () {
    test('hasPrefixes returns correct value', () {
      final withPrefix = PrefixedUser(nick: 'user', prefixes: [UserPrefix.op]);
      final withoutPrefix = PrefixedUser(nick: 'user');

      expect(withPrefix.hasPrefixes, isTrue);
      expect(withoutPrefix.hasPrefixes, isFalse);
    });

    test('highestPrefix returns highest rank prefix', () {
      final user = PrefixedUser(
        nick: 'user',
        prefixes: [UserPrefix.op, UserPrefix.voice],
      );

      expect(user.highestPrefix, equals(UserPrefix.op));
    });

    test('highestPrefix returns null when no prefixes', () {
      final user = PrefixedUser(nick: 'user');
      expect(user.highestPrefix, isNull);
    });

    test('prefixString returns combined prefixes', () {
      final user = PrefixedUser(
        nick: 'user',
        prefixes: [UserPrefix.op, UserPrefix.voice],
      );

      expect(user.prefixString, equals('@+'));
    });

    test('displayName includes prefixes and nick', () {
      final user = PrefixedUser(
        nick: 'nickname',
        prefixes: [UserPrefix.op, UserPrefix.voice],
      );

      expect(user.displayName, equals('@+nickname'));
    });

    test('isOp returns true for op or higher', () {
      final op = PrefixedUser(nick: 'user', prefixes: [UserPrefix.op]);
      final owner = PrefixedUser(nick: 'user', prefixes: [UserPrefix.owner]);
      final voice = PrefixedUser(nick: 'user', prefixes: [UserPrefix.voice]);
      final noPrefix = PrefixedUser(nick: 'user');

      expect(op.isOp, isTrue);
      expect(owner.isOp, isTrue);
      expect(voice.isOp, isFalse);
      expect(noPrefix.isOp, isFalse);
    });

    test('hasVoice returns true for voice or higher', () {
      final voice = PrefixedUser(nick: 'user', prefixes: [UserPrefix.voice]);
      final op = PrefixedUser(nick: 'user', prefixes: [UserPrefix.op]);
      final noPrefix = PrefixedUser(nick: 'user');

      expect(voice.hasVoice, isTrue);
      expect(op.hasVoice, isTrue);
      expect(noPrefix.hasVoice, isFalse);
    });

    test('specific role checks work', () {
      final owner = PrefixedUser(nick: 'user', prefixes: [UserPrefix.owner]);
      final admin = PrefixedUser(nick: 'user', prefixes: [UserPrefix.admin]);
      final halfop = PrefixedUser(nick: 'user', prefixes: [UserPrefix.halfop]);

      expect(owner.isOwner, isTrue);
      expect(owner.isAdmin, isFalse);

      expect(admin.isAdmin, isTrue);
      expect(admin.isOwner, isFalse);

      expect(halfop.isHalfOp, isTrue);
    });

    test('equality works correctly', () {
      final user1 = PrefixedUser(nick: 'nick', prefixes: [UserPrefix.op]);
      final user2 = PrefixedUser(nick: 'nick', prefixes: [UserPrefix.op]);
      final user3 = PrefixedUser(nick: 'nick', prefixes: [UserPrefix.voice]);

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });
  });

  group('UserPrefixParser', () {
    group('parse', () {
      test('parses single prefix', () {
        final user = UserPrefixParser.parse('@nick');

        expect(user.nick, equals('nick'));
        expect(user.prefixes.length, equals(1));
        expect(user.prefixes[0], equals(UserPrefix.op));
      });

      test('parses multiple prefixes (multi-prefix)', () {
        final user = UserPrefixParser.parse('@+nick');

        expect(user.nick, equals('nick'));
        expect(user.prefixes.length, equals(2));
        expect(user.prefixes[0], equals(UserPrefix.op));
        expect(user.prefixes[1], equals(UserPrefix.voice));
      });

      test('parses all standard prefixes', () {
        final user = UserPrefixParser.parse('~&@%+nick');

        expect(user.nick, equals('nick'));
        expect(user.prefixes.length, equals(5));
        expect(user.prefixes[0], equals(UserPrefix.owner));
        expect(user.prefixes[4], equals(UserPrefix.voice));
      });

      test('parses nick without prefix', () {
        final user = UserPrefixParser.parse('nick');

        expect(user.nick, equals('nick'));
        expect(user.prefixes, isEmpty);
      });

      test('handles empty string', () {
        final user = UserPrefixParser.parse('');

        expect(user.nick, equals(''));
        expect(user.prefixes, isEmpty);
      });

      test('sorts prefixes by precedence', () {
        // Voice before op in string, but op should be first after parsing
        final user = UserPrefixParser.parse('+@nick');

        expect(user.prefixes[0], equals(UserPrefix.op));
        expect(user.prefixes[1], equals(UserPrefix.voice));
      });
    });

    group('parseNamesReply', () {
      test('parses simple NAMES reply', () {
        final users = UserPrefixParser.parseNamesReply('nick1 @nick2 +nick3');

        expect(users.length, equals(3));
        expect(users[0].nick, equals('nick1'));
        expect(users[0].hasPrefixes, isFalse);
        expect(users[1].nick, equals('nick2'));
        expect(users[1].prefixes[0], equals(UserPrefix.op));
        expect(users[2].nick, equals('nick3'));
        expect(users[2].prefixes[0], equals(UserPrefix.voice));
      });

      test('parses NAMES with multi-prefix', () {
        final users = UserPrefixParser.parseNamesReply('@nick1 @+nick2 +nick3');

        expect(users.length, equals(3));
        expect(users[1].prefixes.length, equals(2));
        expect(users[1].displayName, equals('@+nick2'));
      });

      test('handles empty string', () {
        final users = UserPrefixParser.parseNamesReply('');
        expect(users, isEmpty);
      });

      test('handles extra spaces', () {
        final users = UserPrefixParser.parseNamesReply('nick1  nick2   nick3');

        expect(users.length, equals(3));
      });
    });

    group('serialize', () {
      test('serializes prefixed user', () {
        final user = PrefixedUser(
          nick: 'nickname',
          prefixes: [UserPrefix.op, UserPrefix.voice],
        );

        expect(UserPrefixParser.serialize(user), equals('@+nickname'));
      });

      test('serializes unprefixed user', () {
        final user = PrefixedUser(nick: 'nickname');

        expect(UserPrefixParser.serialize(user), equals('nickname'));
      });
    });

    group('isPrefixChar', () {
      test('returns true for prefix characters', () {
        expect(UserPrefixParser.isPrefixChar('@'), isTrue);
        expect(UserPrefixParser.isPrefixChar('+'), isTrue);
        expect(UserPrefixParser.isPrefixChar('~'), isTrue);
        expect(UserPrefixParser.isPrefixChar('&'), isTrue);
        expect(UserPrefixParser.isPrefixChar('%'), isTrue);
      });

      test('returns false for non-prefix characters', () {
        expect(UserPrefixParser.isPrefixChar('a'), isFalse);
        expect(UserPrefixParser.isPrefixChar('1'), isFalse);
        expect(UserPrefixParser.isPrefixChar(''), isFalse);
        expect(UserPrefixParser.isPrefixChar('@@'), isFalse);
      });
    });
  });

  group('PrefixConfig', () {
    group('parseIsupport', () {
      test('parses standard PREFIX', () {
        final config = PrefixConfig.parseIsupport('(ov)@+');

        expect(config.length, equals(2));
        expect(config['o'], equals('@'));
        expect(config['v'], equals('+'));
      });

      test('parses extended PREFIX', () {
        final config = PrefixConfig.parseIsupport('(qaohv)~&@%+');

        expect(config.length, equals(5));
        expect(config['q'], equals('~'));
        expect(config['a'], equals('&'));
        expect(config['o'], equals('@'));
        expect(config['h'], equals('%'));
        expect(config['v'], equals('+'));
      });

      test('returns empty map for invalid format', () {
        expect(PrefixConfig.parseIsupport('invalid'), isEmpty);
        expect(PrefixConfig.parseIsupport('(ov'), isEmpty);
        expect(PrefixConfig.parseIsupport('(ov)@'), isEmpty); // mismatched length
      });
    });

    group('fromIsupport', () {
      test('creates UserPrefix list from ISUPPORT', () {
        final prefixes = PrefixConfig.fromIsupport('(ov)@+');

        expect(prefixes.length, equals(2));
        expect(prefixes[0].mode, equals('o'));
        expect(prefixes[0].symbol, equals('@'));
        expect(prefixes[0].precedence, equals(0));
        expect(prefixes[1].mode, equals('v'));
        expect(prefixes[1].symbol, equals('+'));
        expect(prefixes[1].precedence, equals(1));
      });

      test('handles extended prefixes', () {
        final prefixes = PrefixConfig.fromIsupport('(qaohv)~&@%+');

        expect(prefixes.length, equals(5));
        expect(prefixes[0].mode, equals('q'));
        expect(prefixes[0].symbol, equals('~'));
      });
    });
  });
}

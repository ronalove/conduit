import 'package:conduit/core/irc/parser/isupport.dart';
import 'package:conduit/core/irc/parser/user_prefix.dart';
import 'package:test/test.dart';

void main() {
  group('IsupportParser', () {
    group('parse', () {
      test('parses boolean tokens', () {
        final params = ['nick', 'UTF8ONLY', 'WHOX', 'are supported'];

        final result = IsupportParser.parse(params);

        expect(result['UTF8ONLY'], isNull);
        expect(result.containsKey('UTF8ONLY'), isTrue);
        expect(result.containsKey('WHOX'), isTrue);
      });

      test('parses value tokens', () {
        final params = ['nick', 'NETWORK=Libera.Chat', 'NICKLEN=32', 'are supported'];

        final result = IsupportParser.parse(params);

        expect(result['NETWORK'], equals('Libera.Chat'));
        expect(result['NICKLEN'], equals('32'));
      });

      test('parses mixed tokens', () {
        final params = [
          'nick',
          'UTF8ONLY',
          'NETWORK=TestNet',
          'CHANTYPES=#&',
          'PREFIX=(ov)@+',
          'are supported by this server',
        ];

        final result = IsupportParser.parse(params);

        expect(result.containsKey('UTF8ONLY'), isTrue);
        expect(result['NETWORK'], equals('TestNet'));
        expect(result['CHANTYPES'], equals('#&'));
        expect(result['PREFIX'], equals('(ov)@+'));
      });

      test('converts keys to uppercase', () {
        final params = ['nick', 'network=Test', 'nicklen=30', 'trailing'];

        final result = IsupportParser.parse(params);

        expect(result.containsKey('NETWORK'), isTrue);
        expect(result.containsKey('NICKLEN'), isTrue);
      });

      test('handles empty params', () {
        final result = IsupportParser.parse([]);
        expect(result, isEmpty);
      });

      test('handles minimal params', () {
        final result = IsupportParser.parse(['nick']);
        expect(result, isEmpty);
      });
    });

    group('parseToken', () {
      test('parses boolean token', () {
        final result = IsupportParser.parseToken('UTF8ONLY');

        expect(result, isNotNull);
        expect(result!.$1, equals('UTF8ONLY'));
        expect(result.$2, isNull);
      });

      test('parses value token', () {
        final result = IsupportParser.parseToken('NETWORK=TestNet');

        expect(result, isNotNull);
        expect(result!.$1, equals('NETWORK'));
        expect(result.$2, equals('TestNet'));
      });

      test('returns null for removal tokens', () {
        final result = IsupportParser.parseToken('-UTF8ONLY');
        expect(result, isNull);
      });

      test('returns null for empty token', () {
        final result = IsupportParser.parseToken('');
        expect(result, isNull);
      });

      test('handles value with equals sign', () {
        final result = IsupportParser.parseToken('EXTBAN=,ABCNOQRSTUcjmprsz');

        expect(result!.$1, equals('EXTBAN'));
        expect(result.$2, equals(',ABCNOQRSTUcjmprsz'));
      });
    });

    group('isRemovalToken', () {
      test('returns true for removal tokens', () {
        expect(IsupportParser.isRemovalToken('-UTF8ONLY'), isTrue);
        expect(IsupportParser.isRemovalToken('-NETWORK=Test'), isTrue);
      });

      test('returns false for normal tokens', () {
        expect(IsupportParser.isRemovalToken('UTF8ONLY'), isFalse);
        expect(IsupportParser.isRemovalToken('NETWORK=Test'), isFalse);
      });
    });

    group('getRemovalKey', () {
      test('extracts key from removal token', () {
        expect(IsupportParser.getRemovalKey('-UTF8ONLY'), equals('UTF8ONLY'));
        expect(IsupportParser.getRemovalKey('-NETWORK=Test'), equals('NETWORK'));
      });

      test('returns null for non-removal token', () {
        expect(IsupportParser.getRemovalKey('UTF8ONLY'), isNull);
      });
    });
  });

  group('Isupport', () {
    test('utf8Only returns correct value', () {
      final with8 = Isupport.fromTokens({'UTF8ONLY': null});
      final without = Isupport.fromTokens({});

      expect(with8.utf8Only, isTrue);
      expect(without.utf8Only, isFalse);
    });

    test('network returns correct value', () {
      final isupport = Isupport.fromTokens({'NETWORK': 'Libera.Chat'});
      expect(isupport.network, equals('Libera.Chat'));
    });

    test('network returns null when not set', () {
      final isupport = Isupport.fromTokens({});
      expect(isupport.network, isNull);
    });

    test('chanTypes returns value or default', () {
      final withTypes = Isupport.fromTokens({'CHANTYPES': '#&!'});
      final withoutTypes = Isupport.fromTokens({});

      expect(withTypes.chanTypes, equals('#&!'));
      expect(withoutTypes.chanTypes, equals('#'));
    });

    test('nickLen returns value or default', () {
      final withLen = Isupport.fromTokens({'NICKLEN': '32'});
      final withoutLen = Isupport.fromTokens({});

      expect(withLen.nickLen, equals(32));
      expect(withoutLen.nickLen, equals(9));
    });

    test('channelLen returns value or default', () {
      final withLen = Isupport.fromTokens({'CHANNELLEN': '64'});
      final withoutLen = Isupport.fromTokens({});

      expect(withLen.channelLen, equals(64));
      expect(withoutLen.channelLen, equals(200));
    });

    test('topicLen returns value or null', () {
      final withLen = Isupport.fromTokens({'TOPICLEN': '390'});
      final withoutLen = Isupport.fromTokens({});

      expect(withLen.topicLen, equals(390));
      expect(withoutLen.topicLen, isNull);
    });

    test('caseMapping returns value or default', () {
      final withMapping = Isupport.fromTokens({'CASEMAPPING': 'ascii'});
      final withoutMapping = Isupport.fromTokens({});

      expect(withMapping.caseMapping, equals('ascii'));
      expect(withoutMapping.caseMapping, equals('rfc1459'));
    });

    test('chanModes parses correctly', () {
      final isupport = Isupport.fromTokens({
        'CHANMODES': 'beI,k,l,imnpst',
      });

      final modes = isupport.chanModes;

      expect(modes['A'], equals('beI'));
      expect(modes['B'], equals('k'));
      expect(modes['C'], equals('l'));
      expect(modes['D'], equals('imnpst'));
    });

    test('chanModes returns empty map when not set', () {
      final isupport = Isupport.fromTokens({});
      expect(isupport.chanModes, isEmpty);
    });

    test('prefixes parses PREFIX token', () {
      final isupport = Isupport.fromTokens({'PREFIX': '(ov)@+'});

      final prefixes = isupport.prefixes;

      expect(prefixes.length, equals(2));
      expect(prefixes[0].mode, equals('o'));
      expect(prefixes[0].symbol, equals('@'));
      expect(prefixes[1].mode, equals('v'));
      expect(prefixes[1].symbol, equals('+'));
    });

    test('prefixes returns standard when not set', () {
      final isupport = Isupport.fromTokens({});

      expect(isupport.prefixes, equals(UserPrefix.standardPrefixes));
    });

    test('hasToken checks token existence', () {
      final isupport = Isupport.fromTokens({
        'UTF8ONLY': null,
        'NETWORK': 'Test',
      });

      expect(isupport.hasToken('UTF8ONLY'), isTrue);
      expect(isupport.hasToken('NETWORK'), isTrue);
      expect(isupport.hasToken('MISSING'), isFalse);
    });

    test('hasToken is case-insensitive', () {
      final isupport = Isupport.fromTokens({'UTF8ONLY': null});

      expect(isupport.hasToken('utf8only'), isTrue);
      expect(isupport.hasToken('Utf8Only'), isTrue);
    });

    test('getValue returns correct values', () {
      final isupport = Isupport.fromTokens({
        'UTF8ONLY': null,
        'NETWORK': 'TestNet',
      });

      expect(isupport.getValue('UTF8ONLY'), isNull);
      expect(isupport.getValue('NETWORK'), equals('TestNet'));
      expect(isupport.getValue('MISSING'), isNull);
    });

    test('getIntValue parses integers', () {
      final isupport = Isupport.fromTokens({
        'NICKLEN': '32',
        'NETWORK': 'Test',
      });

      expect(isupport.getIntValue('NICKLEN'), equals(32));
      expect(isupport.getIntValue('NETWORK'), isNull); // Not an int
      expect(isupport.getIntValue('MISSING'), isNull);
    });

    test('merge combines tokens', () {
      final original = Isupport.fromTokens({
        'UTF8ONLY': null,
        'NETWORK': 'OldNet',
      });

      final merged = original.merge({
        'NETWORK': 'NewNet',
        'NICKLEN': '32',
      });

      expect(merged.hasToken('UTF8ONLY'), isTrue);
      expect(merged.getValue('NETWORK'), equals('NewNet'));
      expect(merged.getValue('NICKLEN'), equals('32'));
    });

    test('without removes token', () {
      final original = Isupport.fromTokens({
        'UTF8ONLY': null,
        'NETWORK': 'Test',
      });

      final modified = original.without('UTF8ONLY');

      expect(modified.hasToken('UTF8ONLY'), isFalse);
      expect(modified.hasToken('NETWORK'), isTrue);
    });

    test('tokens returns unmodifiable map', () {
      final isupport = Isupport.fromTokens({'UTF8ONLY': null});

      expect(() => isupport.tokens['NEW'] = 'value', throwsUnsupportedError);
    });
  });

  group('IsupportTokens', () {
    test('contains expected constants', () {
      expect(IsupportTokens.utf8Only, equals('UTF8ONLY'));
      expect(IsupportTokens.network, equals('NETWORK'));
      expect(IsupportTokens.prefix, equals('PREFIX'));
      expect(IsupportTokens.monitor, equals('MONITOR'));
    });
  });

  group('Integration', () {
    test('parses real-world ISUPPORT', () {
      // Simulated 005 params from a real server
      final params = [
        'testnick',
        'CASEMAPPING=ascii',
        'CHANLIMIT=#:100',
        'CHANMODES=beI,k,l,imnpst',
        'CHANNELLEN=64',
        'CHANTYPES=#',
        'ELIST=MNUCT',
        'EXCEPTS=e',
        'are supported by this server',
      ];

      final isupport = IsupportParser.fromParams(params);

      expect(isupport.caseMapping, equals('ascii'));
      expect(isupport.channelLen, equals(64));
      expect(isupport.chanTypes, equals('#'));
      expect(isupport.hasToken('EXCEPTS'), isTrue);
    });

    test('handles multiple 005 messages', () {
      // First 005
      var isupport = IsupportParser.fromParams([
        'nick',
        'CASEMAPPING=ascii',
        'NETWORK=TestNet',
        'are supported',
      ]);

      // Second 005
      isupport = isupport.merge(IsupportParser.parse([
        'nick',
        'UTF8ONLY',
        'NICKLEN=30',
        'are supported',
      ]));

      expect(isupport.caseMapping, equals('ascii'));
      expect(isupport.network, equals('TestNet'));
      expect(isupport.utf8Only, isTrue);
      expect(isupport.nickLen, equals(30));
    });
  });
}

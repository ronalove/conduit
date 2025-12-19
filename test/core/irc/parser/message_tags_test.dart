import 'package:conduit/core/irc/parser/message_tags.dart';
import 'package:test/test.dart';

void main() {
  group('IrcTags', () {
    test('defines standard tag names', () {
      expect(IrcTags.time, equals('time'));
      expect(IrcTags.msgid, equals('msgid'));
      expect(IrcTags.account, equals('account'));
      expect(IrcTags.batch, equals('batch'));
      expect(IrcTags.label, equals('label'));
      expect(IrcTags.replyTo, equals('+draft/reply'));
      expect(IrcTags.typing, equals('+typing'));
      expect(IrcTags.react, equals('+draft/react'));
    });
  });

  group('MessageTags.isClientOnly', () {
    test('returns true for tags starting with +', () {
      expect(MessageTags.isClientOnly('+typing'), isTrue);
      expect(MessageTags.isClientOnly('+draft/reply'), isTrue);
      expect(MessageTags.isClientOnly('+example.com/foo'), isTrue);
    });

    test('returns false for server tags', () {
      expect(MessageTags.isClientOnly('time'), isFalse);
      expect(MessageTags.isClientOnly('msgid'), isFalse);
      expect(MessageTags.isClientOnly('example.com/foo'), isFalse);
    });
  });

  group('MessageTags.isVendorPrefixed', () {
    test('returns true for vendor-prefixed tags', () {
      expect(MessageTags.isVendorPrefixed('example.com/foo'), isTrue);
      expect(MessageTags.isVendorPrefixed('draft/bar'), isFalse); // no dot
      expect(MessageTags.isVendorPrefixed('+example.com/foo'), isTrue);
    });

    test('returns false for standard tags', () {
      expect(MessageTags.isVendorPrefixed('time'), isFalse);
      expect(MessageTags.isVendorPrefixed('msgid'), isFalse);
      expect(MessageTags.isVendorPrefixed('+typing'), isFalse);
    });
  });

  group('MessageTags.getVendorDomain', () {
    test('extracts vendor domain from prefixed tag', () {
      expect(MessageTags.getVendorDomain('example.com/foo'), equals('example.com'));
      expect(MessageTags.getVendorDomain('+example.com/bar'), equals('example.com'));
      expect(MessageTags.getVendorDomain('sub.example.com/baz'), equals('sub.example.com'));
    });

    test('returns null for non-vendor tags', () {
      expect(MessageTags.getVendorDomain('time'), isNull);
      expect(MessageTags.getVendorDomain('+typing'), isNull);
      expect(MessageTags.getVendorDomain('draft/reply'), isNull);
    });
  });

  group('MessageTags.getBaseName', () {
    test('extracts base name from vendor-prefixed tags', () {
      expect(MessageTags.getBaseName('example.com/foo'), equals('foo'));
      expect(MessageTags.getBaseName('+draft/reply'), equals('reply'));
    });

    test('returns same name for standard tags', () {
      expect(MessageTags.getBaseName('time'), equals('time'));
      expect(MessageTags.getBaseName('msgid'), equals('msgid'));
    });
  });

  group('MessageTags.getTime', () {
    test('parses ISO 8601 timestamp', () {
      final tags = {'time': '2024-01-15T10:30:00.000Z'};
      final time = MessageTags.getTime(tags);

      expect(time, isNotNull);
      expect(time!.year, equals(2024));
      expect(time.month, equals(1));
      expect(time.day, equals(15));
      expect(time.hour, equals(10));
      expect(time.minute, equals(30));
      expect(time.isUtc, isTrue);
    });

    test('returns null for missing time tag', () {
      final tags = <String, String?>{'msgid': 'abc123'};
      expect(MessageTags.getTime(tags), isNull);
    });

    test('returns null for invalid timestamp', () {
      final tags = {'time': 'not-a-date'};
      expect(MessageTags.getTime(tags), isNull);
    });
  });

  group('MessageTags.getMsgId', () {
    test('extracts message ID', () {
      final tags = {'msgid': 'abc123xyz'};
      expect(MessageTags.getMsgId(tags), equals('abc123xyz'));
    });

    test('returns null for missing msgid', () {
      final tags = <String, String?>{'time': '2024-01-15T10:30:00.000Z'};
      expect(MessageTags.getMsgId(tags), isNull);
    });
  });

  group('MessageTags.getAccount', () {
    test('extracts account name', () {
      final tags = {'account': 'user123'};
      expect(MessageTags.getAccount(tags), equals('user123'));
    });

    test('returns empty string for logged out user', () {
      final tags = {'account': ''};
      expect(MessageTags.getAccount(tags), equals(''));
    });

    test('returns null for missing account tag', () {
      final tags = <String, String?>{};
      expect(MessageTags.getAccount(tags), isNull);
    });
  });

  group('MessageTags.getBatch', () {
    test('extracts batch reference', () {
      final tags = {'batch': 'batch123'};
      expect(MessageTags.getBatch(tags), equals('batch123'));
    });
  });

  group('MessageTags.getLabel', () {
    test('extracts label', () {
      final tags = {'label': 'req001'};
      expect(MessageTags.getLabel(tags), equals('req001'));
    });
  });

  group('MessageTags.getClientOnlyTags', () {
    test('extracts only client-only tags', () {
      final tags = {
        'time': '2024-01-15T10:30:00.000Z',
        'msgid': 'abc123',
        '+typing': 'active',
        '+draft/reply': 'xyz789',
      };

      final clientOnly = MessageTags.getClientOnlyTags(tags);

      expect(clientOnly.length, equals(2));
      expect(clientOnly['typing'], equals('active'));
      expect(clientOnly['draft/reply'], equals('xyz789'));
      expect(clientOnly.containsKey('time'), isFalse);
    });

    test('returns empty map when no client-only tags', () {
      final tags = {'time': '2024-01-15T10:30:00.000Z', 'msgid': 'abc'};
      expect(MessageTags.getClientOnlyTags(tags), isEmpty);
    });
  });

  group('MessageTags.getServerTags', () {
    test('extracts only server tags', () {
      final tags = {
        'time': '2024-01-15T10:30:00.000Z',
        'msgid': 'abc123',
        '+typing': 'active',
        '+draft/reply': 'xyz789',
      };

      final serverTags = MessageTags.getServerTags(tags);

      expect(serverTags.length, equals(2));
      expect(serverTags['time'], equals('2024-01-15T10:30:00.000Z'));
      expect(serverTags['msgid'], equals('abc123'));
      expect(serverTags.containsKey('+typing'), isFalse);
    });
  });

  group('MessageTags.withTime', () {
    test('adds time tag to existing tags', () {
      final original = {'msgid': 'abc123'};
      final time = DateTime.utc(2024, 1, 15, 10, 30, 0);

      final result = MessageTags.withTime(original, time);

      expect(result['msgid'], equals('abc123'));
      expect(result['time'], equals('2024-01-15T10:30:00.000Z'));
    });

    test('does not modify original map', () {
      final original = <String, String?>{'msgid': 'abc123'};
      final time = DateTime.utc(2024, 1, 15, 10, 30, 0);

      MessageTags.withTime(original, time);

      expect(original.containsKey('time'), isFalse);
    });
  });

  group('MessageTags.withMsgId', () {
    test('adds msgid tag', () {
      final original = <String, String?>{'time': '2024-01-15T10:30:00.000Z'};
      final result = MessageTags.withMsgId(original, 'xyz789');

      expect(result['msgid'], equals('xyz789'));
      expect(result['time'], equals('2024-01-15T10:30:00.000Z'));
    });
  });

  group('MessageTags.withLabel', () {
    test('adds label tag', () {
      final original = <String, String?>{};
      final result = MessageTags.withLabel(original, 'req001');

      expect(result['label'], equals('req001'));
    });
  });

  group('MessageTags.withBatch', () {
    test('adds batch tag', () {
      final original = <String, String?>{};
      final result = MessageTags.withBatch(original, 'batch123');

      expect(result['batch'], equals('batch123'));
    });
  });

  group('MessageTags.withReplyTo', () {
    test('adds reply tag with target msgid', () {
      final original = <String, String?>{};
      final result = MessageTags.withReplyTo(original, 'targetmsg123');

      expect(result['+draft/reply'], equals('targetmsg123'));
    });
  });
}

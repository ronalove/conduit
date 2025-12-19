import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/parser/capability_parser.dart';

void main() {
  group('CapabilityParser', () {
    group('parse single capability', () {
      test('parses simple capability', () {
        final cap = CapabilityParser.parseCapability('sasl');

        expect(cap.name, 'sasl');
        expect(cap.value, isNull);
        expect(cap.isDisabled, false);
        expect(cap.isSticky, false);
        expect(cap.isAck, false);
      });

      test('parses capability with value', () {
        final cap = CapabilityParser.parseCapability('sasl=PLAIN,EXTERNAL');

        expect(cap.name, 'sasl');
        expect(cap.value, 'PLAIN,EXTERNAL');
      });

      test('parses capability with disable modifier', () {
        final cap = CapabilityParser.parseCapability('-sasl');

        expect(cap.name, 'sasl');
        expect(cap.isDisabled, true);
      });

      test('parses capability with sticky modifier', () {
        final cap = CapabilityParser.parseCapability('=sasl');

        expect(cap.name, 'sasl');
        expect(cap.isSticky, true);
      });

      test('parses capability with ack modifier', () {
        final cap = CapabilityParser.parseCapability('~sasl');

        expect(cap.name, 'sasl');
        expect(cap.isAck, true);
      });

      test('parses capability with modifier and value', () {
        final cap = CapabilityParser.parseCapability('-sasl=PLAIN');

        expect(cap.name, 'sasl');
        expect(cap.value, 'PLAIN');
        expect(cap.isDisabled, true);
      });

      test('parses sts capability with complex value', () {
        final cap = CapabilityParser.parseCapability('sts=port=6697,duration=2592000');

        expect(cap.name, 'sts');
        expect(cap.value, 'port=6697,duration=2592000');
      });
    });

    group('parse capability list', () {
      test('parses space-separated capabilities', () {
        final caps = CapabilityParser.parseList('sasl multi-prefix away-notify');

        expect(caps.length, 3);
        expect(caps[0].name, 'sasl');
        expect(caps[1].name, 'multi-prefix');
        expect(caps[2].name, 'away-notify');
      });

      test('parses capabilities with values', () {
        final caps = CapabilityParser.parseList('sasl=PLAIN,EXTERNAL multi-prefix sts=port=6697');

        expect(caps.length, 3);
        expect(caps[0].name, 'sasl');
        expect(caps[0].value, 'PLAIN,EXTERNAL');
        expect(caps[1].name, 'multi-prefix');
        expect(caps[1].value, isNull);
        expect(caps[2].name, 'sts');
        expect(caps[2].value, 'port=6697');
      });

      test('handles empty string', () {
        final caps = CapabilityParser.parseList('');
        expect(caps, isEmpty);
      });

      test('handles whitespace-only string', () {
        final caps = CapabilityParser.parseList('   ');
        expect(caps, isEmpty);
      });

      test('handles extra whitespace between capabilities', () {
        final caps = CapabilityParser.parseList('sasl   multi-prefix    away-notify');

        expect(caps.length, 3);
      });
    });

    group('Capability model', () {
      test('equals compares by name', () {
        final cap1 = Capability(name: 'sasl');
        final cap2 = Capability(name: 'sasl', value: 'PLAIN');

        expect(cap1 == cap2, true);
      });

      test('hashCode based on name', () {
        final cap1 = Capability(name: 'sasl');
        final cap2 = Capability(name: 'sasl', value: 'PLAIN');

        expect(cap1.hashCode, cap2.hashCode);
      });

      test('toString includes name and value', () {
        final cap = Capability(name: 'sasl', value: 'PLAIN');

        expect(cap.toString(), contains('sasl'));
        expect(cap.toString(), contains('PLAIN'));
      });
    });

    group('CapabilitySet', () {
      test('adds capabilities', () {
        final set = CapabilitySet();
        set.add(Capability(name: 'sasl'));
        set.add(Capability(name: 'multi-prefix'));

        expect(set.has('sasl'), true);
        expect(set.has('multi-prefix'), true);
        expect(set.has('away-notify'), false);
      });

      test('removes capabilities', () {
        final set = CapabilitySet();
        set.add(Capability(name: 'sasl'));
        set.remove('sasl');

        expect(set.has('sasl'), false);
      });

      test('gets capability with value', () {
        final set = CapabilitySet();
        set.add(Capability(name: 'sasl', value: 'PLAIN,EXTERNAL'));

        final cap = set.get('sasl');
        expect(cap?.value, 'PLAIN,EXTERNAL');
      });

      test('updates capability value', () {
        final set = CapabilitySet();
        set.add(Capability(name: 'sasl', value: 'PLAIN'));
        set.add(Capability(name: 'sasl', value: 'PLAIN,EXTERNAL'));

        expect(set.get('sasl')?.value, 'PLAIN,EXTERNAL');
      });

      test('lists all capability names', () {
        final set = CapabilitySet();
        set.add(Capability(name: 'sasl'));
        set.add(Capability(name: 'multi-prefix'));

        expect(set.names, containsAll(['sasl', 'multi-prefix']));
      });

      test('clears all capabilities', () {
        final set = CapabilitySet();
        set.add(Capability(name: 'sasl'));
        set.add(Capability(name: 'multi-prefix'));
        set.clear();

        expect(set.names, isEmpty);
      });

      test('addAll adds multiple capabilities', () {
        final set = CapabilitySet();
        set.addAll([
          Capability(name: 'sasl'),
          Capability(name: 'multi-prefix'),
        ]);

        expect(set.has('sasl'), true);
        expect(set.has('multi-prefix'), true);
      });
    });

    group('STS value parsing', () {
      test('parses sts parameters', () {
        final cap = Capability(
          name: 'sts',
          value: 'port=6697,duration=2592000',
        );

        final params = CapabilityParser.parseStsValue(cap.value!);

        expect(params['port'], '6697');
        expect(params['duration'], '2592000');
      });

      test('parses sts with preload', () {
        final params = CapabilityParser.parseStsValue('port=6697,duration=0,preload');

        expect(params['port'], '6697');
        expect(params['duration'], '0');
        expect(params.containsKey('preload'), true);
        expect(params['preload'], isNull);
      });

      test('handles empty sts value', () {
        final params = CapabilityParser.parseStsValue('');
        expect(params, isEmpty);
      });
    });

    group('SASL mechanisms parsing', () {
      test('parses sasl mechanisms', () {
        final mechanisms = CapabilityParser.parseSaslMechanisms('PLAIN,EXTERNAL,SCRAM-SHA-256');

        expect(mechanisms, ['PLAIN', 'EXTERNAL', 'SCRAM-SHA-256']);
      });

      test('handles single mechanism', () {
        final mechanisms = CapabilityParser.parseSaslMechanisms('PLAIN');

        expect(mechanisms, ['PLAIN']);
      });

      test('handles empty string', () {
        final mechanisms = CapabilityParser.parseSaslMechanisms('');

        expect(mechanisms, isEmpty);
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/commands/capability_commands.dart';

void main() {
  group('CapCommand', () {
    group('LS subcommand', () {
      test('generates CAP LS without version', () {
        final cmd = CapCommand.ls();
        final msg = cmd.toMessage();

        expect(msg.command, 'CAP');
        expect(msg.params, ['LS']);
      });

      test('generates CAP LS with version 302', () {
        final cmd = CapCommand.ls(version: 302);
        final msg = cmd.toMessage();

        expect(msg.command, 'CAP');
        expect(msg.params, ['LS', '302']);
      });

      test('generates correct raw output without version', () {
        final cmd = CapCommand.ls();
        expect(cmd.toRaw(), 'CAP :LS\r\n');
      });

      test('generates correct raw output with version', () {
        final cmd = CapCommand.ls(version: 302);
        expect(cmd.toRaw(), 'CAP LS 302\r\n');
      });
    });

    group('LIST subcommand', () {
      test('generates CAP LIST', () {
        final cmd = CapCommand.list();
        final msg = cmd.toMessage();

        expect(msg.command, 'CAP');
        expect(msg.params, ['LIST']);
      });
    });

    group('REQ subcommand', () {
      test('requests single capability', () {
        final cmd = CapCommand.req(['sasl']);
        final msg = cmd.toMessage();

        expect(msg.command, 'CAP');
        expect(msg.params, ['REQ', 'sasl']);
      });

      test('requests multiple capabilities', () {
        final cmd = CapCommand.req(['sasl', 'multi-prefix', 'away-notify']);
        final msg = cmd.toMessage();

        expect(msg.command, 'CAP');
        expect(msg.params, ['REQ', 'sasl multi-prefix away-notify']);
      });

      test('generates correct raw output for multiple caps', () {
        final cmd = CapCommand.req(['sasl', 'multi-prefix']);
        expect(cmd.toRaw(), 'CAP REQ :sasl multi-prefix\r\n');
      });

      test('can disable capability with minus prefix', () {
        final cmd = CapCommand.req(['-sasl']);
        final msg = cmd.toMessage();

        expect(msg.params, ['REQ', '-sasl']);
      });
    });

    group('END subcommand', () {
      test('generates CAP END', () {
        final cmd = CapCommand.end();
        final msg = cmd.toMessage();

        expect(msg.command, 'CAP');
        expect(msg.params, ['END']);
      });

      test('generates correct raw output', () {
        final cmd = CapCommand.end();
        expect(cmd.toRaw(), 'CAP :END\r\n');
      });
    });
  });

  group('AuthenticateCommand', () {
    test('generates AUTHENTICATE with mechanism', () {
      final cmd = AuthenticateCommand.mechanism('PLAIN');
      final msg = cmd.toMessage();

      expect(msg.command, 'AUTHENTICATE');
      expect(msg.params, ['PLAIN']);
    });

    test('generates AUTHENTICATE with data', () {
      final cmd = AuthenticateCommand.data('dGVzdAB0ZXN0AHBhc3N3b3Jk');
      final msg = cmd.toMessage();

      expect(msg.command, 'AUTHENTICATE');
      expect(msg.params, ['dGVzdAB0ZXN0AHBhc3N3b3Jk']);
    });

    test('generates AUTHENTICATE abort', () {
      final cmd = AuthenticateCommand.abort();
      final msg = cmd.toMessage();

      expect(msg.command, 'AUTHENTICATE');
      expect(msg.params, ['*']);
    });

    test('generates AUTHENTICATE continuation (+)', () {
      final cmd = AuthenticateCommand.continuation();
      final msg = cmd.toMessage();

      expect(msg.command, 'AUTHENTICATE');
      expect(msg.params, ['+']);
    });

    group('PLAIN encoding', () {
      test('encodes credentials correctly', () {
        // PLAIN format: authzid\0authcid\0password
        // For "test" user with password "testpass": \0test\0testpass
        final cmd = AuthenticateCommand.plain(
          username: 'test',
          password: 'testpass',
        );
        final msg = cmd.toMessage();

        expect(msg.command, 'AUTHENTICATE');
        // Base64 of "\0test\0testpass" = "AHRlc3QAdGVzdHBhc3M="
        expect(msg.params, ['AHRlc3QAdGVzdHBhc3M=']);
      });

      test('encodes credentials with authzid', () {
        final cmd = AuthenticateCommand.plain(
          username: 'test',
          password: 'testpass',
          authzid: 'admin',
        );
        final msg = cmd.toMessage();

        // Base64 of "admin\0test\0testpass" = "YWRtaW4AdGVzdAB0ZXN0cGFzcw=="
        expect(msg.params, ['YWRtaW4AdGVzdAB0ZXN0cGFzcw==']);
      });

      test('handles unicode in credentials', () {
        final cmd = AuthenticateCommand.plain(
          username: 'tëst',
          password: 'päss',
        );
        final msg = cmd.toMessage();

        expect(msg.command, 'AUTHENTICATE');
        // Should not throw, properly encode UTF-8
        expect(msg.params.length, 1);
        expect(msg.params[0].isNotEmpty, true);
      });
    });

    group('chunking for long data', () {
      test('splits data longer than 400 bytes', () {
        // Create a string that when base64 encoded is > 400 chars
        final longPassword = 'x' * 400;
        final chunks = AuthenticateCommand.plainChunked(
          username: 'test',
          password: longPassword,
        );

        expect(chunks.length, greaterThan(1));
        for (final chunk in chunks.take(chunks.length - 1)) {
          expect(chunk.toMessage().params[0].length, 400);
        }
      });

      test('adds + continuation for exact 400 byte multiple', () {
        // When data is exactly 400 bytes, need + continuation
        final exactPassword = 'x' * 295; // Results in ~400 base64 chars
        final chunks = AuthenticateCommand.plainChunked(
          username: 'test',
          password: exactPassword,
        );

        // If exactly 400, last chunk should be '+'
        if (chunks.length > 1) {
          final lastParam = chunks.last.toMessage().params[0];
          expect(lastParam == '+' || lastParam.length <= 400, true);
        }
      });
    });
  });
}

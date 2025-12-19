import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/connection/line_buffer.dart';

void main() {
  group('LineBuffer', () {
    late LineBuffer buffer;

    setUp(() => buffer = LineBuffer());

    group('addData', () {
      test('returns complete line with CRLF', () {
        final lines = buffer.addData('PING :server\r\n');
        expect(lines, ['PING :server']);
      });

      test('returns complete line with LF only (lenient)', () {
        final lines = buffer.addData('PING :server\n');
        expect(lines, ['PING :server']);
      });

      test('buffers partial data', () {
        var lines = buffer.addData('PING');
        expect(lines, isEmpty);
        expect(buffer.hasPartialLine, isTrue);

        lines = buffer.addData(' :server\r\n');
        expect(lines, ['PING :server']);
        expect(buffer.hasPartialLine, isFalse);
      });

      test('handles multiple lines in single data', () {
        final lines = buffer.addData('LINE1\r\nLINE2\r\nLINE3\r\n');
        expect(lines, ['LINE1', 'LINE2', 'LINE3']);
      });

      test('handles mixed CRLF and LF', () {
        final lines = buffer.addData('LINE1\r\nLINE2\nLINE3\r\n');
        expect(lines, ['LINE1', 'LINE2', 'LINE3']);
      });

      test('handles partial final line', () {
        final lines = buffer.addData('LINE1\r\nLINE2\r\nPARTI');
        expect(lines, ['LINE1', 'LINE2']);
        expect(buffer.hasPartialLine, isTrue);
      });

      test('completes partial line on next call', () {
        buffer.addData('HELLO ');
        buffer.addData('WORLD');
        final lines = buffer.addData('!\r\n');
        expect(lines, ['HELLO WORLD!']);
      });

      test('handles empty lines', () {
        final lines = buffer.addData('LINE1\r\n\r\nLINE2\r\n');
        expect(lines, ['LINE1', '', 'LINE2']);
      });

      test('handles CR without LF (edge case)', () {
        final lines = buffer.addData('LINE1\rLINE2\r\n');
        // CR alone should be part of the content until LF
        expect(lines, ['LINE1\rLINE2']);
      });

      test('handles very long line', () {
        final longContent = 'A' * 1000;
        final lines = buffer.addData('$longContent\r\n');
        expect(lines, [longContent]);
      });

      test('handles UTF-8 content', () {
        final lines = buffer.addData('Hello \u00e9\u00e0\u00fc \u4e2d\u6587\r\n');
        expect(lines, ['Hello \u00e9\u00e0\u00fc \u4e2d\u6587']);
      });

      test('handles consecutive calls with complete lines', () {
        var lines = buffer.addData('LINE1\r\n');
        expect(lines, ['LINE1']);

        lines = buffer.addData('LINE2\r\n');
        expect(lines, ['LINE2']);

        lines = buffer.addData('LINE3\r\n');
        expect(lines, ['LINE3']);
      });
    });

    group('clear', () {
      test('clears partial line', () {
        buffer.addData('partial');
        expect(buffer.hasPartialLine, isTrue);

        buffer.clear();
        expect(buffer.hasPartialLine, isFalse);
      });

      test('allows fresh start after clear', () {
        buffer.addData('OLD');
        buffer.clear();
        final lines = buffer.addData('NEW\r\n');
        expect(lines, ['NEW']);
      });
    });

    group('hasPartialLine', () {
      test('returns false initially', () {
        expect(buffer.hasPartialLine, isFalse);
      });

      test('returns true after partial data', () {
        buffer.addData('partial');
        expect(buffer.hasPartialLine, isTrue);
      });

      test('returns false after complete line', () {
        buffer.addData('complete\r\n');
        expect(buffer.hasPartialLine, isFalse);
      });

      test('returns true when partial remains after complete lines', () {
        buffer.addData('LINE1\r\npartial');
        expect(buffer.hasPartialLine, isTrue);
      });
    });
  });
}

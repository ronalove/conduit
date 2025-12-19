import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/protocol/numeric_handler.dart';
import 'package:conduit/core/constants/irc_numerics.dart';

void main() {
  group('NumericHandler', () {
    late NumericHandler handler;
    late List<IrcMessage> handledMessages;

    setUp(() {
      handledMessages = [];
      handler = NumericHandler();
    });

    group('registerHandler', () {
      test('routes to registered handler', () {
        handler.registerHandler(001, (msg) => handledMessages.add(msg));

        final msg = IrcMessage(command: '001', params: ['nick', 'Welcome']);
        handler.handle(msg);

        expect(handledMessages, [msg]);
      });

      test('ignores non-numeric commands', () {
        handler.registerHandler(001, (msg) => handledMessages.add(msg));

        final msg = IrcMessage(command: 'PRIVMSG', params: ['#chan', 'Hi']);
        handler.handle(msg);

        expect(handledMessages, isEmpty);
      });

      test('supports multiple handlers per numeric', () {
        var count = 0;
        handler.registerHandler(001, (_) => count++);
        handler.registerHandler(001, (_) => count++);

        handler.handle(IrcMessage(command: '001', params: []));

        expect(count, 2);
      });

      test('calls handlers in registration order', () {
        final order = <int>[];
        handler.registerHandler(001, (_) => order.add(1));
        handler.registerHandler(001, (_) => order.add(2));
        handler.registerHandler(001, (_) => order.add(3));

        handler.handle(IrcMessage(command: '001', params: []));

        expect(order, [1, 2, 3]);
      });
    });

    group('registerHandlers', () {
      test('registers multiple handlers at once', () {
        final received = <int>[];
        handler.registerHandlers({
          001: (msg) => received.add(1),
          002: (msg) => received.add(2),
          003: (msg) => received.add(3),
        });

        handler.handle(IrcMessage(command: '001', params: []));
        handler.handle(IrcMessage(command: '002', params: []));
        handler.handle(IrcMessage(command: '003', params: []));

        expect(received, [1, 2, 3]);
      });
    });

    group('defaultHandler', () {
      test('calls default handler for unregistered numerics', () {
        final defaultMessages = <IrcMessage>[];
        final handlerWithDefault = NumericHandler(
          defaultHandler: (msg) => defaultMessages.add(msg),
        );

        final msg = IrcMessage(command: '999', params: ['test']);
        handlerWithDefault.handle(msg);

        expect(defaultMessages, [msg]);
      });

      test('does not call default handler for registered numerics', () {
        final defaultMessages = <IrcMessage>[];
        final handlerWithDefault = NumericHandler(
          defaultHandler: (msg) => defaultMessages.add(msg),
        );

        handlerWithDefault.registerHandler(001, (msg) => handledMessages.add(msg));

        final msg = IrcMessage(command: '001', params: ['nick', 'Welcome']);
        handlerWithDefault.handle(msg);

        expect(handledMessages, [msg]);
        expect(defaultMessages, isEmpty);
      });
    });

    group('removeHandler', () {
      test('removes registered handler', () {
        void callback(IrcMessage msg) => handledMessages.add(msg);
        handler.registerHandler(001, callback);
        handler.removeHandler(001, callback);

        handler.handle(IrcMessage(command: '001', params: []));

        expect(handledMessages, isEmpty);
      });

      test('removes only specified handler', () {
        final results = <int>[];
        void callback1(IrcMessage _) => results.add(1);
        void callback2(IrcMessage _) => results.add(2);

        handler.registerHandler(001, callback1);
        handler.registerHandler(001, callback2);
        handler.removeHandler(001, callback1);

        handler.handle(IrcMessage(command: '001', params: []));

        expect(results, [2]);
      });
    });

    group('clearHandlers', () {
      test('removes all handlers for a numeric', () {
        handler.registerHandler(001, (msg) => handledMessages.add(msg));
        handler.registerHandler(001, (msg) => handledMessages.add(msg));
        handler.clearHandlers(001);

        handler.handle(IrcMessage(command: '001', params: []));

        expect(handledMessages, isEmpty);
      });
    });
  });

  group('IrcNumerics', () {
    test('has correct welcome numeric', () {
      expect(IrcNumerics.rplWelcome, 1);
    });

    test('has correct names reply numeric', () {
      expect(IrcNumerics.rplNamReply, 353);
    });

    test('has correct end of names numeric', () {
      expect(IrcNumerics.rplEndOfNames, 366);
    });

    test('isError returns true for error numerics', () {
      expect(IrcNumerics.isError(401), isTrue);
      expect(IrcNumerics.isError(403), isTrue);
      expect(IrcNumerics.isError(433), isTrue);
      expect(IrcNumerics.isError(474), isTrue);
    });

    test('isError returns false for non-error numerics', () {
      expect(IrcNumerics.isError(001), isFalse);
      expect(IrcNumerics.isError(353), isFalse);
      expect(IrcNumerics.isError(366), isFalse);
    });

    test('isError handles SASL numerics correctly', () {
      expect(IrcNumerics.isError(900), isFalse); // rplLoggedIn
      expect(IrcNumerics.isError(903), isFalse); // rplSaslSuccess
      expect(IrcNumerics.isError(904), isTrue);  // errSaslFail
      expect(IrcNumerics.isError(906), isTrue);  // errSaslAborted
    });
  });
}

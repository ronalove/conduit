import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/protocol/sasl_authenticator.dart';
import 'package:conduit/core/irc/parser/irc_message.dart';
import 'package:conduit/core/irc/commands/capability_commands.dart';

void main() {
  group('SaslAuthenticator', () {
    late SaslAuthenticator authenticator;

    setUp(() {
      authenticator = SaslAuthenticator();
    });

    group('initial state', () {
      test('starts in idle state', () {
        expect(authenticator.state, SaslState.idle);
      });

      test('is not authenticated', () {
        expect(authenticator.isAuthenticated, false);
      });

      test('has no account info', () {
        expect(authenticator.account, isNull);
      });
    });

    group('startAuthentication', () {
      test('returns AUTHENTICATE PLAIN command', () {
        final cmd = authenticator.startAuthentication(mechanism: 'PLAIN');

        expect(cmd, isA<AuthenticateCommand>());
        final msg = cmd.toMessage();
        expect(msg.command, 'AUTHENTICATE');
        expect(msg.params, ['PLAIN']);
      });

      test('transitions to mechanismSent state', () {
        authenticator.startAuthentication(mechanism: 'PLAIN');
        expect(authenticator.state, SaslState.mechanismSent);
      });

      test('defaults to PLAIN mechanism', () {
        final cmd = authenticator.startAuthentication();
        final msg = cmd.toMessage();
        expect(msg.params, ['PLAIN']);
      });
    });

    group('handleMessage', () {
      group('AUTHENTICATE + response', () {
        test('prompts for credentials', () {
          authenticator.startAuthentication();

          final msg = IrcMessage(command: 'AUTHENTICATE', params: ['+']);
          final result = authenticator.handleMessage(msg);

          expect(result.type, SaslResultType.credentialsNeeded);
          expect(authenticator.state, SaslState.waitingForCredentials);
        });
      });

      group('sendCredentials', () {
        test('returns AUTHENTICATE command with encoded credentials', () {
          authenticator.startAuthentication();
          authenticator.handleMessage(
            IrcMessage(command: 'AUTHENTICATE', params: ['+']),
          );

          final cmd = authenticator.sendCredentials(
            username: 'testuser',
            password: 'testpass',
          );

          expect(cmd, isA<AuthenticateCommand>());
          expect(authenticator.state, SaslState.credentialsSent);
        });

        test('supports authzid', () {
          authenticator.startAuthentication();
          authenticator.handleMessage(
            IrcMessage(command: 'AUTHENTICATE', params: ['+']),
          );

          final cmd = authenticator.sendCredentials(
            username: 'testuser',
            password: 'testpass',
            authzid: 'admin',
          );

          expect(cmd, isA<AuthenticateCommand>());
        });
      });

      group('900 RPL_LOGGEDIN', () {
        test('stores account information', () {
          authenticator.startAuthentication();
          authenticator.handleMessage(
            IrcMessage(command: 'AUTHENTICATE', params: ['+']),
          );
          authenticator.sendCredentials(
            username: 'testuser',
            password: 'testpass',
          );

          final msg = IrcMessage(
            command: '900',
            params: ['nick', 'nick!user@host', 'account', 'You are now logged in as account'],
          );
          final result = authenticator.handleMessage(msg);

          expect(result.type, SaslResultType.loggedIn);
          expect(authenticator.account, 'account');
        });
      });

      group('903 RPL_SASLSUCCESS', () {
        test('marks authentication as successful', () {
          authenticator.startAuthentication();
          authenticator.handleMessage(
            IrcMessage(command: 'AUTHENTICATE', params: ['+']),
          );
          authenticator.sendCredentials(
            username: 'testuser',
            password: 'testpass',
          );
          // 900 logged in
          authenticator.handleMessage(IrcMessage(
            command: '900',
            params: ['nick', 'nick!user@host', 'testuser', 'Logged in'],
          ));

          final msg = IrcMessage(
            command: '903',
            params: ['nick', 'SASL authentication successful'],
          );
          final result = authenticator.handleMessage(msg);

          expect(result.type, SaslResultType.success);
          expect(authenticator.state, SaslState.authenticated);
          expect(authenticator.isAuthenticated, true);
        });
      });

      group('error numerics', () {
        setUp(() {
          authenticator.startAuthentication();
          authenticator.handleMessage(
            IrcMessage(command: 'AUTHENTICATE', params: ['+']),
          );
          authenticator.sendCredentials(
            username: 'testuser',
            password: 'testpass',
          );
        });

        test('902 ERR_NICKLOCKED', () {
          final msg = IrcMessage(
            command: '902',
            params: ['nick', 'You must use a nick assigned to you'],
          );
          final result = authenticator.handleMessage(msg);

          expect(result.type, SaslResultType.error);
          expect(result.error, SaslError.nickLocked);
          expect(authenticator.state, SaslState.failed);
        });

        test('904 ERR_SASLFAIL', () {
          final msg = IrcMessage(
            command: '904',
            params: ['nick', 'SASL authentication failed'],
          );
          final result = authenticator.handleMessage(msg);

          expect(result.type, SaslResultType.error);
          expect(result.error, SaslError.authFailed);
          expect(authenticator.state, SaslState.failed);
        });

        test('905 ERR_SASLTOOLONG', () {
          final msg = IrcMessage(
            command: '905',
            params: ['nick', 'SASL message too long'],
          );
          final result = authenticator.handleMessage(msg);

          expect(result.type, SaslResultType.error);
          expect(result.error, SaslError.tooLong);
        });

        test('906 ERR_SASLABORTED', () {
          final msg = IrcMessage(
            command: '906',
            params: ['nick', 'SASL authentication aborted'],
          );
          final result = authenticator.handleMessage(msg);

          expect(result.type, SaslResultType.error);
          expect(result.error, SaslError.aborted);
        });

        test('907 ERR_SASLALREADY', () {
          final msg = IrcMessage(
            command: '907',
            params: ['nick', 'You have already authenticated'],
          );
          final result = authenticator.handleMessage(msg);

          expect(result.type, SaslResultType.error);
          expect(result.error, SaslError.alreadyAuthenticated);
        });

        test('908 RPL_SASLMECHS', () {
          final msg = IrcMessage(
            command: '908',
            params: ['nick', 'PLAIN,EXTERNAL', 'are available SASL mechanisms'],
          );
          final result = authenticator.handleMessage(msg);

          expect(result.type, SaslResultType.mechanismsAvailable);
          expect(result.mechanisms, containsAll(['PLAIN', 'EXTERNAL']));
        });
      });
    });

    group('abort', () {
      test('returns AUTHENTICATE * command', () {
        authenticator.startAuthentication();

        final cmd = authenticator.abort();

        final msg = cmd.toMessage();
        expect(msg.command, 'AUTHENTICATE');
        expect(msg.params, ['*']);
      });

      test('transitions to aborted state', () {
        authenticator.startAuthentication();
        authenticator.abort();

        expect(authenticator.state, SaslState.aborted);
      });
    });

    group('reset', () {
      test('clears all state', () {
        authenticator.startAuthentication();
        authenticator.handleMessage(
          IrcMessage(command: 'AUTHENTICATE', params: ['+']),
        );
        authenticator.sendCredentials(
          username: 'testuser',
          password: 'testpass',
        );
        authenticator.handleMessage(IrcMessage(
          command: '900',
          params: ['nick', 'nick!user@host', 'testuser', 'Logged in'],
        ));
        authenticator.handleMessage(IrcMessage(
          command: '903',
          params: ['nick', 'SASL authentication successful'],
        ));

        authenticator.reset();

        expect(authenticator.state, SaslState.idle);
        expect(authenticator.isAuthenticated, false);
        expect(authenticator.account, isNull);
      });
    });

    group('state stream', () {
      test('emits state changes', () async {
        final states = <SaslState>[];
        authenticator.states.listen((state) => states.add(state));

        authenticator.startAuthentication();
        authenticator.handleMessage(
          IrcMessage(command: 'AUTHENTICATE', params: ['+']),
        );

        await Future.delayed(Duration.zero);

        expect(states, contains(SaslState.mechanismSent));
        expect(states, contains(SaslState.waitingForCredentials));
      });
    });

    group('supported mechanisms', () {
      test('PLAIN is supported', () {
        expect(SaslAuthenticator.supportedMechanisms, contains('PLAIN'));
      });

      test('isMechanismSupported returns true for PLAIN', () {
        expect(SaslAuthenticator.isMechanismSupported('PLAIN'), true);
      });

      test('isMechanismSupported returns false for unsupported', () {
        expect(SaslAuthenticator.isMechanismSupported('SCRAM-SHA-256'), false);
      });
    });
  });
}

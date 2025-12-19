import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:conduit/features/auth/services/auth_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('AuthService', () {
    late MockFlutterSecureStorage mockStorage;
    late AuthService authService;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      authService = AuthService(storage: mockStorage);
    });

    group('saveCredentials', () {
      test('stores username and password', () async {
        when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
            .thenAnswer((_) async {});

        await authService.saveCredentials(
          username: 'testuser',
          password: 'testpass',
        );

        verify(() => mockStorage.write(key: 'conduit_username', value: 'testuser')).called(1);
        verify(() => mockStorage.write(key: 'conduit_password', value: 'testpass')).called(1);
      });
    });

    group('loadCredentials', () {
      test('returns credentials when stored', () async {
        when(() => mockStorage.read(key: 'conduit_username'))
            .thenAnswer((_) async => 'testuser');
        when(() => mockStorage.read(key: 'conduit_password'))
            .thenAnswer((_) async => 'testpass');

        final credentials = await authService.loadCredentials();

        expect(credentials, isNotNull);
        expect(credentials!.username, 'testuser');
        expect(credentials.password, 'testpass');
      });

      test('returns null when username is missing', () async {
        when(() => mockStorage.read(key: 'conduit_username'))
            .thenAnswer((_) async => null);
        when(() => mockStorage.read(key: 'conduit_password'))
            .thenAnswer((_) async => 'testpass');

        final credentials = await authService.loadCredentials();

        expect(credentials, isNull);
      });

      test('returns null when password is missing', () async {
        when(() => mockStorage.read(key: 'conduit_username'))
            .thenAnswer((_) async => 'testuser');
        when(() => mockStorage.read(key: 'conduit_password'))
            .thenAnswer((_) async => null);

        final credentials = await authService.loadCredentials();

        expect(credentials, isNull);
      });

      test('returns null when both are missing', () async {
        when(() => mockStorage.read(key: 'conduit_username'))
            .thenAnswer((_) async => null);
        when(() => mockStorage.read(key: 'conduit_password'))
            .thenAnswer((_) async => null);

        final credentials = await authService.loadCredentials();

        expect(credentials, isNull);
      });
    });

    group('hasStoredCredentials', () {
      test('returns true when credentials exist', () async {
        when(() => mockStorage.read(key: 'conduit_username'))
            .thenAnswer((_) async => 'testuser');

        final hasCredentials = await authService.hasStoredCredentials();

        expect(hasCredentials, isTrue);
      });

      test('returns false when no credentials', () async {
        when(() => mockStorage.read(key: 'conduit_username'))
            .thenAnswer((_) async => null);

        final hasCredentials = await authService.hasStoredCredentials();

        expect(hasCredentials, isFalse);
      });
    });

    group('clearCredentials', () {
      test('deletes username and password', () async {
        when(() => mockStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await authService.clearCredentials();

        verify(() => mockStorage.delete(key: 'conduit_username')).called(1);
        verify(() => mockStorage.delete(key: 'conduit_password')).called(1);
      });
    });
  });

  group('StoredCredentials', () {
    test('holds username and password', () {
      const credentials = StoredCredentials(
        username: 'user',
        password: 'pass',
      );

      expect(credentials.username, 'user');
      expect(credentials.password, 'pass');
    });
  });
}

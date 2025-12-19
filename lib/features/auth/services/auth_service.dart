import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stored credentials data.
class StoredCredentials {
  final String username;
  final String password;

  const StoredCredentials({
    required this.username,
    required this.password,
  });
}

/// Service for securely storing authentication credentials.
///
/// Uses flutter_secure_storage to store credentials in the platform's
/// secure storage (Keychain on iOS/macOS, Keystore on Android).
class AuthService {
  static const _keyUsername = 'conduit_username';
  static const _keyPassword = 'conduit_password';

  final FlutterSecureStorage _storage;

  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock,
                synchronizable: false,
              ),
            );

  /// Save credentials to secure storage.
  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUsername, value: username),
      _storage.write(key: _keyPassword, value: password),
    ]);
  }

  /// Load credentials from secure storage.
  ///
  /// Returns null if no credentials are stored.
  Future<StoredCredentials?> loadCredentials() async {
    final results = await Future.wait([
      _storage.read(key: _keyUsername),
      _storage.read(key: _keyPassword),
    ]);

    final username = results[0];
    final password = results[1];

    if (username == null || password == null) {
      return null;
    }

    return StoredCredentials(username: username, password: password);
  }

  /// Check if credentials are stored.
  Future<bool> hasStoredCredentials() async {
    final username = await _storage.read(key: _keyUsername);
    return username != null;
  }

  /// Clear stored credentials.
  Future<void> clearCredentials() async {
    await Future.wait([
      _storage.delete(key: _keyUsername),
      _storage.delete(key: _keyPassword),
    ]);
  }
}

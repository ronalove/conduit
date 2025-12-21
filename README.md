# Knights Network

Client IRCv3 multi-plateforme (Windows, macOS, iOS, Android) developpe avec Flutter.

## Configuration

| Parametre | Valeur |
|-----------|--------|
| Serveur | Ergo (Oragono) |
| Connexion | TLS |
| SASL | PLAIN over TLS |
| Flutter | 3.38+ |
| Dart | 3.10+ |

## Plateformes

- Windows
- macOS
- Linux
- iOS
- Android

## Documentation

Voir le dossier `docs/` pour la documentation complete :
- [Manuel utilisateur](docs/USER_MANUAL.md)

## Developpement

### Prerequis

- Flutter 3.38+
- Dart 3.10+

### Installation

```bash
# Cloner le repository
git clone https://github.com/r9r-dev/conduit.git
cd conduit

# Installer les dependances
flutter pub get

# Lancer l'application
flutter run
```

## Releases

Les releases sont automatiquement buildees via GitHub Actions lors d'un push de tag.

### Creer une release

```bash
# Bumper la version et creer le tag
./scripts/bump_version.sh 1.0.0

# Ou manuellement:
# 1. Modifier version dans pubspec.yaml
# 2. Commit
# 3. git tag v1.0.0
# 4. git push origin main && git push origin v1.0.0
```

### Artifacts generes

| Plateforme | Format | Notes |
|------------|--------|-------|
| Android | APK | Installer via "sources inconnues" |
| macOS | DMG | Clic-droit > Ouvrir (non signe) |
| Windows | ZIP | Extraire et lancer .exe |
| Linux | AppImage | `chmod +x` puis executer |
| iOS | TestFlight | Necessite compte Apple Developer |

### Configuration Android Signing (optionnel)

Pour signer les APK avec votre propre cle :

1. Generer un keystore:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Ajouter les secrets GitHub:
   - `ANDROID_KEYSTORE_BASE64`: `base64 -i upload-keystore.jks`
   - `ANDROID_KEY_ALIAS`: `upload`
   - `ANDROID_KEY_PASSWORD`: votre mot de passe
   - `ANDROID_STORE_PASSWORD`: votre mot de passe

## Features IRCv3 Supportees

### Core
- [x] CAP 302 - Enhanced Capability Negotiation
- [x] cap-notify - Capability Change Notification
- [x] SASL v3.2 - PLAIN Authentication
- [x] message-tags - Full Tag Support
- [x] msgid - Message ID Tag
- [x] server-time - Server Timestamp
- [x] echo-message - Message Echo
- [x] labeled-response - Request/Response Correlation
- [x] standard-replies - Standard Reply Format
- [x] multi-prefix - Multiple User Modes
- [x] UTF8ONLY - UTF-8 Enforcement

### Presence & Users
- [x] away-notify - Away Status Notification
- [x] account-notify - Account Change Notification
- [x] account-tag - Account Tag on Messages
- [x] chghost - Host Change Notification
- [x] setname - Realname Change
- [x] extended-join - Extended JOIN Information
- [x] invite-notify - Invite Notification
- [x] Monitor - User Presence Monitoring
- [x] WHOX - Extended WHO Query

### Batch & History
- [x] batch - Batch Message Grouping
- [x] multiline - Multi-line Messages
- [x] chathistory - Message History Retrieval
- [x] read-marker - Read Position Tracking

### Interactive
- [x] +typing - Typing Indicator
- [x] reply - Message Reply Reference
- [x] channel-context - Channel Context for DMs

### Security
- [x] sts - Strict Transport Security

## Roadmap

Voir les [Milestones](https://github.com/r9r-dev/conduit/milestones) pour le suivi du developpement.

## References

### IRCv3 Specifications
- **IRCv3 Primary Core** : https://modern.ircdocs.horse
- **IRCv3 Specifications** : https://ircv3.net/irc/

## License

MIT

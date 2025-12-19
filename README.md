# Conduit

Client IRCv3 multi-plateforme (Windows, macOS, iOS, Android) developpé avec Flutter.

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

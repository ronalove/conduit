# Conduit - Instructions Claude Code

## Projet

Client IRCv3 multi-plateforme (Windows, macOS, iOS, Android) avec Flutter.

## Stack Technique

- **Framework** : Flutter 3.38+ / Dart 3.10+
- **State Management** : Riverpod 3.x
- **Routing** : go_router
- **Storage** : flutter_secure_storage, shared_preferences
- **Networking** : dart:io (TCP/TLS natif)

## Architecture

```
lib/
├── core/
│   ├── irc/
│   │   ├── commands/      # IRC commands (NICK, JOIN, PRIVMSG, etc.)
│   │   ├── connection/    # Socket manager, line buffer, reconnect
│   │   ├── parser/        # Message & tag parsing
│   │   ├── protocol/      # Numeric handlers
│   │   └── state/         # Connection state machine
│   ├── constants/         # IRC numerics
│   └── models/            # Data models (User, Channel, Message)
├── features/              # UI features (auth, chat, channels, settings)
├── services/              # Storage, notifications
├── theme/                 # Dark theme uniquement
├── layouts/               # Adaptive layouts (desktop/mobile)
└── routing/               # Navigation
```

## Phase 1: Foundation (Complete)

Core IRC implementee avec TDD:
- `TagParser` : IRCv3 message-tags avec escape sequences
- `IrcParser` / `IrcMessage` : parsing/serialization de messages
- `SocketManager` : TCP/TLS via SecureSocket
- `ConnectionStateMachine` : etats disconnected/connecting/registering/connected
- `IrcCommand` classes : NICK, USER, JOIN, PART, QUIT, PRIVMSG, etc.
- `NumericHandler` : dispatch des numerics (001-005, 353, 366, 4xx)

## Conventions

### Code Style
- Utiliser Riverpod pour le state management
- Utiliser freezed pour les models immutables
- Suivre les conventions Dart/Flutter officielles
- Pas de commentaires inutiles, code auto-documenté

### IRC Protocol
- Format message : `[@tags] [:source] <command> [params] [:trailing]`
- Line ending : `\r\n` (CRLF)
- Encodage : UTF-8
- TLS obligatoire (port 6697)

### Layouts
- Desktop (>1024dp) : 3 colonnes (channels, chat, users)
- Mobile (<600dp) : Portrait avec navigation bottom/drawer
- Tablet (600-1024dp) : Layout hybride

## Serveur Cible

- **Type** : Ergo (Oragono)
- **Connexion** : TLS uniquement
- **Auth** : SASL PLAIN over TLS

## IRCv3 Features

Capabilities a implémenter :
- CAP 302, cap-notify
- SASL v3.2 (PLAIN)
- message-tags, msgid, server-time
- echo-message, labeled-response
- batch, chathistory, multiline
- away-notify, account-notify, account-tag
- Monitor, WHOX
- +typing, reply, read-marker

## References

- IRCv3 Specs : https://ircv3.net/irc/
- Modern IRC : https://modern.ircdocs.horse
- GitHub Issues : https://github.com/r9r-dev/conduit/issues
- Milestones : https://github.com/r9r-dev/conduit/milestones

## Commandes Utiles

```bash
# Lancer l'app
flutter run

# Build
flutter build macos
flutter build ios
flutter build apk
flutter build windows

# Tests
flutter test
flutter test --coverage

# Code generation (freezed, riverpod)
dart run build_runner build --delete-conflicting-outputs
```

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

## Phase 2: CAP & SASL (Complete)

IRCv3 capability negotiation et authentification:
- `CapCommand` : CAP LS, LIST, REQ, END subcommands
- `AuthenticateCommand` : SASL PLAIN encoding, chunking
- `CapabilityParser` : parse cap=value format, modifiers (-, =, ~)
- `CapabilityNegotiator` : state machine idle -> negotiating -> completed
- `SaslAuthenticator` : SASL PLAIN flow avec error handling (902-908)
- `StsPolicy` / `StsPolicyStore` : STS policy storage et enforcement

### Fichiers cles Phase 2
```
lib/core/irc/
├── commands/
│   └── capability_commands.dart  # CAP, AUTHENTICATE commands
├── parser/
│   └── capability_parser.dart    # Capability, CapabilitySet, STS parsing
└── protocol/
    ├── capability_negotiator.dart # CAP negotiation state machine
    ├── sasl_authenticator.dart    # SASL PLAIN authentication
    └── sts_policy.dart            # STS policy management

integration_test/
├── cap_test.dart                  # CAP negotiation tests
├── sasl_test.dart                 # SASL authentication tests
└── sts_test.dart                  # STS policy tests
```

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

### Implementees (Phase 2)
- CAP 302, cap-notify ✓
- SASL v3.2 (PLAIN) ✓
- STS (Strict Transport Security) ✓

### A implementer (Phase 3+)
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

# Tests unitaires
flutter test
flutter test --coverage

# Tests d'integration (necessite serveur IRC)
export IRC_TEST_HOST="irc.example.com"
export IRC_TEST_NICK="conduit-test"
export IRC_TEST_USER="conduit"
flutter test integration_test/
# ou
./scripts/run_integration_tests.sh

# Code generation (freezed, riverpod)
dart run build_runner build --delete-conflicting-outputs
```

## Tests d'Integration

Infrastructure de tests d'integration avec serveur IRC (Ergo recommande).

### Variables d'environnement requises

- `IRC_TEST_HOST` : Hostname du serveur IRC
- `IRC_TEST_NICK` : Nickname pour les tests
- `IRC_TEST_USER` : Username pour les tests

### Variables optionnelles

- `IRC_TEST_PORT` : Port (defaut: 6697)
- `IRC_TEST_CHANNEL` : Canal de test (defaut: #conduit-test)
- `IRC_TEST_PASS` : Mot de passe serveur/SASL
- `IRC_TEST_ALLOW_INVALID_CERTS` : Accepter certificats auto-signes

### Couverture actuelle

- Connexion TLS et Registration
- CAP negotiation (LS, REQ, ACK, END)
- SASL PLAIN authentication
- STS policy detection

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

## Phase 3: Extensions Core (Complete)

IRCv3 extensions et utilitaires:
- `MessageTags` / `IrcTags` : utilitaires pour tags standard (time, msgid, account, batch, label)
- `IrcMessageExtensions` : extensions sur IrcMessage pour acces aux tags
- `EchoMessageHandler` : echo-message avec tracking des messages pending
- `LabeledResponseHandler` : correlation request/response avec labels
- `StandardReplyParser` / `StandardReply` : parsing FAIL/WARN/NOTE
- `UserPrefixParser` / `PrefixedUser` : multi-prefix pour modes utilisateur
- `IsupportParser` / `Isupport` : parsing ISUPPORT (005) avec UTF8ONLY

### Fichiers cles Phase 3
```
lib/core/irc/
├── parser/
│   ├── message_tags.dart          # IrcTags constants, MessageTags utils
│   ├── irc_message_extensions.dart # Extensions on IrcMessage
│   ├── standard_replies.dart      # FAIL/WARN/NOTE parsing
│   ├── user_prefix.dart           # Multi-prefix, PrefixedUser
│   └── isupport.dart              # ISUPPORT parsing, UTF8ONLY
└── protocol/
    ├── echo_message_handler.dart  # Echo-message tracking
    └── labeled_response_handler.dart # Request/response correlation

test/core/irc/
├── parser/
│   ├── message_tags_test.dart
│   ├── irc_message_extensions_test.dart
│   ├── standard_replies_test.dart
│   ├── user_prefix_test.dart
│   └── isupport_test.dart
└── protocol/
    ├── echo_message_handler_test.dart
    └── labeled_response_handler_test.dart
```

## Phase 4: Presence & Users (Complete)

Extensions IRCv3 pour presence et utilisateurs:
- `AwayCommand` / `AwayNotifyHandler` : away-notify notifications temps reel
- `AccountNotifyHandler` : account-notify login/logout notifications
- `MessageTags.hasAccount` / `IrcMessage.hasAccount` : account-tag support
- `ChghostHandler` : chghost host change notifications
- `SetnameCommand` / `SetnameHandler` : setname realname change
- `ExtendedJoinParser` / `ExtendedJoin` : extended-join avec account/realname
- `InviteNotifyHandler` : invite-notify pour membres du canal
- `MonitorCommand` / `MonitorHandler` : Monitor user presence tracking
- `WhoxCommand` / `WhoxParser` : WHOX extended WHO queries

### Fichiers cles Phase 4
```
lib/core/irc/
├── commands/
│   ├── presence_commands.dart    # AWAY, SETNAME commands
│   ├── monitor_commands.dart     # MONITOR +/-/C/L/S commands
│   └── whox_command.dart         # WHO with WHOX fields
├── parser/
│   ├── extended_join.dart        # Extended JOIN parsing
│   └── whox_parser.dart          # WHOX response parsing
└── protocol/
    ├── away_notify_handler.dart      # Away status notifications
    ├── account_notify_handler.dart   # Account change notifications
    ├── chghost_handler.dart          # Host change notifications
    ├── setname_handler.dart          # Realname change notifications
    ├── invite_notify_handler.dart    # Invite notifications
    └── monitor_handler.dart          # Monitor numerics (730-734)

test/core/irc/
├── commands/
│   ├── presence_commands_test.dart
│   ├── monitor_commands_test.dart
│   └── whox_command_test.dart
├── parser/
│   ├── extended_join_test.dart
│   └── whox_parser_test.dart
└── protocol/
    ├── away_notify_handler_test.dart
    ├── account_notify_handler_test.dart
    ├── chghost_handler_test.dart
    ├── setname_handler_test.dart
    ├── invite_notify_handler_test.dart
    └── monitor_handler_test.dart
```

## Phase 5: Batch & History (Complete)

Extensions IRCv3 pour batch et historique:
- `BatchCommand` : BATCH +/-reference commands
- `BatchHandler` : batch accumulation, nested batches, concurrent batches
- `ChathistoryCommand` : LATEST, BEFORE, AFTER, AROUND, BETWEEN, TARGETS
- `ChathistoryHandler` : process chathistory batches, error handling
- `MultilineHandler` : draft/multiline batch send/receive
- `MarkreadCommand` / `ReadMarkerHandler` : read position tracking

### Fichiers cles Phase 5
```
lib/core/irc/
├── commands/
│   ├── batch_commands.dart         # BATCH +/- commands
│   ├── chathistory_commands.dart   # CHATHISTORY subcommands
│   └── read_marker_commands.dart   # MARKREAD command
└── protocol/
    ├── batch_handler.dart          # Batch accumulation & nested batches
    ├── chathistory_handler.dart    # Chathistory batch processing
    ├── multiline_handler.dart      # Multiline message handling
    └── read_marker_handler.dart    # Read position tracking

test/core/irc/
├── commands/
│   ├── batch_commands_test.dart
│   ├── chathistory_commands_test.dart
│   └── read_marker_commands_test.dart
└── protocol/
    ├── batch_handler_test.dart
    ├── chathistory_handler_test.dart
    ├── multiline_handler_test.dart
    └── read_marker_handler_test.dart
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

### Implementees (Phase 3)
- message-tags (full tag support) ✓
- msgid (message ID) ✓
- server-time (ISO 8601 timestamps) ✓
- echo-message (message echo tracking) ✓
- labeled-response (request/response correlation) ✓
- standard-replies (FAIL/WARN/NOTE) ✓
- multi-prefix (multiple user modes) ✓
- UTF8ONLY (via ISUPPORT) ✓

### Implementees (Phase 4)
- away-notify (real-time away status) ✓
- account-notify (login/logout notifications) ✓
- account-tag (account on messages) ✓
- chghost (host change notifications) ✓
- setname (realname change) ✓
- extended-join (account/realname in JOIN) ✓
- invite-notify (invite notifications) ✓
- Monitor (user presence tracking) ✓
- WHOX (extended WHO queries) ✓

### Implementees (Phase 5)
- batch (message grouping, nested batches) ✓
- chathistory (LATEST, BEFORE, AFTER, AROUND, BETWEEN, TARGETS) ✓
- multiline (draft/multiline batches) ✓
- read-marker (draft/read-marker, MARKREAD) ✓

### A implementer (Phase 6+)
- +typing (typing notifications)
- reply (message replies)

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

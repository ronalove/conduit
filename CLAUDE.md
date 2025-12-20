# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Conduit is a modern IRCv3 client built with Flutter for cross-platform desktop and mobile support (macOS, Windows, iOS, Android). It implements 18+ IRCv3 specifications including SASL authentication, message history, typing indicators, and more.

**Conduit est le client dedie au serveur Ronan.** Il n'est pas concu comme un client IRC generique :
- Un seul serveur preconfigure (pas de configuration d'URL, pas d'ajout de serveurs)
- L'URL du serveur changera entre dev (IP locale) et prod (IP publique) mais c'est toujours le meme serveur
- Les credentials utilisateur sont stockes localement avec flutter_secure_storage

## Development Commands

```bash
# Dependencies
flutter pub get

# Code generation (required after model changes)
flutter pub run build_runner build
flutter pub run build_runner watch  # continuous mode

# Run application
flutter run -d macos    # macOS
flutter run -d windows  # Windows
flutter run -d ios      # iOS
flutter run -d android  # Android

# Testing
flutter test                           # unit tests
flutter test test/path/to/test.dart   # single test file
flutter test integration_test/         # integration tests

# Linting
flutter analyze
```

## Architecture

### Data Flow
```
TCP/TLS Socket -> LineBuffer -> IrcParser -> Protocol Handlers -> Riverpod Providers -> UI
                                                                         |
Commands Queue <- UI Events/Riverpod State <-----------------------------+
```

### Core Layers (`lib/core/irc/`)

- **connection/**: Socket/TLS management, reconnection policy, line buffering
- **parser/**: IRC message parsing (13 files) - handles tags, prefixes, ISUPPORT, WHOX, etc.
- **protocol/**: IRCv3 capability handlers (31 files) - SASL, batch, chathistory, typing, etc.
- **commands/**: IRC command builders (19 files) - registration, channel, message, monitor, etc.
- **state/**: Connection state machine (disconnected -> connecting -> registering -> connected)

### Feature Modules (`lib/features/`)

Each feature is self-contained with `providers/`, `screens/`, `widgets/`, `models/`, `services/`:
- **auth/**: SASL authentication flow
- **connection/**: Server connection management
- **channels/**: Channel list and management
- **chat/**: Message display and sending
- **users/**: User list and profiles
- **settings/**: App configuration

### UI System (`lib/layouts/`, `lib/theme/`)

- Adaptive layouts with responsive breakpoints
- Desktop: 3-column layout (channels, chat, users)
- Mobile: Optimized single-column with navigation

## State Management

Uses **flutter_riverpod** with:
- `Notifier` providers for mutable state (ConnectionNotifier, AuthNotifier)
- Generated providers via `riverpod_generator` for type safety
- Providers in each feature's `providers/` directory

## Code Generation

This project uses build_runner with:
- **freezed**: Immutable data models (`.freezed.dart`)
- **json_serializable**: JSON serialization (`.g.dart`)
- **riverpod_generator**: Type-safe providers (`.g.dart`)

Always run `flutter pub run build_runner build` after modifying annotated classes.

## Key Files

- `lib/main.dart`: Application entry point
- `lib/core/irc/protocol/protocol.dart`: Main IRC protocol orchestrator
- `lib/core/irc/state/connection_state_machine.dart`: Connection lifecycle
- `lib/core/constants/irc_numerics.dart`: IRC numeric reply codes
- `lib/routing/`: go_router navigation setup

## IRCv3 Capabilities Implemented

Core: CAP 302, cap-notify, SASL, message-tags, msgid, server-time, echo-message, labeled-response, standard-replies, multi-prefix, UTF8ONLY

Presence: away-notify, account-notify, account-tag, chghost, setname, extended-join, invite-notify, MONITOR, WHOX

Batch & History: batch, multiline, chathistory, read-marker

Interactive: +typing, reply, channel-context

Security: STS (Strict Transport Security)

## Requirements

- Flutter 3.38+
- Dart 3.10+

## Commit, Push policies
After finishing a feature and user tells you it respect critera acceptance, always:
1. Update CLAUDE.md
2. Commit
3. Push
4. Close github related issue if any

When creating a tag to publish a new version, always:
1. update frontend/package.json with new version
2. update claude-proxy-sdk/package.json with new version

/// Represents a user's channel mode prefix (e.g., @, +, %).
///
/// Standard IRC prefixes (in order of precedence):
/// - ~ (owner)
/// - & (admin/protected)
/// - @ (operator)
/// - % (halfop)
/// - + (voice)
class UserPrefix implements Comparable<UserPrefix> {
  /// The prefix character (e.g., '@', '+').
  final String symbol;

  /// The mode character (e.g., 'o' for op, 'v' for voice).
  final String mode;

  /// Precedence level (lower = higher rank).
  final int precedence;

  const UserPrefix({
    required this.symbol,
    required this.mode,
    required this.precedence,
  });

  /// Owner prefix (~q).
  static const owner = UserPrefix(symbol: '~', mode: 'q', precedence: 0);

  /// Admin/protected prefix (&a).
  static const admin = UserPrefix(symbol: '&', mode: 'a', precedence: 1);

  /// Operator prefix (@o).
  static const op = UserPrefix(symbol: '@', mode: 'o', precedence: 2);

  /// Half-operator prefix (%h).
  static const halfop = UserPrefix(symbol: '%', mode: 'h', precedence: 3);

  /// Voice prefix (+v).
  static const voice = UserPrefix(symbol: '+', mode: 'v', precedence: 4);

  /// All standard prefixes in order of precedence.
  static const standardPrefixes = [owner, admin, op, halfop, voice];

  /// Maps prefix symbols to UserPrefix objects.
  static const _symbolMap = {
    '~': owner,
    '&': admin,
    '@': op,
    '%': halfop,
    '+': voice,
  };

  /// Maps mode characters to UserPrefix objects.
  static const _modeMap = {
    'q': owner,
    'a': admin,
    'o': op,
    'h': halfop,
    'v': voice,
  };

  /// Gets a prefix by its symbol.
  static UserPrefix? fromSymbol(String symbol) => _symbolMap[symbol];

  /// Gets a prefix by its mode character.
  static UserPrefix? fromMode(String mode) => _modeMap[mode];

  @override
  int compareTo(UserPrefix other) => precedence.compareTo(other.precedence);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPrefix &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol;

  @override
  int get hashCode => symbol.hashCode;

  @override
  String toString() => symbol;
}

/// A user in a channel with their mode prefixes.
class PrefixedUser {
  /// The user's nickname.
  final String nick;

  /// All mode prefixes for this user (may be empty).
  ///
  /// With multi-prefix enabled, this contains all user modes.
  /// Without multi-prefix, this contains only the highest mode.
  final List<UserPrefix> prefixes;

  const PrefixedUser({
    required this.nick,
    this.prefixes = const [],
  });

  /// Whether the user has any prefixes.
  bool get hasPrefixes => prefixes.isNotEmpty;

  /// The highest (most privileged) prefix, or null if no prefixes.
  UserPrefix? get highestPrefix => prefixes.isEmpty ? null : prefixes.first;

  /// The prefix string (e.g., "@+" for op+voice).
  String get prefixString => prefixes.map((p) => p.symbol).join();

  /// The full display name with prefixes (e.g., "@+nick").
  String get displayName => '$prefixString$nick';

  /// Whether the user is an operator (or higher).
  bool get isOp => prefixes.any(
        (p) => p.precedence <= UserPrefix.op.precedence,
      );

  /// Whether the user has voice (or higher).
  bool get hasVoice => prefixes.any(
        (p) => p.precedence <= UserPrefix.voice.precedence,
      );

  /// Whether the user is an owner.
  bool get isOwner => prefixes.contains(UserPrefix.owner);

  /// Whether the user is an admin.
  bool get isAdmin => prefixes.contains(UserPrefix.admin);

  /// Whether the user is a half-operator.
  bool get isHalfOp => prefixes.contains(UserPrefix.halfop);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrefixedUser &&
          runtimeType == other.runtimeType &&
          nick == other.nick &&
          _listEquals(prefixes, other.prefixes);

  @override
  int get hashCode => nick.hashCode ^ prefixes.hashCode;

  @override
  String toString() => 'PrefixedUser($displayName)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Parser for user prefixes in NAMES and WHO replies.
///
/// Handles both single-prefix and multi-prefix modes.
///
/// See: https://ircv3.net/specs/extensions/multi-prefix
abstract class UserPrefixParser {
  /// Standard prefix characters.
  static const prefixChars = {'~', '&', '@', '%', '+'};

  /// Parses a prefixed nick string into a PrefixedUser.
  ///
  /// Examples:
  /// - "@nick" -> PrefixedUser(nick: "nick", prefixes: [op])
  /// - "@+nick" -> PrefixedUser(nick: "nick", prefixes: [op, voice])
  /// - "nick" -> PrefixedUser(nick: "nick", prefixes: [])
  static PrefixedUser parse(String prefixedNick) {
    if (prefixedNick.isEmpty) {
      return const PrefixedUser(nick: '');
    }

    final prefixes = <UserPrefix>[];
    var index = 0;

    // Extract all leading prefix characters
    while (index < prefixedNick.length &&
        prefixChars.contains(prefixedNick[index])) {
      final prefix = UserPrefix.fromSymbol(prefixedNick[index]);
      if (prefix != null) {
        prefixes.add(prefix);
      }
      index++;
    }

    // Sort prefixes by precedence (highest first)
    prefixes.sort();

    // Remaining string is the nick
    final nick = prefixedNick.substring(index);

    return PrefixedUser(nick: nick, prefixes: prefixes);
  }

  /// Parses a NAMES reply (RPL_NAMREPLY, 353) trailing parameter.
  ///
  /// Format: `nick1 @nick2 +nick3 @+nick4`
  static List<PrefixedUser> parseNamesReply(String names) {
    if (names.isEmpty) return [];

    return names.split(' ').where((n) => n.isNotEmpty).map(parse).toList();
  }

  /// Serializes a PrefixedUser back to string format.
  static String serialize(PrefixedUser user) => user.displayName;

  /// Checks if a character is a prefix character.
  static bool isPrefixChar(String char) =>
      char.length == 1 && prefixChars.contains(char);
}

/// ISUPPORT PREFIX parsing.
///
/// ISUPPORT sends prefix configuration as: PREFIX=(modes)prefixes
/// Example: PREFIX=(qaohv)~&@%+
abstract class PrefixConfig {
  /// Default IRC prefix configuration.
  static const defaultConfig = '(ov)@+';

  /// Parses PREFIX from ISUPPORT.
  ///
  /// Format: `(modes)prefixes`
  /// Returns map of mode char -> prefix symbol.
  static Map<String, String> parseIsupport(String prefix) {
    // Format: (modes)prefixes
    if (!prefix.startsWith('(')) {
      return {};
    }

    final closeIndex = prefix.indexOf(')');
    if (closeIndex == -1) {
      return {};
    }

    final modes = prefix.substring(1, closeIndex);
    final symbols = prefix.substring(closeIndex + 1);

    if (modes.length != symbols.length) {
      return {};
    }

    final result = <String, String>{};
    for (var i = 0; i < modes.length; i++) {
      result[modes[i]] = symbols[i];
    }

    return result;
  }

  /// Creates UserPrefix objects from ISUPPORT PREFIX.
  static List<UserPrefix> fromIsupport(String prefix) {
    final config = parseIsupport(prefix);
    final result = <UserPrefix>[];

    var precedence = 0;
    for (final entry in config.entries) {
      result.add(UserPrefix(
        mode: entry.key,
        symbol: entry.value,
        precedence: precedence++,
      ));
    }

    return result;
  }
}

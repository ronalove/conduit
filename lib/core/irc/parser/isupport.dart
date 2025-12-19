import 'user_prefix.dart';

/// Parsed ISUPPORT (005) configuration from the server.
///
/// ISUPPORT provides server capability information in the format:
/// `KEY` (boolean) or `KEY=value` (with value).
///
/// Common tokens:
/// - NETWORK=name - Network name
/// - CHANTYPES=#& - Valid channel prefixes
/// - PREFIX=(ov)@+ - Channel mode prefixes
/// - CHANMODES=a,b,c,d - Channel modes by type
/// - NICKLEN=32 - Maximum nick length
/// - CHANNELLEN=64 - Maximum channel name length
/// - UTF8ONLY - Server enforces UTF-8
///
/// See: https://modern.ircdocs.horse/#rplisupport-005
/// See: https://ircv3.net/specs/extensions/utf8-only
class Isupport {
  final Map<String, String?> _tokens;

  Isupport._(this._tokens);

  /// Creates an empty ISUPPORT configuration.
  factory Isupport.empty() => Isupport._({});

  /// Creates ISUPPORT from a token map.
  factory Isupport.fromTokens(Map<String, String?> tokens) =>
      Isupport._(Map.from(tokens));

  /// All tokens in this ISUPPORT.
  Map<String, String?> get tokens => Map.unmodifiable(_tokens);

  /// Whether the server enforces UTF-8 only.
  ///
  /// When true, the server will only accept UTF-8 encoded messages.
  /// Conduit already uses UTF-8 by default.
  bool get utf8Only => hasToken('UTF8ONLY');

  /// The network name (e.g., "Libera.Chat").
  String? get network => getValue('NETWORK');

  /// Valid channel type prefixes (e.g., "#&").
  String get chanTypes => getValue('CHANTYPES') ?? '#';

  /// Maximum nick length.
  int get nickLen => getIntValue('NICKLEN') ?? 9;

  /// Maximum channel name length.
  int get channelLen => getIntValue('CHANNELLEN') ?? 200;

  /// Maximum topic length.
  int? get topicLen => getIntValue('TOPICLEN');

  /// Maximum kick message length.
  int? get kickLen => getIntValue('KICKLEN');

  /// Maximum away message length.
  int? get awayLen => getIntValue('AWAYLEN');

  /// Maximum number of channels a user can join.
  int? get maxChannels => getIntValue('CHANLIMIT')?.abs() ??
      getIntValue('MAXCHANNELS');

  /// Maximum targets for PRIVMSG/NOTICE.
  int get maxTargets => getIntValue('MAXTARGETS') ?? 4;

  /// Case mapping used by server (ascii, rfc1459, strict-rfc1459).
  String get caseMapping => getValue('CASEMAPPING') ?? 'rfc1459';

  /// Channel modes organized by type.
  ///
  /// Returns a map with keys 'A', 'B', 'C', 'D' for mode types:
  /// - A: List modes (e.g., ban list)
  /// - B: Modes with parameter always
  /// - C: Modes with parameter on set only
  /// - D: Modes without parameter
  Map<String, String> get chanModes {
    final value = getValue('CHANMODES');
    if (value == null) return {};

    final parts = value.split(',');
    final result = <String, String>{};

    if (parts.isNotEmpty) result['A'] = parts[0];
    if (parts.length > 1) result['B'] = parts[1];
    if (parts.length > 2) result['C'] = parts[2];
    if (parts.length > 3) result['D'] = parts[3];

    return result;
  }

  /// Prefix configuration for channel modes.
  ///
  /// Returns parsed UserPrefix objects from PREFIX token.
  List<UserPrefix> get prefixes {
    final value = getValue('PREFIX');
    if (value == null) return UserPrefix.standardPrefixes;
    return PrefixConfig.fromIsupport(value);
  }

  /// Raw PREFIX value.
  String? get prefixRaw => getValue('PREFIX');

  /// Whether a specific token exists.
  bool hasToken(String token) => _tokens.containsKey(token.toUpperCase());

  /// Gets the value for a token (null if boolean token or not present).
  String? getValue(String token) => _tokens[token.toUpperCase()];

  /// Gets an integer value for a token.
  int? getIntValue(String token) {
    final value = getValue(token);
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Creates a new ISUPPORT with additional tokens merged.
  Isupport merge(Map<String, String?> additionalTokens) {
    return Isupport._({
      ..._tokens,
      ...additionalTokens.map((k, v) => MapEntry(k.toUpperCase(), v)),
    });
  }

  /// Creates a new ISUPPORT with a token removed.
  Isupport without(String token) {
    final newTokens = Map<String, String?>.from(_tokens);
    newTokens.remove(token.toUpperCase());
    return Isupport._(newTokens);
  }

  @override
  String toString() => 'Isupport($_tokens)';
}

/// Parser for ISUPPORT (005) numeric responses.
abstract class IsupportParser {
  /// Parses ISUPPORT tokens from a 005 numeric params list.
  ///
  /// Format: `<nick> <token1> [token2]... :are supported by this server`
  /// Tokens can be `KEY` (boolean) or `KEY=value`.
  /// Tokens starting with `-` indicate removal.
  static Map<String, String?> parse(List<String> params) {
    if (params.length < 2) return {};

    final result = <String, String?>{};

    // Skip first param (nick) and last param (trailing "are supported...")
    for (var i = 1; i < params.length - 1; i++) {
      final token = params[i];
      final parsed = parseToken(token);
      if (parsed != null) {
        result[parsed.$1] = parsed.$2;
      }
    }

    return result;
  }

  /// Parses a single ISUPPORT token.
  ///
  /// Returns (key, value) tuple. Value is null for boolean tokens.
  /// Returns null for invalid tokens or removal tokens (-KEY).
  static (String, String?)? parseToken(String token) {
    if (token.isEmpty) return null;

    // Removal token
    if (token.startsWith('-')) {
      return null; // Caller should handle removal separately
    }

    final equalsIndex = token.indexOf('=');
    if (equalsIndex == -1) {
      // Boolean token
      return (token.toUpperCase(), null);
    }

    final key = token.substring(0, equalsIndex).toUpperCase();
    final value = token.substring(equalsIndex + 1);

    return (key, value);
  }

  /// Checks if a token indicates removal.
  static bool isRemovalToken(String token) => token.startsWith('-');

  /// Gets the key from a removal token.
  static String? getRemovalKey(String token) {
    if (!isRemovalToken(token)) return null;
    final key = token.substring(1);
    final equalsIndex = key.indexOf('=');
    return (equalsIndex == -1 ? key : key.substring(0, equalsIndex))
        .toUpperCase();
  }

  /// Creates an Isupport instance from 005 params.
  static Isupport fromParams(List<String> params) {
    return Isupport.fromTokens(parse(params));
  }
}

/// Common ISUPPORT token names.
abstract class IsupportTokens {
  static const String utf8Only = 'UTF8ONLY';
  static const String network = 'NETWORK';
  static const String chanTypes = 'CHANTYPES';
  static const String prefix = 'PREFIX';
  static const String chanModes = 'CHANMODES';
  static const String nickLen = 'NICKLEN';
  static const String channelLen = 'CHANNELLEN';
  static const String topicLen = 'TOPICLEN';
  static const String kickLen = 'KICKLEN';
  static const String awayLen = 'AWAYLEN';
  static const String maxChannels = 'MAXCHANNELS';
  static const String chanLimit = 'CHANLIMIT';
  static const String maxTargets = 'MAXTARGETS';
  static const String caseMapping = 'CASEMAPPING';
  static const String modes = 'MODES';
  static const String statusMsg = 'STATUSMSG';
  static const String excepts = 'EXCEPTS';
  static const String invex = 'INVEX';
  static const String monitor = 'MONITOR';
  static const String whox = 'WHOX';
}

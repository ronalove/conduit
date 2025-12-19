/// IRCv3 message-tags extension support.
///
/// Provides utilities for working with standard IRCv3 tags:
/// - `time` - Server timestamp (server-time)
/// - `msgid` - Unique message ID
/// - `account` - Sender's account name
/// - `batch` - Batch reference
/// - `label` - Request/response correlation
/// - Client-only tags (+prefix)
/// - Vendor-prefixed tags
///
/// See: https://ircv3.net/specs/extensions/message-tags
library;

/// Standard IRCv3 tag names.
abstract class IrcTags {
  /// Server timestamp (ISO 8601 format).
  static const String time = 'time';

  /// Unique message identifier.
  static const String msgid = 'msgid';

  /// Sender's account name (empty string if not logged in).
  static const String account = 'account';

  /// Batch reference identifier.
  static const String batch = 'batch';

  /// Request/response correlation label.
  static const String label = 'label';

  /// Reply target message ID.
  static const String replyTo = '+draft/reply';

  /// Typing indicator.
  static const String typing = '+typing';

  /// React emoji.
  static const String react = '+draft/react';

  /// Channel context for private messages.
  static const String channelContext = '+draft/channel-context';
}

/// Utilities for working with IRCv3 message tags.
abstract class MessageTags {
  /// Checks if a tag name is a client-only tag (starts with +).
  static bool isClientOnly(String tagName) => tagName.startsWith('+');

  /// Checks if a tag name is vendor-prefixed.
  ///
  /// Vendor tags contain a domain prefix like `example.com/tag`.
  static bool isVendorPrefixed(String tagName) {
    // Client-only tags can also be vendor-prefixed: +example.com/tag
    final name = tagName.startsWith('+') ? tagName.substring(1) : tagName;
    return name.contains('/') && name.contains('.');
  }

  /// Extracts the vendor domain from a vendor-prefixed tag.
  ///
  /// Returns null if not a vendor-prefixed tag.
  /// Example: `example.com/foo` -> `example.com`
  static String? getVendorDomain(String tagName) {
    final name = tagName.startsWith('+') ? tagName.substring(1) : tagName;
    final slashIndex = name.indexOf('/');
    if (slashIndex == -1) return null;

    final domain = name.substring(0, slashIndex);
    if (!domain.contains('.')) return null;

    return domain;
  }

  /// Extracts the tag base name without vendor prefix.
  ///
  /// Example: `example.com/foo` -> `foo`
  /// Example: `+draft/reply` -> `reply`
  static String getBaseName(String tagName) {
    final name = tagName.startsWith('+') ? tagName.substring(1) : tagName;
    final slashIndex = name.lastIndexOf('/');
    if (slashIndex == -1) return name;
    return name.substring(slashIndex + 1);
  }

  /// Extracts the server timestamp from tags.
  ///
  /// Returns null if no time tag or invalid format.
  static DateTime? getTime(Map<String, String?> tags) {
    final timeValue = tags[IrcTags.time];
    if (timeValue == null) return null;
    return DateTime.tryParse(timeValue);
  }

  /// Extracts the message ID from tags.
  static String? getMsgId(Map<String, String?> tags) => tags[IrcTags.msgid];

  /// Extracts the account name from tags.
  ///
  /// Returns empty string if account tag exists but user not logged in.
  /// Returns null if no account tag.
  static String? getAccount(Map<String, String?> tags) => tags[IrcTags.account];

  /// Extracts the batch reference from tags.
  static String? getBatch(Map<String, String?> tags) => tags[IrcTags.batch];

  /// Extracts the label from tags.
  static String? getLabel(Map<String, String?> tags) => tags[IrcTags.label];

  /// Extracts all client-only tags from a tag map.
  ///
  /// Returns a new map containing only client-only tags (+ prefix removed).
  static Map<String, String?> getClientOnlyTags(Map<String, String?> tags) {
    final result = <String, String?>{};
    for (final entry in tags.entries) {
      if (isClientOnly(entry.key)) {
        result[entry.key.substring(1)] = entry.value;
      }
    }
    return result;
  }

  /// Extracts all server tags (non-client-only) from a tag map.
  static Map<String, String?> getServerTags(Map<String, String?> tags) {
    final result = <String, String?>{};
    for (final entry in tags.entries) {
      if (!isClientOnly(entry.key)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  /// Creates a tag map with a time tag from a DateTime.
  ///
  /// Formats as ISO 8601 with milliseconds.
  static Map<String, String?> withTime(
    Map<String, String?> tags,
    DateTime time,
  ) {
    return {
      ...tags,
      IrcTags.time: time.toUtc().toIso8601String(),
    };
  }

  /// Creates a tag map with a msgid tag.
  static Map<String, String?> withMsgId(
    Map<String, String?> tags,
    String msgId,
  ) {
    return {
      ...tags,
      IrcTags.msgid: msgId,
    };
  }

  /// Creates a tag map with a label tag.
  static Map<String, String?> withLabel(
    Map<String, String?> tags,
    String label,
  ) {
    return {
      ...tags,
      IrcTags.label: label,
    };
  }

  /// Creates a tag map with a batch reference.
  static Map<String, String?> withBatch(
    Map<String, String?> tags,
    String batchRef,
  ) {
    return {
      ...tags,
      IrcTags.batch: batchRef,
    };
  }

  /// Creates a tag map for a reply to another message.
  static Map<String, String?> withReplyTo(
    Map<String, String?> tags,
    String targetMsgId,
  ) {
    return {
      ...tags,
      IrcTags.replyTo: targetMsgId,
    };
  }

  /// Creates a tag map with an account tag.
  ///
  /// Use empty string to indicate user is not logged in.
  static Map<String, String?> withAccount(
    Map<String, String?> tags,
    String account,
  ) {
    return {
      ...tags,
      IrcTags.account: account,
    };
  }

  /// Checks if the sender has an account (is logged in).
  ///
  /// Returns true if account tag exists and is not empty.
  static bool hasAccount(Map<String, String?> tags) {
    final account = tags[IrcTags.account];
    return account != null && account.isNotEmpty;
  }
}

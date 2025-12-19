import 'irc_message.dart';
import 'message_tags.dart';

/// Extensions on [IrcMessage] for working with IRCv3 tags.
extension IrcMessageTagsExtension on IrcMessage {
  /// Gets the server timestamp from the message tags.
  ///
  /// Returns null if no time tag present or invalid format.
  DateTime? get serverTime => MessageTags.getTime(tags);

  /// Gets the message ID from the message tags.
  String? get msgId => MessageTags.getMsgId(tags);

  /// Gets the sender's account name from the message tags.
  ///
  /// Returns empty string if sender not logged in.
  /// Returns null if account tag not present.
  String? get senderAccount => MessageTags.getAccount(tags);

  /// Gets the batch reference from the message tags.
  String? get batchRef => MessageTags.getBatch(tags);

  /// Gets the label for request/response correlation.
  String? get responseLabel => MessageTags.getLabel(tags);

  /// Whether this message has a server timestamp.
  bool get hasServerTime => tags.containsKey(IrcTags.time);

  /// Whether this message has a message ID.
  bool get hasMsgId => tags.containsKey(IrcTags.msgid);

  /// Whether this message is part of a batch.
  bool get isPartOfBatch => tags.containsKey(IrcTags.batch);

  /// Whether this message is a labeled response.
  bool get isLabeledResponse => tags.containsKey(IrcTags.label);

  /// Gets the reply target message ID if this is a reply.
  String? get replyTargetMsgId => tags[IrcTags.replyTo];

  /// Whether this message is a reply to another message.
  bool get isReply => tags.containsKey(IrcTags.replyTo);

  /// Creates a copy of this message with additional tags.
  IrcMessage withTags(Map<String, String?> additionalTags) {
    return IrcMessage(
      tags: {...tags, ...additionalTags},
      source: source,
      command: command,
      params: params,
    );
  }

  /// Creates a copy of this message with a label tag.
  IrcMessage withLabel(String label) {
    return withTags({IrcTags.label: label});
  }

  /// Creates a copy of this message with a reply-to tag.
  IrcMessage asReplyTo(String targetMsgId) {
    return withTags({IrcTags.replyTo: targetMsgId});
  }
}

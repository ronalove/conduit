/// Chat message model for UI display.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.type = MessageType.normal,
    this.isOwn = false,
    this.replyTo,
    this.isAction = false,
  });

  /// Unique message ID.
  final String id;

  /// Sender nickname.
  final String sender;

  /// Message content.
  final String content;

  /// Message timestamp.
  final DateTime timestamp;

  /// Type of message.
  final MessageType type;

  /// Whether this message was sent by the current user.
  final bool isOwn;

  /// ID of message this is replying to.
  final String? replyTo;

  /// Whether this is a /me action.
  final bool isAction;
}

/// Type of IRC message.
enum MessageType {
  /// Normal user message.
  normal,

  /// Server notice.
  notice,

  /// Join/part/quit event.
  event,

  /// Error message.
  error,
}

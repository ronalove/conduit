import '../../../core/database/tables.dart' show MessageStatus;

export '../../../core/database/tables.dart' show MessageStatus;

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
    this.status = MessageStatus.confirmed,
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

  /// Message send status (pending, confirmed, failed).
  final MessageStatus status;

  /// Create a copy with updated fields.
  ChatMessage copyWith({
    String? id,
    String? sender,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    bool? isOwn,
    String? replyTo,
    bool? isAction,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isOwn: isOwn ?? this.isOwn,
      replyTo: replyTo ?? this.replyTo,
      isAction: isAction ?? this.isAction,
      status: status ?? this.status,
    );
  }
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

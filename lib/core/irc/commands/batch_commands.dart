import '../parser/irc_message.dart';
import 'irc_command.dart';

/// BATCH command for grouping related messages.
///
/// Used to start and end batches of related messages.
///
/// Start batch: `BATCH +<ref> <type> [params...]`
/// End batch: `BATCH -<ref>`
///
/// See: https://ircv3.net/specs/extensions/batch
class BatchCommand extends IrcCommand {
  final String reference;
  final BatchAction action;
  final String? type;
  final List<String> params;

  const BatchCommand._({
    required this.reference,
    required this.action,
    this.type,
    this.params = const [],
  });

  /// Creates a batch start command.
  ///
  /// [reference] is a unique identifier for this batch.
  /// [type] is the batch type (e.g., 'chathistory', 'netjoin').
  /// [params] are additional type-specific parameters.
  factory BatchCommand.start(
    String reference,
    String type, [
    List<String> params = const [],
  ]) {
    return BatchCommand._(
      reference: reference,
      action: BatchAction.start,
      type: type,
      params: params,
    );
  }

  /// Creates a batch end command.
  factory BatchCommand.end(String reference) {
    return BatchCommand._(
      reference: reference,
      action: BatchAction.end,
    );
  }

  @override
  IrcMessage toMessage() {
    final messageParams = <String>[];

    switch (action) {
      case BatchAction.start:
        messageParams.add('+$reference');
        if (type != null) {
          messageParams.add(type!);
        }
        messageParams.addAll(params);
      case BatchAction.end:
        messageParams.add('-$reference');
    }

    return IrcMessage(
      command: 'BATCH',
      params: messageParams,
    );
  }
}

/// Action for a BATCH command.
enum BatchAction {
  /// Start a new batch (+reference).
  start,

  /// End an existing batch (-reference).
  end,
}

/// Standard batch types defined in IRCv3.
abstract class BatchTypes {
  /// Network join batch - users joining after netsplit recovery.
  static const String netjoin = 'netjoin';

  /// Network split batch - users lost due to netsplit.
  static const String netsplit = 'netsplit';

  /// Chat history batch - historical messages.
  static const String chathistory = 'chathistory';

  /// Labeled response batch - response to labeled request.
  static const String labeledResponse = 'labeled-response';

  /// Multiline message batch.
  static const String multiline = 'draft/multiline';
}

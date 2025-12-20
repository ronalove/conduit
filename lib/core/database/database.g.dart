// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isOwnMeta = const VerificationMeta('isOwn');
  @override
  late final GeneratedColumn<bool> isOwn = GeneratedColumn<bool>(
    'is_own',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_own" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isActionMeta = const VerificationMeta(
    'isAction',
  );
  @override
  late final GeneratedColumn<bool> isAction = GeneratedColumn<bool>(
    'is_action',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_action" IN (0, 1))',
    ),
  );
  static const VerificationMeta _replyToMeta = const VerificationMeta(
    'replyTo',
  );
  @override
  late final GeneratedColumn<String> replyTo = GeneratedColumn<String>(
    'reply_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    channel,
    sender,
    content,
    timestamp,
    type,
    isOwn,
    isAction,
    replyTo,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    } else if (isInserting) {
      context.missing(_channelMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('is_own')) {
      context.handle(
        _isOwnMeta,
        isOwn.isAcceptableOrUnknown(data['is_own']!, _isOwnMeta),
      );
    } else if (isInserting) {
      context.missing(_isOwnMeta);
    }
    if (data.containsKey('is_action')) {
      context.handle(
        _isActionMeta,
        isAction.isAcceptableOrUnknown(data['is_action']!, _isActionMeta),
      );
    } else if (isInserting) {
      context.missing(_isActionMeta);
    }
    if (data.containsKey('reply_to')) {
      context.handle(
        _replyToMeta,
        replyTo.isAcceptableOrUnknown(data['reply_to']!, _replyToMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      isOwn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_own'],
      )!,
      isAction: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_action'],
      )!,
      replyTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  /// Unique message ID (msgid from IRC or UUID for pending).
  final String id;

  /// Channel name (lowercase for indexing).
  final String channel;

  /// Sender nickname.
  final String sender;

  /// Message content.
  final String content;

  /// Unix timestamp in milliseconds.
  final int timestamp;

  /// Message type index (0=normal, 1=notice, 2=event, 3=error).
  final int type;

  /// Whether message is from current user.
  final bool isOwn;

  /// Whether this is a /me action.
  final bool isAction;

  /// Optional: msgid of replied message.
  final String? replyTo;

  /// Message status (0=pending, 1=confirmed, 2=failed).
  final int status;
  const Message({
    required this.id,
    required this.channel,
    required this.sender,
    required this.content,
    required this.timestamp,
    required this.type,
    required this.isOwn,
    required this.isAction,
    this.replyTo,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['channel'] = Variable<String>(channel);
    map['sender'] = Variable<String>(sender);
    map['content'] = Variable<String>(content);
    map['timestamp'] = Variable<int>(timestamp);
    map['type'] = Variable<int>(type);
    map['is_own'] = Variable<bool>(isOwn);
    map['is_action'] = Variable<bool>(isAction);
    if (!nullToAbsent || replyTo != null) {
      map['reply_to'] = Variable<String>(replyTo);
    }
    map['status'] = Variable<int>(status);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      channel: Value(channel),
      sender: Value(sender),
      content: Value(content),
      timestamp: Value(timestamp),
      type: Value(type),
      isOwn: Value(isOwn),
      isAction: Value(isAction),
      replyTo: replyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(replyTo),
      status: Value(status),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<String>(json['id']),
      channel: serializer.fromJson<String>(json['channel']),
      sender: serializer.fromJson<String>(json['sender']),
      content: serializer.fromJson<String>(json['content']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      type: serializer.fromJson<int>(json['type']),
      isOwn: serializer.fromJson<bool>(json['isOwn']),
      isAction: serializer.fromJson<bool>(json['isAction']),
      replyTo: serializer.fromJson<String?>(json['replyTo']),
      status: serializer.fromJson<int>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'channel': serializer.toJson<String>(channel),
      'sender': serializer.toJson<String>(sender),
      'content': serializer.toJson<String>(content),
      'timestamp': serializer.toJson<int>(timestamp),
      'type': serializer.toJson<int>(type),
      'isOwn': serializer.toJson<bool>(isOwn),
      'isAction': serializer.toJson<bool>(isAction),
      'replyTo': serializer.toJson<String?>(replyTo),
      'status': serializer.toJson<int>(status),
    };
  }

  Message copyWith({
    String? id,
    String? channel,
    String? sender,
    String? content,
    int? timestamp,
    int? type,
    bool? isOwn,
    bool? isAction,
    Value<String?> replyTo = const Value.absent(),
    int? status,
  }) => Message(
    id: id ?? this.id,
    channel: channel ?? this.channel,
    sender: sender ?? this.sender,
    content: content ?? this.content,
    timestamp: timestamp ?? this.timestamp,
    type: type ?? this.type,
    isOwn: isOwn ?? this.isOwn,
    isAction: isAction ?? this.isAction,
    replyTo: replyTo.present ? replyTo.value : this.replyTo,
    status: status ?? this.status,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      channel: data.channel.present ? data.channel.value : this.channel,
      sender: data.sender.present ? data.sender.value : this.sender,
      content: data.content.present ? data.content.value : this.content,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      type: data.type.present ? data.type.value : this.type,
      isOwn: data.isOwn.present ? data.isOwn.value : this.isOwn,
      isAction: data.isAction.present ? data.isAction.value : this.isAction,
      replyTo: data.replyTo.present ? data.replyTo.value : this.replyTo,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('channel: $channel, ')
          ..write('sender: $sender, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('type: $type, ')
          ..write('isOwn: $isOwn, ')
          ..write('isAction: $isAction, ')
          ..write('replyTo: $replyTo, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    channel,
    sender,
    content,
    timestamp,
    type,
    isOwn,
    isAction,
    replyTo,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.channel == this.channel &&
          other.sender == this.sender &&
          other.content == this.content &&
          other.timestamp == this.timestamp &&
          other.type == this.type &&
          other.isOwn == this.isOwn &&
          other.isAction == this.isAction &&
          other.replyTo == this.replyTo &&
          other.status == this.status);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> id;
  final Value<String> channel;
  final Value<String> sender;
  final Value<String> content;
  final Value<int> timestamp;
  final Value<int> type;
  final Value<bool> isOwn;
  final Value<bool> isAction;
  final Value<String?> replyTo;
  final Value<int> status;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.channel = const Value.absent(),
    this.sender = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.type = const Value.absent(),
    this.isOwn = const Value.absent(),
    this.isAction = const Value.absent(),
    this.replyTo = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String channel,
    required String sender,
    required String content,
    required int timestamp,
    required int type,
    required bool isOwn,
    required bool isAction,
    this.replyTo = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       channel = Value(channel),
       sender = Value(sender),
       content = Value(content),
       timestamp = Value(timestamp),
       type = Value(type),
       isOwn = Value(isOwn),
       isAction = Value(isAction);
  static Insertable<Message> custom({
    Expression<String>? id,
    Expression<String>? channel,
    Expression<String>? sender,
    Expression<String>? content,
    Expression<int>? timestamp,
    Expression<int>? type,
    Expression<bool>? isOwn,
    Expression<bool>? isAction,
    Expression<String>? replyTo,
    Expression<int>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channel != null) 'channel': channel,
      if (sender != null) 'sender': sender,
      if (content != null) 'content': content,
      if (timestamp != null) 'timestamp': timestamp,
      if (type != null) 'type': type,
      if (isOwn != null) 'is_own': isOwn,
      if (isAction != null) 'is_action': isAction,
      if (replyTo != null) 'reply_to': replyTo,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? channel,
    Value<String>? sender,
    Value<String>? content,
    Value<int>? timestamp,
    Value<int>? type,
    Value<bool>? isOwn,
    Value<bool>? isAction,
    Value<String?>? replyTo,
    Value<int>? status,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      channel: channel ?? this.channel,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isOwn: isOwn ?? this.isOwn,
      isAction: isAction ?? this.isAction,
      replyTo: replyTo ?? this.replyTo,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (isOwn.present) {
      map['is_own'] = Variable<bool>(isOwn.value);
    }
    if (isAction.present) {
      map['is_action'] = Variable<bool>(isAction.value);
    }
    if (replyTo.present) {
      map['reply_to'] = Variable<String>(replyTo.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('channel: $channel, ')
          ..write('sender: $sender, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('type: $type, ')
          ..write('isOwn: $isOwn, ')
          ..write('isAction: $isAction, ')
          ..write('replyTo: $replyTo, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChannelReadStatesTable extends ChannelReadStates
    with TableInfo<$ChannelReadStatesTable, ChannelReadState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelReadStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReadIdMeta = const VerificationMeta(
    'lastReadId',
  );
  @override
  late final GeneratedColumn<String> lastReadId = GeneratedColumn<String>(
    'last_read_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReadTimestampMeta = const VerificationMeta(
    'lastReadTimestamp',
  );
  @override
  late final GeneratedColumn<int> lastReadTimestamp = GeneratedColumn<int>(
    'last_read_timestamp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hasMentionMeta = const VerificationMeta(
    'hasMention',
  );
  @override
  late final GeneratedColumn<bool> hasMention = GeneratedColumn<bool>(
    'has_mention',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_mention" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    channel,
    lastReadId,
    lastReadTimestamp,
    unreadCount,
    hasMention,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channel_read_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelReadState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    } else if (isInserting) {
      context.missing(_channelMeta);
    }
    if (data.containsKey('last_read_id')) {
      context.handle(
        _lastReadIdMeta,
        lastReadId.isAcceptableOrUnknown(
          data['last_read_id']!,
          _lastReadIdMeta,
        ),
      );
    }
    if (data.containsKey('last_read_timestamp')) {
      context.handle(
        _lastReadTimestampMeta,
        lastReadTimestamp.isAcceptableOrUnknown(
          data['last_read_timestamp']!,
          _lastReadTimestampMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('has_mention')) {
      context.handle(
        _hasMentionMeta,
        hasMention.isAcceptableOrUnknown(data['has_mention']!, _hasMentionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {channel};
  @override
  ChannelReadState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelReadState(
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      lastReadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_read_id'],
      ),
      lastReadTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_read_timestamp'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      hasMention: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_mention'],
      )!,
    );
  }

  @override
  $ChannelReadStatesTable createAlias(String alias) {
    return $ChannelReadStatesTable(attachedDatabase, alias);
  }
}

class ChannelReadState extends DataClass
    implements Insertable<ChannelReadState> {
  /// Channel name (lowercase).
  final String channel;

  /// Last read message ID.
  final String? lastReadId;

  /// Last read timestamp for ordering.
  final int? lastReadTimestamp;

  /// Number of unread messages.
  final int unreadCount;

  /// Whether there's an unread mention.
  final bool hasMention;
  const ChannelReadState({
    required this.channel,
    this.lastReadId,
    this.lastReadTimestamp,
    required this.unreadCount,
    required this.hasMention,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['channel'] = Variable<String>(channel);
    if (!nullToAbsent || lastReadId != null) {
      map['last_read_id'] = Variable<String>(lastReadId);
    }
    if (!nullToAbsent || lastReadTimestamp != null) {
      map['last_read_timestamp'] = Variable<int>(lastReadTimestamp);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    map['has_mention'] = Variable<bool>(hasMention);
    return map;
  }

  ChannelReadStatesCompanion toCompanion(bool nullToAbsent) {
    return ChannelReadStatesCompanion(
      channel: Value(channel),
      lastReadId: lastReadId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadId),
      lastReadTimestamp: lastReadTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadTimestamp),
      unreadCount: Value(unreadCount),
      hasMention: Value(hasMention),
    );
  }

  factory ChannelReadState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelReadState(
      channel: serializer.fromJson<String>(json['channel']),
      lastReadId: serializer.fromJson<String?>(json['lastReadId']),
      lastReadTimestamp: serializer.fromJson<int?>(json['lastReadTimestamp']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      hasMention: serializer.fromJson<bool>(json['hasMention']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'channel': serializer.toJson<String>(channel),
      'lastReadId': serializer.toJson<String?>(lastReadId),
      'lastReadTimestamp': serializer.toJson<int?>(lastReadTimestamp),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'hasMention': serializer.toJson<bool>(hasMention),
    };
  }

  ChannelReadState copyWith({
    String? channel,
    Value<String?> lastReadId = const Value.absent(),
    Value<int?> lastReadTimestamp = const Value.absent(),
    int? unreadCount,
    bool? hasMention,
  }) => ChannelReadState(
    channel: channel ?? this.channel,
    lastReadId: lastReadId.present ? lastReadId.value : this.lastReadId,
    lastReadTimestamp: lastReadTimestamp.present
        ? lastReadTimestamp.value
        : this.lastReadTimestamp,
    unreadCount: unreadCount ?? this.unreadCount,
    hasMention: hasMention ?? this.hasMention,
  );
  ChannelReadState copyWithCompanion(ChannelReadStatesCompanion data) {
    return ChannelReadState(
      channel: data.channel.present ? data.channel.value : this.channel,
      lastReadId: data.lastReadId.present
          ? data.lastReadId.value
          : this.lastReadId,
      lastReadTimestamp: data.lastReadTimestamp.present
          ? data.lastReadTimestamp.value
          : this.lastReadTimestamp,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      hasMention: data.hasMention.present
          ? data.hasMention.value
          : this.hasMention,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelReadState(')
          ..write('channel: $channel, ')
          ..write('lastReadId: $lastReadId, ')
          ..write('lastReadTimestamp: $lastReadTimestamp, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('hasMention: $hasMention')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    channel,
    lastReadId,
    lastReadTimestamp,
    unreadCount,
    hasMention,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelReadState &&
          other.channel == this.channel &&
          other.lastReadId == this.lastReadId &&
          other.lastReadTimestamp == this.lastReadTimestamp &&
          other.unreadCount == this.unreadCount &&
          other.hasMention == this.hasMention);
}

class ChannelReadStatesCompanion extends UpdateCompanion<ChannelReadState> {
  final Value<String> channel;
  final Value<String?> lastReadId;
  final Value<int?> lastReadTimestamp;
  final Value<int> unreadCount;
  final Value<bool> hasMention;
  final Value<int> rowid;
  const ChannelReadStatesCompanion({
    this.channel = const Value.absent(),
    this.lastReadId = const Value.absent(),
    this.lastReadTimestamp = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.hasMention = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelReadStatesCompanion.insert({
    required String channel,
    this.lastReadId = const Value.absent(),
    this.lastReadTimestamp = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.hasMention = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : channel = Value(channel);
  static Insertable<ChannelReadState> custom({
    Expression<String>? channel,
    Expression<String>? lastReadId,
    Expression<int>? lastReadTimestamp,
    Expression<int>? unreadCount,
    Expression<bool>? hasMention,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (channel != null) 'channel': channel,
      if (lastReadId != null) 'last_read_id': lastReadId,
      if (lastReadTimestamp != null) 'last_read_timestamp': lastReadTimestamp,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (hasMention != null) 'has_mention': hasMention,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelReadStatesCompanion copyWith({
    Value<String>? channel,
    Value<String?>? lastReadId,
    Value<int?>? lastReadTimestamp,
    Value<int>? unreadCount,
    Value<bool>? hasMention,
    Value<int>? rowid,
  }) {
    return ChannelReadStatesCompanion(
      channel: channel ?? this.channel,
      lastReadId: lastReadId ?? this.lastReadId,
      lastReadTimestamp: lastReadTimestamp ?? this.lastReadTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMention: hasMention ?? this.hasMention,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (lastReadId.present) {
      map['last_read_id'] = Variable<String>(lastReadId.value);
    }
    if (lastReadTimestamp.present) {
      map['last_read_timestamp'] = Variable<int>(lastReadTimestamp.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (hasMention.present) {
      map['has_mention'] = Variable<bool>(hasMention.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelReadStatesCompanion(')
          ..write('channel: $channel, ')
          ..write('lastReadId: $lastReadId, ')
          ..write('lastReadTimestamp: $lastReadTimestamp, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('hasMention: $hasMention, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $ChannelReadStatesTable channelReadStates =
      $ChannelReadStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    messages,
    channelReadStates,
  ];
}

typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String id,
      required String channel,
      required String sender,
      required String content,
      required int timestamp,
      required int type,
      required bool isOwn,
      required bool isAction,
      Value<String?> replyTo,
      Value<int> status,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<String> channel,
      Value<String> sender,
      Value<String> content,
      Value<int> timestamp,
      Value<int> type,
      Value<bool> isOwn,
      Value<bool> isAction,
      Value<String?> replyTo,
      Value<int> status,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOwn => $composableBuilder(
    column: $table.isOwn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAction => $composableBuilder(
    column: $table.isAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyTo => $composableBuilder(
    column: $table.replyTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOwn => $composableBuilder(
    column: $table.isOwn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAction => $composableBuilder(
    column: $table.isAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyTo => $composableBuilder(
    column: $table.replyTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isOwn =>
      $composableBuilder(column: $table.isOwn, builder: (column) => column);

  GeneratedColumn<bool> get isAction =>
      $composableBuilder(column: $table.isAction, builder: (column) => column);

  GeneratedColumn<String> get replyTo =>
      $composableBuilder(column: $table.replyTo, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<bool> isOwn = const Value.absent(),
                Value<bool> isAction = const Value.absent(),
                Value<String?> replyTo = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                channel: channel,
                sender: sender,
                content: content,
                timestamp: timestamp,
                type: type,
                isOwn: isOwn,
                isAction: isAction,
                replyTo: replyTo,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String channel,
                required String sender,
                required String content,
                required int timestamp,
                required int type,
                required bool isOwn,
                required bool isAction,
                Value<String?> replyTo = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                channel: channel,
                sender: sender,
                content: content,
                timestamp: timestamp,
                type: type,
                isOwn: isOwn,
                isAction: isAction,
                replyTo: replyTo,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$ChannelReadStatesTableCreateCompanionBuilder =
    ChannelReadStatesCompanion Function({
      required String channel,
      Value<String?> lastReadId,
      Value<int?> lastReadTimestamp,
      Value<int> unreadCount,
      Value<bool> hasMention,
      Value<int> rowid,
    });
typedef $$ChannelReadStatesTableUpdateCompanionBuilder =
    ChannelReadStatesCompanion Function({
      Value<String> channel,
      Value<String?> lastReadId,
      Value<int?> lastReadTimestamp,
      Value<int> unreadCount,
      Value<bool> hasMention,
      Value<int> rowid,
    });

class $$ChannelReadStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelReadStatesTable> {
  $$ChannelReadStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReadId => $composableBuilder(
    column: $table.lastReadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReadTimestamp => $composableBuilder(
    column: $table.lastReadTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasMention => $composableBuilder(
    column: $table.hasMention,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChannelReadStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelReadStatesTable> {
  $$ChannelReadStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReadId => $composableBuilder(
    column: $table.lastReadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReadTimestamp => $composableBuilder(
    column: $table.lastReadTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasMention => $composableBuilder(
    column: $table.hasMention,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChannelReadStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelReadStatesTable> {
  $$ChannelReadStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<String> get lastReadId => $composableBuilder(
    column: $table.lastReadId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastReadTimestamp => $composableBuilder(
    column: $table.lastReadTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasMention => $composableBuilder(
    column: $table.hasMention,
    builder: (column) => column,
  );
}

class $$ChannelReadStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelReadStatesTable,
          ChannelReadState,
          $$ChannelReadStatesTableFilterComposer,
          $$ChannelReadStatesTableOrderingComposer,
          $$ChannelReadStatesTableAnnotationComposer,
          $$ChannelReadStatesTableCreateCompanionBuilder,
          $$ChannelReadStatesTableUpdateCompanionBuilder,
          (
            ChannelReadState,
            BaseReferences<
              _$AppDatabase,
              $ChannelReadStatesTable,
              ChannelReadState
            >,
          ),
          ChannelReadState,
          PrefetchHooks Function()
        > {
  $$ChannelReadStatesTableTableManager(
    _$AppDatabase db,
    $ChannelReadStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelReadStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelReadStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelReadStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> channel = const Value.absent(),
                Value<String?> lastReadId = const Value.absent(),
                Value<int?> lastReadTimestamp = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> hasMention = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelReadStatesCompanion(
                channel: channel,
                lastReadId: lastReadId,
                lastReadTimestamp: lastReadTimestamp,
                unreadCount: unreadCount,
                hasMention: hasMention,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String channel,
                Value<String?> lastReadId = const Value.absent(),
                Value<int?> lastReadTimestamp = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> hasMention = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelReadStatesCompanion.insert(
                channel: channel,
                lastReadId: lastReadId,
                lastReadTimestamp: lastReadTimestamp,
                unreadCount: unreadCount,
                hasMention: hasMention,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChannelReadStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelReadStatesTable,
      ChannelReadState,
      $$ChannelReadStatesTableFilterComposer,
      $$ChannelReadStatesTableOrderingComposer,
      $$ChannelReadStatesTableAnnotationComposer,
      $$ChannelReadStatesTableCreateCompanionBuilder,
      $$ChannelReadStatesTableUpdateCompanionBuilder,
      (
        ChannelReadState,
        BaseReferences<
          _$AppDatabase,
          $ChannelReadStatesTable,
          ChannelReadState
        >,
      ),
      ChannelReadState,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$ChannelReadStatesTableTableManager get channelReadStates =>
      $$ChannelReadStatesTableTableManager(_db, _db.channelReadStates);
}

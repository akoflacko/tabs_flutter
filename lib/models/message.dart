import 'package:uuid/uuid.dart';

/// {@template message}
/// Message model
/// {@endtemplate}
class Message {
  /// Message id
  final String id;

  /// Text of the message
  final String text;

  /// Creation date
  final DateTime createdAt;

  /// Tab id
  final String tabId;

  /// {@macro message}
  Message({
    String? id,
    required this.tabId,
    required this.text,
    required this.createdAt,
  }) : id = id ?? _uuid.v4();

  static final _uuid = const Uuid();

  @override
  String toString() =>
      'Message(id: $id, tabId: $tabId, text: $text, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tabId == other.tabId &&
          text == other.text &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^ tabId.hashCode ^ text.hashCode ^ createdAt.hashCode;

  Message copyWith({
    String? id,
    String? tabId,
    String? text,
    DateTime? createdAt,
  }) =>
      Message(
        id: id ?? this.id,
        tabId: tabId ?? this.tabId,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
      );
}

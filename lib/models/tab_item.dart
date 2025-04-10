/// {@template tab_item}
/// Represents a tab in the app.
/// {@endtemplate}
class TabItem {
  /// The id of the tab.
  final String id;

  /// The title of the tab.
  final String title;

  /// The emoji of the tab.
  final String? emoji;

  /// Whether the tab is the inbox.
  final bool isInbox;

  /// Created at
  final DateTime createdAt;

  /// {@macro tab_item}
  const TabItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.emoji,
    this.isInbox = false,
  });

  /// {@macro tab_item}
  /// From json
  factory TabItem.fromJson(Map<String, Object?> yaml) => TabItem(
        id: yaml['id'] as String,
        title: yaml['title'] as String,
        emoji: yaml['emoji'] as String?,
        isInbox: yaml['isInbox'] as bool,
        createdAt: DateTime.parse(yaml['timestamp'] as String),
      );

  /// To json
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'emoji': emoji,
        'isInbox': isInbox,
        'timestamp': createdAt.toIso8601String(),
      };

  static List<TabItem> get defaultTabs => [
        TabItem(
          id: 'inbox',
          title: 'Inbox',
          emoji: '📥',
          isInbox: true,
          createdAt: DateTime.now(),
        ),
      ];

  static TabItem inbox() => TabItem(
        id: 'inbox',
        title: 'Inbox',
        emoji: '📥',
        isInbox: true,
        createdAt: DateTime.now(),
      );

  @override
  String toString() => 'TabItem(id: $id, title: $title, emoji: $emoji)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TabItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          emoji == other.emoji &&
          isInbox == other.isInbox &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      emoji.hashCode ^
      isInbox.hashCode ^
      createdAt.hashCode;
}

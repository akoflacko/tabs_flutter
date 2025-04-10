import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tabs_test/data/messages_datasource.dart';
import 'package:tabs_test/data/tabs_datasource.dart';
import 'package:tabs_test/models/message.dart';
import 'package:tabs_test/models/tab_item.dart';

/// application doc dir/
/// - tabs/
///   - tabs.json
///   - id1/
///     - messageId1.md
///     - messageId2.md
///   - id2/
///     - messageId1.md
///     - messageId2.md
class TabsDatasource$Storage implements ITabsDatasource, IMessagesDatasource {
  late final Directory _baseDir;

  late final File _tabsJsonFile;
  late TabsJson _tabsJson;

  Completer<void>? _initializedCompleter;

  String _messageExtension = '.md';

  // #region Init

  Future<void> _createTabsJsonIfAbsent() async {
    final tabsJsonFile = File(path.join(_baseDir.path, 'tabs.json'));
    final isExist = await tabsJsonFile.exists();
    if (!isExist) await tabsJsonFile.create(recursive: true);

    _tabsJsonFile = tabsJsonFile;

    final jsonContent = await tabsJsonFile.readAsString();
    if (jsonContent.isEmpty) {
      _tabsJson = TabsJson(tabs: []);
      return;
    }

    _tabsJson = TabsJson.fromJson(
      jsonDecode(
        jsonContent,
      ),
    );
  }

  Future<void> _addDefaultTabIfAbsent() async {
    final defaultTab = TabItem.inbox();
    final isExist = _tabsJson.tabs.any((tab) => tab.id == defaultTab.id);

    if (!isExist) {
      final dir = Directory(_buildTabDirPath(defaultTab.id));
      await dir.create(recursive: true);

      _tabsJson.tabs.add(defaultTab);
      await _updateTabsJson(_tabsJson);
    }
  }

  Future<void> _init() async {
    if (_initializedCompleter != null) return _initializedCompleter!.future;

    _initializedCompleter = Completer<void>();

    final appDir = await getApplicationDocumentsDirectory();
    _baseDir = Directory(path.join(appDir.path, 'tabs'));

    final isExist = await _baseDir.exists();
    if (!isExist) await _baseDir.create(recursive: true);

    await _createTabsJsonIfAbsent();
    await _addDefaultTabIfAbsent();

    _initializedCompleter?.complete();
  }

  // #endregion

  // #region Add Tab

  String _buildTabDirPath(String tabId) => path.join(_baseDir.path, tabId);

  @override
  Future<TabItem> createTab(
    TabItem tab,
  ) async {
    await _init();

    final dir = Directory(_buildTabDirPath(tab.id));
    await dir.create(recursive: true);

    _tabsJson.tabs.add(tab);
    await _updateTabsJson(_tabsJson);

    return tab;
  }

  // #endregion

  // #region Remove Tab

  @override
  Future<void> deleteTab(
    TabItem tab,
  ) async {
    await _init();

    final dir = Directory(_buildTabDirPath(tab.id));
    await dir.delete(recursive: true);
    _tabsJson.tabs.removeWhere((element) => element.id == tab.id);
    await _updateTabsJson(_tabsJson);
  }

  // #endregion

  // #region Update Tab

  @override
  Future<TabItem> updateTab(
    TabItem tab,
  ) async {
    await _init();

    _tabsJson.tabs.removeWhere((element) => element.id == tab.id);
    _tabsJson.tabs.add(tab);
    await _updateTabsJson(_tabsJson);

    return tab;
  }

  // #endregion

  // #region Fetch Tabs

  @override
  Future<List<TabItem>> fetchTabs() async {
    await _init();
    return _tabsJson.tabs;
  }

  // #endregion

  Future<void> _updateTabsJson(
    TabsJson json,
  ) async {
    final jsonContent = jsonEncode(json.toJson());
    await _tabsJsonFile.writeAsString(jsonContent);
    _tabsJson = json;
  }

  @override
  Future<Message> createMessage(
    Message message,
  ) async {
    final tabId = message.tabId;
    final tabDir = Directory(_buildTabDirPath(tabId));
    final isExist = await tabDir.exists();
    if (!isExist) throw Exception('Tab not found');

    // Создаем markdown контент
    final content = '''
                    ---
                    createdAt: ${message.createdAt.toIso8601String()}
                    ---

                    ${message.text}
                    ''';

    final fileName = 'message_${message.id}.md';
    final file = File(path.join(tabDir.path, fileName));

    await file.writeAsString(content);

    return message;
  }

  @override
  Future<void> deleteMessage(
    Message message,
  ) async {
    final tabId = message.tabId;
    final tabDir = Directory(_buildTabDirPath(tabId));
    final isExist = await tabDir.exists();
    if (!isExist) throw Exception('Tab not found');

    final fileName = 'message_${message.id}';
    final file = File(path.join(tabDir.path, fileName));
    await file.delete();
  }

  @override
  Future<List<Message>> fetchMessages(
    String tabId,
  ) async {
    final tabDir = Directory(_buildTabDirPath(tabId));
    final isExist = await tabDir.exists();
    if (!isExist) throw Exception('Tab not found');

    final List<Message> messages = [];

    await for (final entity in tabDir.list()) {
      if (entity is! File) continue;

      final content = await entity.readAsString();

      final message = _parseMessageFromMd(tabId, content);
      messages.add(message);
    }

    return messages;
  }

  @override
  Future<Message> moveMessage(
    Message message,
    String newTabId,
  ) async {
    await deleteMessage(message);
    message = message.copyWith(tabId: newTabId);
    await createMessage(message);
    return message;
  }

  Message _parseMessageFromMd(String tabId, String content) {
    final parts = content.split('---');
    if (parts.length < 3) {
      throw FormatException('Invalid markdown format');
    }

    // Парсим метаданные
    final metadata = parts[1].trim().split('\n');
    DateTime? timestamp;

    for (final line in metadata) {
      final keyValue = line.split(': ');
      if (keyValue.length != 2) continue;

      final key = keyValue[0].trim();
      final value = keyValue[1].trim();

      switch (key) {
        case 'createdAt':
          timestamp = DateTime.parse(value);
          break;
      }
    }

    // Получаем текст сообщения
    final text = parts[2].trim();

    if (timestamp == null) {
      throw FormatException('Timestamp is required');
    }

    return Message(
      text: text,
      createdAt: timestamp,
      tabId: tabId,
    );
  }

  @override
  Future<Message> updateMessage(
    Message message,
  ) async {
    final tabId = message.tabId;
    final tabDir = Directory(_buildTabDirPath(tabId));
    final isExist = await tabDir.exists();
    if (!isExist) throw Exception('Tab not found');

    final fileName = 'message_${message.id}.md';
    final file = File(path.join(tabDir.path, fileName));

    // Создаем markdown контент
    final content = '''
                    ---
                    createdAt: ${message.createdAt.toIso8601String()}
                    ---

                    ${message.text}
                    ''';

    await file.writeAsString(content);

    return message;
  }
}

class TabsJson {
  final List<TabItem> tabs;

  const TabsJson({
    required this.tabs,
  });

  factory TabsJson.fromJson(Map<String, Object?> json) => TabsJson(
        tabs: List<TabItem>.from(
          (json['tabs'] as List).map(
            (e) => TabItem.fromJson(
              e as Map<String, Object?>,
            ),
          ),
        ),
      );

  Map<String, Object?> toJson() => {'tabs': tabs};
}

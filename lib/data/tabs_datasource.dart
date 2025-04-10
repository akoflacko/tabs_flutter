import 'package:tabs_test/models/tab_item.dart';

/// {@template tabs_datasource}
/// A datasource for tabs.
/// {@endtemplate}
abstract interface class ITabsDatasource {
  /// Fetches tabs.
  Future<List<TabItem>> fetchTabs();

  /// Updates a tab.
  Future<TabItem> updateTab(TabItem tab);

  /// Deletes a tab.
  Future<void> deleteTab(TabItem tab);

  /// Creates a tab.
  Future<TabItem> createTab(TabItem tab);
}

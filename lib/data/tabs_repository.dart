import 'package:tabs_test/data/tabs_datasource.dart';
import 'package:tabs_test/models/tab_item.dart';

/// {@template tabs_repository}
/// A repository for tabs.
/// {@endtemplate}
abstract interface class ITabsRepository {
  /// Fetches tabs.
  Future<List<TabItem>> fetchTabs();

  /// Creates a tab.
  Future<TabItem> createTab(TabItem tab);

  /// Updates a tab.
  Future<TabItem> updateTab(TabItem tab);

  /// Deletes a tab.
  Future<void> deleteTab(TabItem tab);
}

class TabsRepository implements ITabsRepository {
  final ITabsDatasource _datasource;

  const TabsRepository(
    this._datasource,
  );

  @override
  Future<TabItem> createTab(
    TabItem tab,
  ) =>
      _datasource.createTab(
        tab,
      );

  @override
  Future<void> deleteTab(
    TabItem tab,
  ) =>
      _datasource.deleteTab(
        tab,
      );

  @override
  Future<List<TabItem>> fetchTabs() => _datasource.fetchTabs();

  @override
  Future<TabItem> updateTab(
    TabItem tab,
  ) =>
      _datasource.updateTab(tab);
}

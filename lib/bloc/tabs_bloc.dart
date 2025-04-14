import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart' as bloc_concurrency;
import 'package:collection/collection.dart';
import 'package:tabs_test/bloc/set_state_mixin.dart';
import 'package:tabs_test/data/tabs_repository.dart';
import 'package:tabs_test/models/tab_item.dart';

class TabsBloc extends Bloc<TabsEvent, TabsState> with SetStateMixin<TabsState> {
  TabsBloc({
    required ITabsRepository repository,
    required TabsState initialState,
  })  : _repository = repository,
        super(initialState) {
    on<TabsEvent>(
      (event, _) => switch (event) {
        _TabsEvent$FetchTabs event => _fetchTabs(event),
        _TabsEvent$TabCreated event => _tabCreated(event),
        _TabsEvent$TabUpdated event => _tabUpdated(event),
        _TabsEvent$TabDeleted event => _tabDeleted(event),
      },
      transformer: bloc_concurrency.sequential(),
    );
  }

  final ITabsRepository _repository;

  Future<void> _fetchTabs(_TabsEvent$FetchTabs event) async {
    setState(TabsState.processing(tabs: state.tabs, message: 'Processing'));
    try {
      final tabs = await _repository.fetchTabs();

      setState(TabsState.successful(tabs: tabs, message: 'Successful'));
    } catch (e) {
      setState(TabsState.idle(tabs: state.tabs, error: e, message: 'Error: $e'));
    } finally {
      setState(TabsState.idle(tabs: state.tabs, message: 'Idle'));
    }
  }

  void _tabCreated(_TabsEvent$TabCreated event) {
    final map = {for (var tab in state.tabs) tab.id: tab};
    final updatedMap = map..[event.tabItem.id] = event.tabItem;

    setState(
      TabsState.tabCreated(
        tabItem: event.tabItem,
        tabs: updatedMap.values.toList(),
        message: 'Successful',
      ),
    );
  }

  Future<void> _tabUpdated(_TabsEvent$TabUpdated event) async {
    final tab = event.tabItem;
    final tabs = state.tabs.map((t) => t.id == tab.id ? tab : t).toList();

    setState(TabsState.successful(tabs: tabs, message: 'Successful'));
  }

  Future<void> _tabDeleted(_TabsEvent$TabDeleted event) async {
    final tabs = state.tabs.where((t) => t.id != event.tabItem.id).toList();

    setState(TabsState.successful(tabs: tabs, message: 'Successful'));
  }
}

sealed class TabsEvent {
  const TabsEvent();

  abstract final String type;

  const factory TabsEvent.fetchTabs() = _TabsEvent$FetchTabs;

  const factory TabsEvent.tabDeleted({required TabItem tabItem}) = _TabsEvent$TabDeleted;

  const factory TabsEvent.tabUpdated({required TabItem tabItem}) = _TabsEvent$TabUpdated;

  const factory TabsEvent.tabCreated({required TabItem tabItem}) = _TabsEvent$TabCreated;
}

final class _TabsEvent$FetchTabs extends TabsEvent {
  const _TabsEvent$FetchTabs();

  @override
  String get type => 'fetchTabs';

  @override
  bool operator ==(Object other) => other is _TabsEvent$FetchTabs;

  @override
  int get hashCode => type.hashCode;
}

final class _TabsEvent$TabDeleted extends TabsEvent {
  const _TabsEvent$TabDeleted({required this.tabItem});

  final TabItem tabItem;

  @override
  String get type => 'tabDeleted';

  @override
  bool operator ==(Object other) => other is _TabsEvent$TabDeleted;

  @override
  int get hashCode => type.hashCode;
}

final class _TabsEvent$TabUpdated extends TabsEvent {
  const _TabsEvent$TabUpdated({required this.tabItem});

  final TabItem tabItem;

  @override
  String get type => 'tabUpdated';

  @override
  bool operator ==(Object other) => other is _TabsEvent$TabUpdated && other.tabItem == tabItem;

  @override
  int get hashCode => type.hashCode ^ tabItem.hashCode;
}

final class _TabsEvent$TabCreated extends TabsEvent {
  const _TabsEvent$TabCreated({required this.tabItem});

  final TabItem tabItem;

  @override
  String get type => 'tabCreated';

  @override
  bool operator ==(Object other) => other is _TabsEvent$TabCreated && other.tabItem == tabItem;

  @override
  int get hashCode => type.hashCode ^ tabItem.hashCode;
}

sealed class TabsState extends _$TabsState {
  const TabsState({required super.tabs, super.message = '', super.error});

  const factory TabsState.idle({
    required List<TabItem> tabs,
    Object? error,
    String message,
  }) = _TabsState$Idle;

  const factory TabsState.processing({
    required List<TabItem> tabs,
    String message,
  }) = _TabsState$Processing;

  const factory TabsState.successful({
    required List<TabItem> tabs,
    String message,
  }) = _TabsState$Successful;

  const factory TabsState.tabCreated({
    required List<TabItem> tabs,
    required TabItem tabItem,
    String message,
  }) = _TabsState$TabCreated;

  TabItem? get createdTab => switch (this) {
        _TabsState$TabCreated tabCreated => tabCreated.tabItem,
        _ => null,
      };
}

final class _TabsState$Idle extends TabsState {
  const _TabsState$Idle({required super.tabs, super.message = 'Idle', super.error});

  @override
  String get type => 'idle';
}

final class _TabsState$Processing extends TabsState {
  const _TabsState$Processing({required super.tabs, super.message = 'Processing'});

  @override
  String get type => 'processing';
}

final class _TabsState$Successful extends TabsState {
  const _TabsState$Successful({required super.tabs, super.message = 'Successful'});

  @override
  String get type => 'successful';
}

final class _TabsState$TabCreated extends TabsState {
  const _TabsState$TabCreated({
    required super.tabs,
    required this.tabItem,
    super.message = 'Tab Created',
  });

  final TabItem tabItem;

  @override
  String get type => 'tabCreated';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TabsState$TabCreated &&
          const ListEquality().equals(tabs, other.tabs) &&
          tabItem == other.tabItem &&
          message == other.message &&
          type == other.type;

  @override
  int get hashCode => Object.hashAll([
        const ListEquality().hash(tabs),
        tabItem,
        message,
        type,
      ]);
}

abstract base class _$TabsState {
  /// List of tabs
  final List<TabItem> tabs;

  /// Error
  final Object? error;

  /// Message
  final String message;

  /// Alias
  String get type;

  const _$TabsState({required this.tabs, this.message = '', this.error});

  @override
  String toString() => 'TabsState.$type(tabs: $tabs, error: $error, message: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _$TabsState &&
          const ListEquality().equals(tabs, other.tabs) &&
          !identical(error, other.error) &&
          message == other.message &&
          type == other.type;

  @override
  int get hashCode => Object.hashAll([const ListEquality().hash(tabs), error, message, type]);
}

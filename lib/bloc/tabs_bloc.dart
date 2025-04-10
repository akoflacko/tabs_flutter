// ignore_for_file: overridden_fields

import 'package:bloc/bloc.dart';
import 'package:tabs_test/data/tabs_repository.dart';
import 'package:tabs_test/models/tab_item.dart';

class TabsBloc extends Bloc<TabsEvent, TabsState> {
  TabsBloc({
    required ITabsRepository repository,
    required TabsState initialState,
  })  : _repository = repository,
        super(initialState) {
    on<TabsEvent>(
      (event, emit) => switch (event) {
        TabsEvent$FetchTabs event => _fetchTabs(event, emit),
        TabsEvent$TabCreated event => _tabCreated(event, emit),
        TabsEvent$TabUpdated event => _tabUpdated(event, emit),
        TabsEvent$TabDeleted event => _tabDeleted(event, emit),
      },
    );
  }

  final ITabsRepository _repository;

  Future<void> _fetchTabs(
    TabsEvent$FetchTabs event,
    Emitter<TabsState> emit,
  ) async {
    emit(TabsState.processing(tabs: state.tabs, message: 'Processing'));
    try {
      final tabs = await _repository.fetchTabs();

      emit(TabsState.successful(tabs: tabs, message: 'Successful'));
    } catch (e) {
      emit(TabsState.idle(tabs: state.tabs, error: e, message: 'Error: $e'));
    } finally {
      emit(TabsState.idle(tabs: state.tabs, message: 'Idle'));
    }
  }

  Future<void> _tabCreated(
    TabsEvent$TabCreated event,
    Emitter<TabsState> emit,
  ) async {
    emit(TabsState.processing(tabs: state.tabs, message: 'Processing'));
    try {
      final tab = await _repository.createTab(event.tabItem);
      final tabs = [...state.tabs, tab];

      emit(TabsState.successful(tabs: tabs, message: 'Successful'));
    } catch (e) {
      emit(TabsState.idle(tabs: state.tabs, error: e, message: 'Error: $e'));
    } finally {
      emit(TabsState.idle(tabs: state.tabs, message: 'Idle'));
    }
  }

  Future<void> _tabUpdated(
    TabsEvent$TabUpdated event,
    Emitter<TabsState> emit,
  ) async {
    emit(TabsState.processing(tabs: state.tabs, message: 'Processing'));
    try {
      final tab = await _repository.updateTab(event.tabItem);
      final tabs = state.tabs.map((t) => t.id == tab.id ? tab : t).toList();

      emit(TabsState.successful(tabs: tabs, message: 'Successful'));
    } catch (e) {
      emit(TabsState.idle(tabs: state.tabs, error: e, message: 'Error: $e'));
    } finally {
      emit(TabsState.idle(tabs: state.tabs, message: 'Idle'));
    }
  }

  Future<void> _tabDeleted(
    TabsEvent$TabDeleted event,
    Emitter<TabsState> emit,
  ) async {
    emit(TabsState.processing(tabs: state.tabs, message: 'Processing'));
    try {
      await _repository.deleteTab(event.tabItem);
      final tabs = state.tabs.where((t) => t.id != event.tabItem.id).toList();

      emit(TabsState.successful(tabs: tabs, message: 'Successful'));
    } catch (e) {
      emit(TabsState.idle(tabs: state.tabs, error: e, message: 'Error: $e'));
    } finally {
      emit(TabsState.idle(tabs: state.tabs, message: 'Idle'));
    }
  }
}

sealed class TabsEvent extends _$TabsEvent {
  const TabsEvent({
    super.tabItem,
  });

  const factory TabsEvent.fetchTabs() = TabsEvent$FetchTabs;

  const factory TabsEvent.tabDeleted({
    required TabItem tabItem,
  }) = TabsEvent$TabDeleted;

  const factory TabsEvent.tabUpdated({
    required TabItem tabItem,
  }) = TabsEvent$TabUpdated;

  const factory TabsEvent.tabCreated({
    required TabItem tabItem,
  }) = TabsEvent$TabCreated;
}

final class TabsEvent$FetchTabs extends TabsEvent {
  const TabsEvent$FetchTabs();

  @override
  String get type => 'fetch_tabs';
}

final class TabsEvent$TabDeleted extends TabsEvent {
  const TabsEvent$TabDeleted({
    required this.tabItem,
  });

  @override
  final TabItem tabItem;

  @override
  String get type => 'tab_deleted';
}

final class TabsEvent$TabUpdated extends TabsEvent {
  const TabsEvent$TabUpdated({
    required this.tabItem,
  });

  @override
  final TabItem tabItem;

  @override
  String get type => 'tab_updated';
}

final class TabsEvent$TabCreated extends TabsEvent {
  const TabsEvent$TabCreated({
    required this.tabItem,
  });

  @override
  final TabItem tabItem;

  @override
  String get type => 'tab_created';
}

abstract base class _$TabsEvent {
  final TabItem? tabItem;

  const _$TabsEvent({
    this.tabItem,
  });

  String get type;

  @override
  String toString() => 'TabsEvent.$type(tabItem: $tabItem)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _$TabsEvent &&
          runtimeType == other.runtimeType &&
          tabItem == other.tabItem &&
          type == other.type;

  @override
  int get hashCode => Object.hash(tabItem, type);
}

sealed class TabsState extends _$TabsState {
  const TabsState({
    required super.tabs,
    super.message = '',
    super.error,
  });

  const factory TabsState.idle({
    required List<TabItem> tabs,
    Object? error,
    String message,
  }) = TabsState$Idle;

  const factory TabsState.processing({
    required List<TabItem> tabs,
    String message,
  }) = TabsState$Processing;

  const factory TabsState.successful({
    required List<TabItem> tabs,
    String message,
  }) = TabsState$Successful;
}

final class TabsState$Idle extends TabsState {
  const TabsState$Idle({
    required super.tabs,
    super.message = 'Idle',
    super.error,
  });

  @override
  String get type => 'idle';
}

final class TabsState$Processing extends TabsState {
  const TabsState$Processing({
    required super.tabs,
    super.message = 'Processing',
  });

  @override
  String get type => 'processing';
}

final class TabsState$Successful extends TabsState {
  const TabsState$Successful({
    required super.tabs,
    super.message = 'Successful',
  });

  @override
  String get type => 'successful';
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

  const _$TabsState({
    required this.tabs,
    this.message = '',
    this.error,
  });

  @override
  String toString() =>
      'TabsState.type(tabs: $tabs, error: $error, message: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _$TabsState &&
          runtimeType == other.runtimeType &&
          tabs == other.tabs &&
          error == other.error &&
          message == other.message &&
          type == other.type;

  @override
  int get hashCode =>
      tabs.hashCode ^ error.hashCode ^ message.hashCode ^ type.hashCode;
}

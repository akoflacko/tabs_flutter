// ignore_for_file: overridden_fields

import 'package:bloc/bloc.dart';
import 'package:tabs_test/data/tabs_repository.dart';
import 'package:tabs_test/models/tab_item.dart';

class TabBloc extends Bloc<TabEvent, TabState> {
  TabBloc({required ITabsRepository repository, required TabState initialState})
      : _repository = repository,
        super(initialState) {
    on<TabEvent>(
      (event, emit) => switch (event) {
        _TabEvent$Update event => _update(event, emit),
        _TabEvent$Delete event => _delete(event, emit),
      },
    );
  }

  final ITabsRepository _repository;

  Future<void> _update(_TabEvent$Update event, Emitter<TabState> emit) async {
    emit(TabState.processing(tabItem: event.tabItem, message: 'Processing'));

    try {
      final tab = await _repository.updateTab(event.tabItem);
      emit(TabState.successful(tabItem: tab, message: 'Successful'));
    } catch (e) {
      emit(TabState.idle(tabItem: event.tabItem, error: e, message: 'Error: $e'));
    } finally {
      emit(TabState.idle(tabItem: event.tabItem, message: 'Idle'));
    }
  }

  Future<void> _delete(_TabEvent$Delete event, Emitter<TabState> emit) async {
    emit(TabState.processing(tabItem: state.tabItem, message: 'Processing'));

    try {
      await _repository.deleteTab(state.tabItem);

      emit(TabState.successful(tabItem: state.tabItem, message: 'Successful'));
    } catch (e) {
      emit(TabState.idle(tabItem: state.tabItem, error: e, message: 'Error: $e'));
    } finally {
      emit(TabState.idle(tabItem: state.tabItem, message: 'Idle'));
    }
  }
}

sealed class TabEvent extends _$TabEvent {
  const TabEvent({super.tabItem});

  const factory TabEvent.update({required TabItem tabItem}) = _TabEvent$Update;

  const factory TabEvent.delete() = _TabEvent$Delete;
}

final class _TabEvent$Delete extends TabEvent {
  const _TabEvent$Delete();

  @override
  String get type => 'delete';
}

final class _TabEvent$Update extends TabEvent {
  const _TabEvent$Update({required this.tabItem}) : super(tabItem: tabItem);

  @override
  final TabItem tabItem;

  @override
  String get type => 'update';
}

abstract base class _$TabEvent {
  const _$TabEvent({this.tabItem});

  final TabItem? tabItem;

  String get type;

  @override
  String toString() => 'TabEvent.$type(tabItem: $tabItem)';

  @override
  bool operator ==(Object other) => identical(this, other) || other is _$TabEvent && type == other.type && tabItem == other.tabItem;

  @override
  int get hashCode => Object.hash(type, tabItem);
}

sealed class TabState extends _$TabState {
  const TabState({required super.tabItem, super.message, super.error});

  const factory TabState.idle({required TabItem tabItem, String message, Object? error}) = TabState$Idle;

  const factory TabState.processing({required TabItem tabItem, String message}) = TabState$Processing;

  const factory TabState.successful({required TabItem tabItem, String message}) = TabState$Successful;

  const factory TabState.deleted({required TabItem tabItem, String message}) = TabsState$Deleted;
}

final class TabState$Idle extends TabState {
  const TabState$Idle({required super.tabItem, super.message, super.error});

  @override
  String get type => 'idle';
}

final class TabState$Processing extends TabState {
  const TabState$Processing({required super.tabItem, super.message, super.error});

  @override
  String get type => 'processing';
}

final class TabState$Successful extends TabState {
  const TabState$Successful({required super.tabItem, super.message, super.error});

  @override
  String get type => 'successful';
}

final class TabsState$Deleted extends TabState {
  const TabsState$Deleted({required super.tabItem, super.message, super.error});

  @override
  String get type => 'deleted';
}

abstract base class _$TabState {
  const _$TabState({required this.tabItem, this.message = '', this.error});

  final TabItem tabItem;

  final String message;

  final Object? error;

  String get type;

  @override
  String toString() => 'TabState.$type(tabItem: $tabItem, message: $message, error: $error)';

  @override
  bool operator ==(Object other) =>
      other is _$TabState && other.type == type && other.tabItem == tabItem && other.message == message && other.error == error;

  @override
  int get hashCode => type.hashCode ^ tabItem.hashCode ^ message.hashCode ^ error.hashCode;
}

// ignore_for_file: overridden_fields

import 'package:bloc/bloc.dart';
import 'package:tabs_test/data/tabs_repository.dart';
import 'package:tabs_test/models/tab_item.dart';

class CreateTabBloc extends Bloc<CreateTabEvent, CreateTabState> {
  CreateTabBloc({required ITabsRepository repository, required CreateTabState initialState})
      : _repository = repository,
        super(initialState) {
    on<CreateTabEvent>(_createTab);
  }

  final ITabsRepository _repository;

  Future<void> _createTab(CreateTabEvent event, Emitter<CreateTabState> emit) async {
    emit(CreateTabState.processing(message: 'Processing'));
    try {
      final tab = await _repository.createTab(event.tabItem);
      emit(CreateTabState.successful(message: 'Successful', tabItem: tab));
    } catch (e) {
      emit(CreateTabState.idle(error: e, message: 'Error: $e'));
    } finally {
      emit(CreateTabState.idle());
    }
  }
}

class CreateTabEvent {
  const CreateTabEvent({required this.tabItem});

  final TabItem tabItem;

  @override
  String toString() => 'CreateTabEvent(tabItem: $tabItem)';

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateTabEvent && runtimeType == other.runtimeType && tabItem == other.tabItem;

  @override
  int get hashCode => tabItem.hashCode;
}

sealed class CreateTabState extends _$CreateTabState {
  const CreateTabState({super.tabItem, super.message, super.error});

  const factory CreateTabState.idle({String message, Object? error}) = CreateTabState$Idle;

  const factory CreateTabState.processing({String message}) = CreateTabState$Processing;

  const factory CreateTabState.successful({String message, required TabItem tabItem}) = CreateTabState$Successful;

  bool get isIdle => this is CreateTabState$Idle;

  bool get isProcessing => this is CreateTabState$Processing;

  bool get isSuccessful => this is CreateTabState$Successful;
}

final class CreateTabState$Idle extends CreateTabState {
  const CreateTabState$Idle({super.tabItem, super.message, super.error});

  @override
  String get type => 'idle';
}

final class CreateTabState$Processing extends CreateTabState {
  const CreateTabState$Processing({super.tabItem, super.message, super.error});

  @override
  String get type => 'processing';
}

final class CreateTabState$Successful extends CreateTabState {
  const CreateTabState$Successful({required this.tabItem, super.message, super.error}) : super(tabItem: tabItem);

  @override
  final TabItem tabItem;

  @override
  String get type => 'successful';
}

abstract base class _$CreateTabState {
  const _$CreateTabState({this.tabItem, this.message = '', this.error});

  final TabItem? tabItem;

  final String message;

  final Object? error;

  String get type;

  @override
  String toString() => 'CreateTabState.$type(tabItem: $tabItem, message: $message, error: $error)';

  @override
  bool operator ==(Object other) =>
      other is _$CreateTabState && other.type == type && other.tabItem == tabItem && other.message == message && other.error == error;

  @override
  int get hashCode => type.hashCode ^ tabItem.hashCode ^ message.hashCode ^ error.hashCode;
}

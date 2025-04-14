// ignore_for_file: overridden_fields

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:tabs_test/data/messages_repository.dart';
import 'package:tabs_test/models/message.dart';

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  MessagesBloc({required IMessagesRepository repository, required MessagesState initialState})
      : _repository = repository,
        super(initialState) {
    on<MessagesEvent>(
      (event, emit) => switch (event) {
        MessagesEvent$Fetch event => _fetchMessages(event, emit),
        MessagesEvent$Send event => _sendMessage(event, emit),
        MessagesEvent$MoveMessages event => _moveMessages(event, emit),
        MessagesEvent$DeleteMessages event => _deleteMessages(event, emit),
        MessagesEvent$HandleMovedMessages event => _handleMovedMessages(event, emit),
      },
    );
  }

  final IMessagesRepository _repository;

  Future<void> _fetchMessages(MessagesEvent$Fetch event, Emitter<MessagesState> emit) async {
    emit(MessagesState.processing(tabId: state.tabId, message: 'Processing', messages: state.messages));

    try {
      final messages = await _repository.fetchMessages(state.tabId);

      emit(MessagesState.successful(tabId: state.tabId, messages: messages));
    } catch (e) {
      emit(MessagesState.idle(tabId: state.tabId, messages: state.messages, error: e, message: 'Error: $e'));
    }
  }

  Future<void> _sendMessage(MessagesEvent$Send event, Emitter<MessagesState> emit) async {
    emit(MessagesState.processing(tabId: event.message.tabId, messages: state.messages, message: 'Processing'));

    try {
      final message = await _repository.createMessage(event.message);
      final messages = [...state.messages, message];

      emit(MessagesState.successful(tabId: event.message.tabId, messages: messages, message: 'Successful'));
    } catch (e) {
      emit(MessagesState.idle(tabId: event.message.tabId, messages: state.messages, error: e, message: 'Error: $e'));
    } finally {
      emit(MessagesState.idle(tabId: event.message.tabId, messages: state.messages, message: 'Idle'));
    }
  }

  Future<void> _deleteMessages(MessagesEvent$DeleteMessages event, Emitter<MessagesState> emit) async {
    emit(MessagesState.processing(tabId: state.tabId, messages: state.messages, message: 'Processing'));

    try {
      await _repository.deleteMessages(event.messages);

      final messages = state.messages.where((message) => !event.messages.contains(message)).toList();

      emit(MessagesState.successful(tabId: state.tabId, messages: messages, message: 'Successful'));
    } catch (e) {
      emit(MessagesState.idle(tabId: state.tabId, messages: state.messages, error: e, message: 'Error: $e'));
    } finally {
      emit(MessagesState.idle(tabId: state.tabId, messages: state.messages, message: 'Idle'));
    }
  }

  Future<void> _moveMessages(
    MessagesEvent$MoveMessages event,
    Emitter<MessagesState> emit,
  ) async {
    emit(
      MessagesState.processing(
        tabId: event.messages.first.tabId,
        messages: state.messages,
        message: 'Processing',
      ),
    );

    try {
      final movedMessages = await _repository.moveMessages(
        event.messages,
        event.toTabId,
      );

      // remove moved messages from the current tab
      final messages = state.messages.where((message) => !event.messages.contains(message)).toList();

      emit(
        MessagesState.messagesMoved(
          movedMessages: movedMessages,
          tabId: event.messages.first.tabId,
          fromTabId: event.messages.first.tabId,
          messages: messages,
          message: 'Successful',
        ),
      );
    } catch (e) {
      emit(
        MessagesState.idle(
          tabId: event.messages.first.tabId,
          messages: state.messages,
          error: e,
          message: 'Error: $e',
        ),
      );
    } finally {
      emit(
        MessagesState.idle(
          tabId: event.messages.first.tabId,
          messages: state.messages,
          message: 'Idle',
        ),
      );
    }
  }

  Future<void> _handleMovedMessages(
    MessagesEvent$HandleMovedMessages event,
    Emitter<MessagesState> emit,
  ) async {
    // add moved messages to the current tab
    final messages = [...state.messages, ...event.movedMessages];

    emit(
      MessagesState.successful(
        messages: messages,
        tabId: state.tabId,
        message: 'Successful handle moved messages',
      ),
    );
  }
}

sealed class MessagesEvent extends _$MessagesEvent {
  const MessagesEvent({super.message});

  const factory MessagesEvent.fetch() = MessagesEvent$Fetch;

  const factory MessagesEvent.send({required Message message}) = MessagesEvent$Send;

  const factory MessagesEvent.deleteMessages({required List<Message> messages}) = MessagesEvent$DeleteMessages;

  const factory MessagesEvent.moveMessages({required List<Message> messages, required String toTabId}) = MessagesEvent$MoveMessages;

  const factory MessagesEvent.handleMovedMessages({required List<Message> movedMessages}) = MessagesEvent$HandleMovedMessages;
}

final class MessagesEvent$Fetch extends MessagesEvent {
  const MessagesEvent$Fetch({super.message});

  @override
  String get type => 'Fetch';
}

final class MessagesEvent$Send extends MessagesEvent {
  const MessagesEvent$Send({required this.message}) : super(message: message);

  @override
  final Message message;

  @override
  String get type => 'Send';
}

final class MessagesEvent$DeleteMessages extends MessagesEvent {
  const MessagesEvent$DeleteMessages({
    required this.messages,
  });

  final List<Message> messages;

  @override
  String get type => 'DeleteMessages';

  @override
  bool operator ==(Object other) => other is MessagesEvent$DeleteMessages && const ListEquality<Message>().equals(other.messages, messages);

  @override
  int get hashCode => ListEquality<Message>().hash(messages);
}

final class MessagesEvent$MoveMessages extends MessagesEvent {
  const MessagesEvent$MoveMessages({
    required this.messages,
    required this.toTabId,
  });

  final List<Message> messages;

  final String toTabId;

  @override
  String get type => 'MoveMessages';

  @override
  bool operator ==(Object other) =>
      other is MessagesEvent$MoveMessages && const ListEquality<Message>().equals(other.messages, messages) && toTabId == other.toTabId;

  @override
  int get hashCode => ListEquality<Message>().hash(messages) ^ toTabId.hashCode;
}

final class MessagesEvent$HandleMovedMessages extends MessagesEvent {
  const MessagesEvent$HandleMovedMessages({
    required this.movedMessages,
  });

  final List<Message> movedMessages;

  @override
  String get type => 'HandleMovedMessages';

  @override
  bool operator ==(Object other) =>
      other is MessagesEvent$HandleMovedMessages && const ListEquality<Message>().equals(other.movedMessages, movedMessages);

  @override
  int get hashCode => const ListEquality<Message>().hash(movedMessages);
}

abstract base class _$MessagesEvent {
  const _$MessagesEvent({this.message});

  final Message? message;

  String get type;

  @override
  String toString() => 'MessagesEvent.$type(message: $message)';

  @override
  bool operator ==(Object other) => identical(this, other) || other is _$MessagesEvent && type == other.type && message == other.message;

  @override
  int get hashCode => message.hashCode ^ type.hashCode;
}

sealed class MessagesState extends _$MessagesState {
  const MessagesState({required super.tabId, required super.messages, super.error, super.message = ''});

  const factory MessagesState.idle({required String tabId, required List<Message> messages, Object? error, String message}) = MessagesState$Idle;

  const factory MessagesState.processing({required String tabId, required List<Message> messages, String message}) = MessagesState$Processing;

  const factory MessagesState.successful({required String tabId, required List<Message> messages, String message}) = MessagesState$Successful;

  const factory MessagesState.messageMoved({
    required String tabId,
    required List<Message> messages,
    required Message movedMessage,
    required String fromTabId,
    String message,
  }) = MessagesState$MessageMoved;

  const factory MessagesState.messagesMoved({
    required String tabId,
    required List<Message> messages,
    required List<Message> movedMessages,
    required String fromTabId,
    String message,
  }) = MessagesState$MessagesMoved;

  bool get isIdle => this is MessagesState$Idle;

  bool get isProcessing => this is MessagesState$Processing;

  bool get isSuccessful => this is MessagesState$Successful;

  bool get isMessageMoved => this is MessagesState$MessageMoved;
}

final class MessagesState$Idle extends MessagesState {
  const MessagesState$Idle({required super.tabId, required super.messages, super.error, super.message = 'Idle'});

  @override
  String get type => 'Idle';
}

final class MessagesState$Processing extends MessagesState {
  const MessagesState$Processing({required super.tabId, required super.messages, super.message = 'Processing'});

  @override
  String get type => 'Processing';
}

final class MessagesState$Successful extends MessagesState {
  const MessagesState$Successful({required super.tabId, required super.messages, super.message = 'Successful'});

  @override
  String get type => 'Successful';
}

final class MessagesState$MessageMoved extends MessagesState {
  const MessagesState$MessageMoved({
    required super.tabId,
    required super.messages,
    required this.movedMessage,
    required this.fromTabId,
    super.message = 'Message moved',
  });

  final Message movedMessage;

  final String fromTabId;

  @override
  String get type => 'MessageMoved';

  @override
  bool operator ==(Object other) =>
      other is MessagesState$MessageMoved && super == other && movedMessage == other.movedMessage && fromTabId == other.fromTabId;

  @override
  int get hashCode => super.hashCode ^ movedMessage.hashCode ^ fromTabId.hashCode;
}

final class MessagesState$MessagesMoved extends MessagesState {
  const MessagesState$MessagesMoved({
    required this.fromTabId,
    required this.movedMessages,
    required super.messages,
    required super.tabId,
    super.message = 'Messages moved',
  });

  final List<Message> movedMessages;

  final String fromTabId;

  @override
  String get type => 'MessagesMoved';

  @override
  bool operator ==(Object other) =>
      other is MessagesState$MessagesMoved && super == other && const ListEquality<Message>().equals(other.movedMessages, movedMessages);

  @override
  int get hashCode => super.hashCode ^ const ListEquality<Message>().hash(movedMessages) ^ fromTabId.hashCode;
}

abstract base class _$MessagesState {
  const _$MessagesState({required this.tabId, required this.messages, this.error, this.message = ''});

  final String tabId;

  final List<Message> messages;

  final Object? error;

  final String message;

  String get type;

  @override
  String toString() => 'MessagesState.$type(tabId: $tabId, messages: $messages, error: $error, message: $message)';

  @override
  bool operator ==(Object other) =>
      other is _$MessagesState &&
      other.tabId == tabId &&
      ListEquality<Message>().equals(other.messages, messages) &&
      other.error == error &&
      other.message == message &&
      type == other.type;

  @override
  int get hashCode => Object.hash(tabId, ListEquality<Message>().hash(messages), error, message, type);
}

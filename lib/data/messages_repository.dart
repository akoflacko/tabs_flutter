import 'package:tabs_test/data/messages_datasource.dart';
import 'package:tabs_test/models/message.dart';

/// {@template messages_repository}
/// A repository for messages.
/// {@endtemplate}
abstract interface class IMessagesRepository {
  /// Fetches messages for a specific tab.
  Future<List<Message>> fetchMessages(String tabId);

  /// Updates a message.
  Future<Message> updateMessage(Message message);

  /// Deletes a message.
  Future<void> deleteMessage(Message message);

  /// Deletes multiple messages.
  Future<void> deleteMessages(List<Message> messages);

  /// Creates a message.
  Future<Message> createMessage(Message message);

  /// Move a message to a new tab.
  Future<Message> moveMessage(Message message, String newTabId);

  /// Move multiple messages to a new tab.
  Future<List<Message>> moveMessages(List<Message> messages, String newTabId);
}

class MessagesRepository implements IMessagesRepository {
  final IMessagesDatasource _datasource;

  MessagesRepository(this._datasource);

  @override
  Future<List<Message>> fetchMessages(String tabId) => _datasource.fetchMessages(tabId);

  @override
  Future<Message> updateMessage(Message message) => _datasource.updateMessage(message);

  @override
  Future<void> deleteMessage(Message message) => _datasource.deleteMessage(message);

  @override
  Future<void> deleteMessages(List<Message> messages) => _datasource.deleteMessages(messages);

  @override
  Future<Message> createMessage(Message message) => _datasource.createMessage(message);

  @override
  Future<Message> moveMessage(Message message, String newTabId) => _datasource.moveMessage(message, newTabId);

  @override
  Future<List<Message>> moveMessages(List<Message> messages, String newTabId) => _datasource.moveMessages(messages, newTabId);
}

import 'package:tabs_test/models/message.dart';

/// {@template messages_datasource}
/// A datasource for messages.
/// {@endtemplate}
abstract interface class IMessagesDatasource {
  /// Fetches messages for a specific tab.
  Future<List<Message>> fetchMessages(String tabId);

  /// Updates a message.
  Future<Message> updateMessage(Message message);

  /// Deletes a message.
  Future<void> deleteMessage(Message message);

  /// Deletes multiple messages.
  Future<void> deleteMessages(List<Message> messages);

  /// Creates a new message.
  Future<Message> createMessage(Message message);

  /// Move message to another tab.
  Future<Message> moveMessage(Message message, String newTabId);

  /// Move multiple messages to another tab.
  Future<List<Message>> moveMessages(List<Message> messages, String newTabId);
}

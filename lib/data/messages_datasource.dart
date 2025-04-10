import 'package:tabs_test/models/message.dart';

/// {@template messages_datasource}
/// A datasource for messages.
/// {@endtemplate}
abstract interface class IMessagesDatasource {
  /// Fetches messages for a specific tab.
  Future<List<Message>> fetchMessages(
    String tabId,
  );

  /// Updates a message.
  Future<Message> updateMessage(
    Message message,
  );

  /// Deletes a message.
  Future<void> deleteMessage(
    Message message,
  );

  /// Creates a new message.
  Future<Message> createMessage(
    Message message,
  );

  /// Move message to another tab.
  Future<Message> moveMessage(
    Message message,
    String newTabId,
  );
}

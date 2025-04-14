import 'package:tabs_test/bloc/tabs_bloc.dart';
import 'package:tabs_test/data/messages_repository.dart';
import 'package:tabs_test/data/tabs_repository.dart';

class Dependencies {
  const Dependencies({required this.tabsRepository, required this.messagesRepository, required this.tabsBloc});

  final ITabsRepository tabsRepository;

  final IMessagesRepository messagesRepository;

  final TabsBloc tabsBloc;
}

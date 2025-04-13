import 'package:bloc_concurrency/bloc_concurrency.dart' as bloc_concurrency;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabs_test/bloc/tabs_bloc.dart';
import 'package:tabs_test/data/messages_repository.dart';
import 'package:tabs_test/data/tabs_datasource_storage.dart';
import 'package:tabs_test/data/tabs_repository.dart';
import 'package:tabs_test/models/dependencies.dart';
import 'package:tabs_test/widgets/dependencies_scope.dart';
import 'screens/chat_screen.dart';

class MessengerApp extends StatelessWidget {
  const MessengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Messenger',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme.copyWith(
                bodyLarge: const TextStyle(
                  fontSize: 17,
                  fontVariations: [
                    FontVariation('wght', 400),
                  ],
                ),
                bodyMedium: const TextStyle(
                  fontSize: 14,
                  fontVariations: [
                    FontVariation('wght', 400),
                  ],
                ),
              ),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

void main() async {
  Bloc.transformer = bloc_concurrency.sequential();

  final tabsDatasource = TabsDatasource$Storage();

  final tabsRepository = TabsRepository(tabsDatasource);
  final messagesRepository = MessagesRepository(tabsDatasource);

  final tabsBloc = TabsBloc(
    repository: tabsRepository,
    initialState: const TabsState.idle(
      tabs: [],
    ),
  );

  runApp(
    DependenciesScope(
      dependencies: Dependencies(
        tabsRepository: tabsRepository,
        messagesRepository: messagesRepository,
        tabsBloc: tabsBloc,
      ),
      child: const MessengerApp(),
    ),
  );
}

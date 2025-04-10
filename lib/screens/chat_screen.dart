import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabs_test/bloc/messages_bloc.dart';
import 'package:tabs_test/bloc/tab_bloc.dart';
import 'package:tabs_test/bloc/tabs_bloc.dart';
import 'package:tabs_test/data/messages_repository.dart';
import 'package:tabs_test/data/tabs_datasource_storage.dart';
import 'package:tabs_test/data/tabs_repository.dart';
import 'package:tabs_test/widgets/dependencies_scope.dart';
import 'package:tabs_test/widgets/tab_item_body.dart';
import '../widgets/input_bar.dart';
import '../widgets/scroll_tabs.dart';
import '../widgets/header.dart';
import '../widgets/side_menu.dart';
import '../models/message.dart';
import '../theme/app_colors.dart';
import '../models/tab_item.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late final TabsBloc _tabsBloc;

  final ValueNotifier<String?> _selectedTabIdNotifier = ValueNotifier(null);

  /// For each tab, there is a bloc that handles the messages for that tab
  Map<String, MessagesBloc> _messagesBlocs = {};

  /// For each tab, there is a bloc that handles the tab for that tab
  Map<String, TabBloc> _tabsBlocs = {};

  void _tabsBlocListener(TabsState state) {
    final messagesRepository = context.dependencies.messagesRepository;

    switch (state) {
      case TabsState$Successful state:
        final tabs = state.tabs;
        for (final tab in tabs) {
          if (_selectedTabIdNotifier.value == null) {
            _selectedTabIdNotifier.value = tab.id;
          }

          _messagesBlocs[tab.id] = _messagesBlocs[tab.id] ??
              MessagesBloc(
                repository: messagesRepository,
                initialState: MessagesState.idle(
                  tabId: tab.id,
                  messages: const [],
                ),
              )
            ..add(
              MessagesEvent.fetch(),
            );

          _tabsBlocs[tab.id] = _tabsBlocs[tab.id] ??
              TabBloc(
                repository: TabsRepository(TabsDatasource$Storage()),
                initialState: TabState.idle(
                  tabItem: tab,
                ),
              );
        }
        break;
      default:
    }
  }

  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  double? _dragStartX;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    _tabsBloc = context.dependencies.tabsBloc
      ..add(
        TabsEvent.fetchTabs(),
      );
    _tabsBloc.stream.listen(_tabsBlocListener);
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;
    if (_selectedTabIdNotifier.value == null) return;

    final message = Message(
      text: _textController.text,
      createdAt: DateTime.now(),
      tabId: _selectedTabIdNotifier.value!,
    );

    final bloc = _messagesBlocs[message.tabId]!;
    _textController.clear();

    bloc.add(MessagesEvent.send(message: message));
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _focusNode.unfocus(),
        child: Scaffold(
          key: _scaffoldKey,
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.getPrimaryBackground(context),
          drawer: BlocBuilder<TabsBloc, TabsState>(
            bloc: _tabsBloc,
            builder: (context, state) => ValueListenableBuilder(
              valueListenable: _selectedTabIdNotifier,
              builder: (context, value, _) => SideMenu(
                tabs: state.tabs,
                selectedTabId: value ?? '',
                onTabSelected: (value) => _selectedTabIdNotifier.value = value,
              ),
            ),
          ),
          drawerEnableOpenDragGesture: true,
          drawerEdgeDragWidth: 60,
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    Builder(
                      builder: (context) => Header(
                        onMenuPressed: () {
                          _focusNode.unfocus();
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        isSelectionMode: false,
                        onExitSelectionMode: () {},
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          BlocBuilder<TabsBloc, TabsState>(
                            bloc: _tabsBloc,
                            builder: (context, state) {
                              return PageView.builder(
                                // TODO: add controller
                                // Убираем ограничение на свайпы
                                physics: const PageScrollPhysics(),
                                itemCount: state.tabs.length,
                                onPageChanged: (index) {
                                  // print('🟦 PAGE VIEW - Page Changed:');
                                  // print('  New Index: $index');
                                  // print(
                                  //     '  Previous Index: ${_tabManager.selectedTabIndex}');

                                  // HapticFeedback.selectionClick();
                                  // setState(() {
                                  //   _tabManager.selectedTabIndex = index;
                                  //   _messageManager.messagesByTabIndex[index] ??=
                                  //       [];
                                  // });
                                },
                                itemBuilder: (context, index) {
                                  final tabItem = state.tabs[index];
                                  final bloc = _messagesBlocs[tabItem.id]!;

                                  return TabItemBody(
                                    tabItem: tabItem,
                                    bloc: bloc,
                                  );
                                },
                              );
                            },
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            top: 0,
                            left: 0,
                            right: 0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: 1,
                              child: BlocBuilder<TabsBloc, TabsState>(
                                bloc: _tabsBloc,
                                builder: (context, state) => ScrollTabs(
                                  tabs: state.tabs,
                                  selectedIndex: 0,
                                  onTabSelected: (_) {},
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    BlocSelector<TabsBloc, TabsState, List<TabItem>>(
                      bloc: _tabsBloc,
                      selector: (state) => state.tabs,
                      builder: (context, tabs) => InputBar(
                        controller: _textController,
                        focusNode: _focusNode,
                        onSendPressed: _sendMessage,
                        onAttachPressed: () {},
                        hintText: 'Новая заметка...',
                        isSelectionMode: false,
                        selectedCount: 0,
                        tabs: tabs,
                        onDelete: () async {},
                        onMove: (index) async {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool isEmoji(String text) {
    if (text.isEmpty) return false;

    final runes = text.runes.toList();

    for (final rune in runes) {
      final isInRange =
          (rune >= 0x1F300 && rune <= 0x1F9FF) || // Основные эмодзи
              (rune >= 0x2600 && rune <= 0x26FF) || // Разные символы
              (rune >= 0x2700 && rune <= 0x27BF) || // Dingbats
              (rune >= 0xFE00 && rune <= 0xFE0F); // Вариации

      if (!isInRange) {
        return false;
      }
    }

    return true;
  }
}

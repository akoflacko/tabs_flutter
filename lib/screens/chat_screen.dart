import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabs_test/bloc/messages_bloc.dart';
import 'package:tabs_test/bloc/tab_bloc.dart';
import 'package:tabs_test/bloc/tabs_bloc.dart';
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

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin, _ChatScreenStateMixin {
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _focusNode.unfocus(),
        child: Scaffold(
          key: _scaffoldKey,
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.getPrimaryBackground(context),
          drawer: BlocBuilder<TabsBloc, TabsState>(
            bloc: _tabsBloc,
            builder: (context, state) => SideMenu(
              tabs: state.tabs,
              pageController: _controller,
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
                        isSelectionMode: _selectedMessages.isNotEmpty,
                        onExitSelectionMode: () => _disableEditingMode(),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              AnimatedSwitcher(
                                duration: Durations.short2,
                                transitionBuilder: (child, animation) => FadeTransition(
                                  opacity: animation,
                                  child: SizeTransition(
                                    sizeFactor: animation,
                                    axis: Axis.vertical,
                                    axisAlignment: 0.0,
                                    child: child,
                                  ),
                                ),
                                child: _selectedMessages.isEmpty
                                    ? SizedBox(
                                        key: const Key('empty'),
                                        height: 56,
                                      )
                                    : const SizedBox.shrink(
                                        key: Key('not_empty'),
                                      ),
                              ),
                              Expanded(
                                child: BlocBuilder<TabsBloc, TabsState>(
                                  bloc: _tabsBloc,
                                  builder: (context, state) => PageView.builder(
                                    controller: _controller,
                                    physics: _selectedMessages.isEmpty ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                                    itemCount: state.tabs.length,
                                    itemBuilder: (context, index) {
                                      final tabItem = state.tabs[index];
                                      final bloc = _messagesBlocs[tabItem.id]!;

                                      return TabItemBody(
                                        tabItem: tabItem,
                                        bloc: bloc,
                                        selectedMessagesIds: _selectedMessages.map((e) => e.id).toList(),
                                        onMessageLongPress: _onMessageLongPress,
                                        onMessageSelected: _onMessageSelected,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AnimatedSwitcher(
                            duration: Durations.short2,
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                axis: Axis.vertical,
                                axisAlignment: 0.0,
                                child: child,
                              ),
                            ),
                            child: _selectedMessages.isEmpty
                                ? BlocBuilder<TabsBloc, TabsState>(
                                    key: _scrollTabsKey,
                                    bloc: _tabsBloc,
                                    buildWhen: (previous, current) => previous.tabs != current.tabs,
                                    builder: (context, blocState) {
                                      final tabs = List.of(blocState.tabs);

                                      return ScrollTabs(
                                        tabs: tabs,
                                        pageController: _controller,
                                        initialIndex: _controller.page?.round() ?? 0,
                                      );
                                    },
                                  )
                                : const SizedBox.shrink(),
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
                        isSelectionMode: _selectedMessages.isNotEmpty,
                        selectedCount: _selectedMessages.length,
                        tabIdOfSelectedMessages: _selectedMessages.firstOrNull?.tabId,
                        tabs: tabs,
                        onDelete: _onDelete,
                        onMove: _onMove,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

mixin _ChatScreenStateMixin on State<ChatScreen> {
  final GlobalKey _scrollTabsKey = GlobalKey();

  late final PageController _controller;

  late final TabsBloc _tabsBloc;

  // #region Tabs Bloc Listener

  StreamSubscription<void>? _tabsBlocSubscription;

  /// For each tab, there is a bloc that handles the messages for that tab
  final Map<String, MessagesBloc> _messagesBlocs = {};

  /// For each tab, there is a bloc that handles the tab for that tab
  final Map<String, TabBloc> _tabsBlocs = {};

  /// Listener for each MessagesBloc
  final Map<String, StreamSubscription<void>> _messagesBlocsSubscriptions = {};

  MessagesBloc messagesBloc(String tabId) {
    if (_messagesBlocs.containsKey(tabId)) {
      return _messagesBlocs[tabId]!;
    } else {
      final messagesBloc = MessagesBloc(
        repository: context.dependencies.messagesRepository,
        initialState: MessagesState.idle(
          tabId: tabId,
          messages: const [],
        ),
      )..add(MessagesEvent.fetch());
      _messagesBlocs[tabId] = messagesBloc;
      _messagesBlocsSubscriptions[tabId] = messagesBloc.stream.listen(
        _messagesBlocListener,
      );
      return messagesBloc;
    }
  }

  void _tabsBlocListener(TabsState state) {
    final currentTabIds = _tabsBlocs.keys.toList();
    final newTabIds = state.tabs.map((tab) => tab.id).toList();

    // Remove tabs that are no longer present
    for (final tabId in currentTabIds) {
      if (!newTabIds.contains(tabId)) {
        _messagesBlocsSubscriptions[tabId]?.cancel();
        _messagesBlocs[tabId]?.close();
        _tabsBlocs[tabId]?.close();
        _messagesBlocs.remove(tabId);
        _tabsBlocs.remove(tabId);
      }
    }

    // Add new tabs
    for (final tabId in newTabIds) {
      if (!_messagesBlocs.containsKey(tabId)) {
        _messagesBlocs[tabId] = messagesBloc(tabId);

        _tabsBlocs[tabId] = _tabsBlocs[tabId] ??
            TabBloc(
              repository: context.dependencies.tabsRepository,
              initialState: TabState.idle(
                tabItem: state.tabs.firstWhere(
                  (t) => t.id == tabId,
                ),
              ),
            );
      }
    }

    if (state.createdTab != null) {
      _controller.animateToPage(
        state.tabs.indexOf(state.createdTab!),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // #endregion

  // #region Messages Bloc Listener

  void _messagesBlocListener(MessagesState state) {
    if (state is MessagesState$MessagesMoved) {
      final tabId = state.movedMessages.firstOrNull?.tabId;
      if (tabId == null) return;

      final messagesBloc = _messagesBlocs[tabId];
      if (messagesBloc == null) return;

      messagesBloc.add(
        MessagesEvent.handleMovedMessages(
          movedMessages: state.movedMessages,
        ),
      );
    }
  }

  // #endregion

  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // #region Lifecycle

  @override
  void initState() {
    super.initState();

    _tabsBloc = context.dependencies.tabsBloc
      ..add(
        TabsEvent.fetchTabs(),
      );

    _tabsBlocSubscription = _tabsBloc.stream.listen(
      _tabsBlocListener,
    );

    _controller = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();

    _tabsBlocSubscription?.cancel();

    for (final bloc in _messagesBlocs.values) {
      bloc.close();
    }
    for (final bloc in _tabsBlocs.values) {
      bloc.close();
    }

    super.dispose();
  }

  // #endregion

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;
    final page = _controller.page?.round();
    if (page == null) return;

    final currentTab = _tabsBloc.state.tabs[page];

    final message = Message(
      text: _textController.text,
      createdAt: DateTime.now(),
      tabId: currentTab.id,
    );

    final bloc = _messagesBlocs[message.tabId]!;
    _textController.clear();

    bloc.add(MessagesEvent.send(message: message));
  }

  // #region Editing Mode

  void _disableEditingMode() => setState(() => _selectedMessages = []);

  List<Message> _selectedMessages = [];

  void _onMessageLongPress(Message message) => setState(() => _selectedMessages = [
        message,
      ]);

  void _onMessageSelected(Message message) {
    if (_selectedMessages.isEmpty) return;

    List<Message> selectedMessages = List.of(_selectedMessages);

    if (selectedMessages.contains(message)) {
      selectedMessages.remove(message);
    } else {
      selectedMessages.add(message);
    }

    setState(() => _selectedMessages = selectedMessages);
  }

  void _onDelete() {
    if (_selectedMessages.isEmpty) return;

    final bloc = _messagesBlocs[_selectedMessages.first.tabId];
    bloc?.add(
      MessagesEvent.deleteMessages(
        messages: _selectedMessages,
      ),
    );

    setState(() => _selectedMessages = []);
  }

  void _onMove(String tabId) {
    if (_selectedMessages.isEmpty) return;

    final bloc = _messagesBlocs[_selectedMessages.first.tabId];
    bloc?.add(
      MessagesEvent.moveMessages(
        messages: _selectedMessages,
        toTabId: tabId,
      ),
    );

    setState(() => _selectedMessages = []);
  }

  // #endregion
}

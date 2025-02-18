import 'package:flutter/material.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_bar.dart';
import '../widgets/scroll_tabs.dart';
import '../widgets/header.dart';
import '../widgets/side_menu.dart';
import '../models/message.dart';
import '../services/storage_service.dart';
import '../managers/message_manager.dart';
import '../managers/tab_manager.dart';
import '../controllers/custom_page_controller.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late final MessageManager _messageManager;
  late final TabManager _tabManager;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  double? _dragStartX;

  @override
  void initState() {
    super.initState();
    _messageManager = MessageManager(StorageService());
    _tabManager = TabManager(
      pageController: CustomPageController(),
    );

    _messageManager.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final message = Message(
      text: _textController.text,
      isMe: true,
      timestamp: DateTime.now(),
      category: _tabManager.currentCategory,
    );

    _textController.clear();
    await _messageManager.sendMessage(message);
    setState(() {});

    final controller =
        _tabManager.scrollControllers[_tabManager.currentCategory];
    if (controller?.hasClients ?? false) {
      await controller!.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessageList(MessageCategory category) {
    final messages = _messageManager.messagesByCategory[category]!;

    if (messages.isEmpty && !_messageManager.isLoading[category]!) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tabManager.tabs[category.index].emoji,
              style: TextStyle(
                fontSize: 48,
                fontFamily: GoogleFonts.inter().fontFamily,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Text(
                  _tabManager.tabs[category.index].title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.getPrimaryText(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    fontFamily: GoogleFonts.inter().fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Напишите первую заметку',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.getSecondaryText(context),
                    fontSize: 17,
                    letterSpacing: 0.2,
                    fontFamily: GoogleFonts.inter().fontFamily,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent * 0.8) {
            _messageManager.loadMoreMessages(category);
          }
        }
        return false;
      },
      child: ListView.builder(
        key: PageStorageKey(category),
        controller: _tabManager.scrollControllers[category],
        reverse: true,
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        clipBehavior: Clip.none,
        itemCount:
            messages.length + (_messageManager.isLoading[category]! ? 1 : 0),
        itemBuilder: (context, index) {
          final messageIndex = messages.length - 1 - index;

          if (messageIndex < 0) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return MessageBubble(
            message: messages[messageIndex],
            isSelectionMode: _messageManager.isSelectionMode,
            isSelected: _messageManager.selectedMessages
                .contains(messages[messageIndex]),
            onLongPress: () {
              setState(() {
                _messageManager.toggleSelectionMode();
                _messageManager.toggleMessageSelection(messages[messageIndex]);
              });
            },
            onSelect: () {
              setState(() {
                _messageManager.toggleMessageSelection(messages[messageIndex]);
              });
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.getPrimaryBackground(context),
        drawer: SideMenu(
          tabs: _tabManager.tabs,
          selectedIndex: _tabManager.selectedTabIndex,
          onTabSelected: (index) {
            print('🔵 ChatScreen: onTabSelected with index $index');
            print(
                '🔵 ChatScreen: current tab index before: ${_tabManager.selectedTabIndex}');
            _tabManager.handleTabSelection(index, fromDrawer: true);
            print(
                '🔵 ChatScreen: current tab index after: ${_tabManager.selectedTabIndex}');
            setState(() {});
          },
        ),
        drawerEnableOpenDragGesture: false,
        body: SafeArea(
          child: GestureDetector(
            onHorizontalDragStart: (details) {
              if (_tabManager.selectedTabIndex == 0) {
                _dragStartX = details.globalPosition.dx;
              }
            },
            onHorizontalDragUpdate: (details) {
              if (_tabManager.selectedTabIndex == 0 &&
                  _dragStartX != null &&
                  details.globalPosition.dx - _dragStartX! > 50) {
                _dragStartX = null;
                Scaffold.of(context).openDrawer();
              }
            },
            onHorizontalDragEnd: (_) {
              _dragStartX = null;
            },
            child: Column(
              children: [
                Builder(
                  builder: (context) => Header(
                    onMenuPressed: () {
                      _focusNode.unfocus();
                      Scaffold.of(context).openDrawer();
                    },
                    isSelectionMode: _messageManager.isSelectionMode,
                    onExitSelectionMode: () {
                      setState(() {
                        _messageManager.toggleSelectionMode();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _tabManager.pageController,
                        itemCount: MessageCategory.values.length,
                        onPageChanged: (index) {
                          setState(() {
                            _tabManager.selectedTabIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final category = MessageCategory.values[index];
                          return _buildMessageList(category);
                        },
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        top: _messageManager.isSelectionMode ? -56 : 0,
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _messageManager.isSelectionMode ? 0 : 1,
                          child: ScrollTabs(
                            tabs: _tabManager.tabs,
                            selectedIndex: _tabManager.selectedTabIndex,
                            onTabSelected: (index) => setState(() {
                              _tabManager.handleTabSelection(index);
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InputBar(
                  controller: _textController,
                  focusNode: _focusNode,
                  onSendPressed: _sendMessage,
                  onAttachPressed: () {},
                  hintText: 'Новая заметка...',
                  isSelectionMode: _messageManager.isSelectionMode,
                  selectedCount: _messageManager.selectedMessages.length,
                  onDelete: () async {
                    for (var message in _messageManager.selectedMessages) {
                      await _messageManager.deleteMessage(message);
                    }
                    setState(() {
                      _messageManager.toggleSelectionMode();
                    });
                  },
                  onMove: (category) async {
                    for (var message in _messageManager.selectedMessages) {
                      await _messageManager.moveMessage(message, category);
                    }
                    setState(() {
                      _messageManager.toggleSelectionMode();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    _tabManager.dispose();
    super.dispose();
  }
}

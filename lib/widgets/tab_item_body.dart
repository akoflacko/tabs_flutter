import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabs_test/bloc/messages_bloc.dart';
import 'package:tabs_test/models/message.dart';
import 'package:tabs_test/models/tab_item.dart';
import 'package:tabs_test/theme/app_colors.dart';
import 'package:tabs_test/widgets/message_bubble.dart';

/// {@template tab_item_body}
/// TabItemBody widget.
/// {@endtemplate}
class TabItemBody extends StatefulWidget {
  /// {@macro tab_item_body}
  const TabItemBody({
    required this.tabItem,
    required this.bloc,
    super.key, // ignore: unused_element
  });

  final TabItem tabItem;

  /// Лучше передавать через Provider/InheritedWidget
  final MessagesBloc bloc;

  @override
  State<TabItemBody> createState() => _TabItemBodyState();
}

/// State for widget MessagesListView.
class _TabItemBodyState extends State<TabItemBody> {
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MessagesBloc, MessagesState>(
        bloc: widget.bloc,
        builder: (context, state) {
          if (state.isProcessing && state.messages.isEmpty) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          if (state.error != null && state.messages.isEmpty) {
            final errorString = Error.safeToString(state.error);

            return Center(
              child: Text(
                errorString,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            );
          }

          if (state.messages.isEmpty) {
            return Column(
              children: [
                Text(
                  widget.tabItem.title,
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
            );
          }

          return _MessagesListView(
            tabItem: widget.tabItem,
            messages: state.messages.reversed.toList(),
          );
        },
      );
}

/// {@template messages_list_view}
/// _MessagesListView widget.
/// {@endtemplate}
class _MessagesListView extends StatefulWidget {
  /// {@macro messages_list_view}
  const _MessagesListView({
    required this.tabItem,
    required this.messages,
    super.key, // ignore: unused_element
  });

  final TabItem tabItem;

  final List<Message> messages;

  @override
  State<_MessagesListView> createState() => __MessagesListViewState();
}

/// State for widget _MessagesListView.
class __MessagesListViewState extends State<_MessagesListView> {
  final ScrollController _scrollController = ScrollController();

  /* #region Lifecycle */

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  /* #endregion */

  @override
  Widget build(BuildContext context) => ListView.builder(
        key: PageStorageKey(widget.tabItem.id),
        itemCount: widget.messages.length,
        reverse: true,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final message = widget.messages[index];

          return MessageBubble(
            message: message,
            isSelectionMode: false,
            isSelected: false,
            onLongPress: () {},
            onSelect: () {},
          );
        },
      );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabs_test/bloc/create_tab_bloc.dart';
import 'package:tabs_test/bloc/tabs_bloc.dart';
import 'package:tabs_test/models/tab_item.dart';
import 'package:tabs_test/theme/app_colors.dart';
import 'package:tabs_test/widgets/dependencies_scope.dart';
import 'package:tabs_test/widgets/side_menu_tile_wrapper.dart';
import 'package:uuid/uuid.dart';

/// {@template create_tab_input}
/// CreateTabInput widget.
/// {@endtemplate}
class CreateTabInput extends StatefulWidget {
  /// {@macro create_tab_input}
  const CreateTabInput({
    this.onFocusChanged,
    this.onTabCreated,
    super.key, // ignore: unused_element
  });

  final ValueChanged<bool>? onFocusChanged;

  final ValueChanged<TabItem>? onTabCreated;

  @override
  State<CreateTabInput> createState() => _CreateTabInputState();
}

/// State for widget CreateTabInput.
class _CreateTabInputState extends State<CreateTabInput> {
  String? _selectedEmoji;
  bool _canDeleteEmoji = true;
  String? _lastText;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  final _keyboardListenerFocusNode = FocusNode();

  late final Listenable _listenable;

  late final CreateTabBloc _bloc;

  StreamSubscription<void>? _blocSubscription;

  void _blocListener(CreateTabState state) {
    if (state is CreateTabState$Successful) {
      _controller.clear();
      setState(() => _selectedEmoji = null);

      final tabsBloc = context.dependencies.tabsBloc;
      tabsBloc.add(TabsEvent.tabCreated(tabItem: state.tabItem));

      widget.onTabCreated?.call(state.tabItem);
    }
  }

  // #region Text Editing Controller Listener

  void _textEditingControllerListener() {
    final text = _controller.text;
    print('\n🔵 -------- TextField Event --------');
    print('🔵 Текущий текст: "$text"');
    print('🔵 Есть эмодзи: ${_selectedEmoji != null}');
    print('🔵 Должна показываться галочка: ${text.isNotEmpty}');

    if (text.isEmpty && _lastText?.isNotEmpty == true) {
      _canDeleteEmoji = false;
      print('🔵 Блокируем удаление эмодзи на 200мс');
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _canDeleteEmoji = true);
          print('🔵 Разрешаем удаление эмодзи');
        }
      });
    } else if (text.isNotEmpty && _selectedEmoji == null) {
      final isEmojiResult = isEmoji(text);
      if (isEmojiResult) {
        print('🔵 Обнаружена эмодзи в тексте: "$text"');
        final emoji = text;
        _controller.clear();
        setState(() {
          _selectedEmoji = emoji;
          print('🔵 Установлена эмодзи: $_selectedEmoji');
        });
      }
    }

    _lastText = text;
    setState(() {});
    print('🔵 --------------------------------\n');
  }

  bool isEmoji(String text) {
    if (text.isEmpty) {
      print('🔵 isEmoji: текст пустой');
      return false;
    }

    final runes = text.runes.toList();
    print('🔵 isEmoji: проверяем текст: "$text"');
    print('🔵 isEmoji: количество рун: ${runes.length}');
    print('🔵 isEmoji: коды: ${runes.map((r) => '0x${r.toRadixString(16)}').join(", ")}');

    // Проверяем диапазоны эмодзи
    for (final rune in runes) {
      final isInRange = (rune >= 0x1F300 && rune <= 0x1F9FF) || // Основные эмодзи
          (rune >= 0x2600 && rune <= 0x26FF) || // Разные символы
          (rune >= 0x2700 && rune <= 0x27BF) || // Dingbats
          (rune >= 0xFE00 && rune <= 0xFE0F); // Вариации

      print('🔵 isEmoji: руна 0x${rune.toRadixString(16)} ${isInRange ? 'в диапазоне' : 'не в диапазоне'}');

      if (!isInRange) {
        print('🔵 isEmoji: не эмодзи');
        return false;
      }
    }

    print('🔵 isEmoji: это эмодзи');
    return true;
  }

  // #endregion

  void _focusListener() {
    final hasFocus = _focusNode.hasFocus;
    widget.onFocusChanged?.call(hasFocus);
  }

  /* #region Lifecycle */
  @override
  void initState() {
    super.initState();

    final repository = context.dependencies.tabsRepository;
    _bloc = CreateTabBloc(repository: repository, initialState: const CreateTabState.idle());

    _controller.addListener(_textEditingControllerListener);

    _focusNode.addListener(_focusListener);

    _listenable = Listenable.merge([_focusNode, _controller, _keyboardListenerFocusNode]);

    _blocSubscription = _bloc.stream.listen(_blocListener);
  }

  @override
  void dispose() {
    _controller.removeListener(_textEditingControllerListener);
    _controller.dispose();

    _focusNode.removeListener(_focusListener);
    _focusNode.dispose();

    _keyboardListenerFocusNode.dispose();

    _blocSubscription?.cancel();
    _bloc.close();

    super.dispose();
  }
  /* #endregion */

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controller.text.isEmpty &&
        _selectedEmoji != null &&
        _canDeleteEmoji) {
      setState(() {
        _selectedEmoji = null;
      });
    }
  }

  void _createTab() {
    final title = _controller.text;

    if (title.isEmpty) return;

    final newTab = TabItem(id: const Uuid().v4(), title: title, emoji: _selectedEmoji, createdAt: DateTime.now());

    _controller.clear();
    setState(() => _selectedEmoji = null);

    _bloc.add(CreateTabEvent(tabItem: newTab));

    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<CreateTabBloc, CreateTabState>(
        bloc: _bloc,
        builder: (context, state) => ListenableBuilder(
          listenable: _listenable,
          builder: (context, _) => SideMenuTileWrapper(
            backgroundColor: _focusNode.hasFocus ? AppColors.getSecondaryBackground(context) : AppColors.getPrimaryBackground(context),
            child: KeyboardListener(
              focusNode: _keyboardListenerFocusNode,
              onKeyEvent: _handleKeyEvent,
              child: TextField(
                controller: _controller,
                enabled: !state.isProcessing,
                focusNode: _focusNode,
                onTapOutside: (_) => _focusNode.unfocus(),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  prefixIconConstraints: const BoxConstraints(maxWidth: 52),
                  prefixIcon: _selectedEmoji != null || (!_focusNode.hasFocus && _controller.text.isEmpty)
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8, left: 20),
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: Center(
                              child: _selectedEmoji != null
                                  ? Text(_selectedEmoji!, style: TextStyle(fontSize: 20, fontFamily: GoogleFonts.inter().fontFamily))
                                  : DecoratedBox(
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                      child: const Center(child: Icon(Icons.add, size: 18, color: Colors.black)),
                                    ),
                            ),
                          ),
                        )
                      : null,
                  suffixIcon: _controller.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8, right: 20),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Center(
                              child: InkWell(
                                onTap: state.isProcessing ? null : () => _createTab(),
                                child: Builder(
                                  builder: (context) => SvgPicture.asset(
                                    'assets/icons/tab_check.svg',
                                    width: 24,
                                    height: 24,
                                    colorFilter: ColorFilter.mode(AppColors.getSecondaryText(context), BlendMode.srcIn),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Make a Tab',
                  hintStyle: TextStyle(
                    color: AppColors.getSecondaryText(context),
                    fontSize: 17,
                    letterSpacing: 0.2,
                    fontFamily: GoogleFonts.inter().fontFamily,
                  ),
                ),
                onSubmitted: state.isProcessing ? null : (_) => _createTab(),
              ),
            ),
          ),
        ),
      );
}

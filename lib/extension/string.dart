extension StringX on String {
  bool get isEmoji {
    if (isEmpty) return false;

    for (final rune in runes) {
      final isInRange = (rune >= 0x1F300 && rune <= 0x1F9FF) || // Основные эмодзи
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

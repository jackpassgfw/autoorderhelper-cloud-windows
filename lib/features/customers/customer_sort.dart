import 'package:characters/characters.dart';
import 'package:lpinyin/lpinyin.dart';

String buildCustomerNameSortKey(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final hasChinese = _containsChinese(trimmed);
  final hasAsciiAlphaNumeric = _containsAsciiAlphaNumeric(trimmed);
  if (hasAsciiAlphaNumeric) {
    final nonChinese = _normalizeSpaces(_stripChinese(trimmed));
    final sortValue = nonChinese.isEmpty ? trimmed : nonChinese;
    return '0_${sortValue.toLowerCase()}';
  }
  if (hasChinese) {
    final pinyin = PinyinHelper.getPinyin(
      trimmed,
      separator: '',
      format: PinyinFormat.WITHOUT_TONE,
    );
    return '1_${pinyin.toLowerCase()}';
  }
  final fallback = PinyinHelper.getPinyin(
    trimmed,
    separator: '',
    format: PinyinFormat.WITHOUT_TONE,
  );
  return '2_${fallback.toLowerCase()}';
}

int compareCustomerNamesAsc(String a, String b) {
  final aKey = buildCustomerNameSortKey(a);
  final bKey = buildCustomerNameSortKey(b);
  final keyCompare = aKey.compareTo(bKey);
  if (keyCompare != 0) return keyCompare;
  final aDisplay = formatCustomerDisplayName(a).toLowerCase();
  final bDisplay = formatCustomerDisplayName(b).toLowerCase();
  final displayCompare = aDisplay.compareTo(bDisplay);
  if (displayCompare != 0) return displayCompare;
  return a.toLowerCase().compareTo(b.toLowerCase());
}

String formatCustomerDisplayName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final english = _normalizeSpaces(_stripChinese(trimmed));
  final chinese = _normalizeSpaces(_extractChinese(trimmed));
  if (english.isEmpty) {
    return chinese.isEmpty ? trimmed : chinese;
  }
  if (chinese.isEmpty) return english;
  return '$english $chinese';
}

String _normalizeSpaces(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String _stripChinese(String value) {
  final buffer = StringBuffer();
  for (final char in value.characters) {
    if (!ChineseHelper.isChinese(char)) {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

String _extractChinese(String value) {
  final buffer = StringBuffer();
  for (final char in value.characters) {
    if (ChineseHelper.isChinese(char)) {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

bool _containsAsciiAlphaNumeric(String value) {
  for (final char in value.characters) {
    final code = char.codeUnitAt(0);
    if ((code >= 48 && code <= 57) ||
        (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122)) {
      return true;
    }
  }
  return false;
}

bool _containsChinese(String value) {
  for (final char in value.characters) {
    if (ChineseHelper.isChinese(char)) return true;
  }
  return false;
}

class SuggestionItem {
  final String display;
  final bool isGeneric; // true = generic name, false = trade name
  final String query;

  const SuggestionItem({
    required this.display,
    required this.isGeneric,
    required this.query,
  });
}

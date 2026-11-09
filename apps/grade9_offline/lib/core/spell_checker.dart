/// Small, deterministic offline spelling helper. This is a suggestion engine,
/// not a full Urdu morphological spell-checker.
class SpellSuggestion {
  const SpellSuggestion(this.word, this.distance);
  final String word;
  final int distance;
}

class OfflineSpellChecker {
  OfflineSpellChecker(Iterable<String> words)
      : _words = words.map(_normalize).where((w) => w.isNotEmpty).toSet();

  final Set<String> _words;

  bool contains(String word) => _words.contains(_normalize(word));

  List<SpellSuggestion> suggest(String input, {int limit = 3, int maxDistance = 2}) {
    final target = _normalize(input);
    if (target.isEmpty || contains(target) || limit <= 0) return const [];

    final matches = <SpellSuggestion>[];
    for (final candidate in _words) {
      if ((candidate.length - target.length).abs() > maxDistance) continue;
      final distance = levenshtein(target, candidate, cutoff: maxDistance);
      if (distance <= maxDistance) {
        matches.add(SpellSuggestion(candidate, distance));
      }
    }
    matches.sort((a, b) {
      final byDistance = a.distance.compareTo(b.distance);
      return byDistance != 0 ? byDistance : a.word.compareTo(b.word);
    });
    return matches.take(limit).toList(growable: false);
  }

  static String _normalize(String value) => value.trim().toLowerCase();

  static int levenshtein(String a, String b, {int? cutoff}) {
    if (a == b) return 0;
    if (a.isEmpty) return b.runes.length;
    if (b.isEmpty) return a.runes.length;

    final left = a.runes.toList(growable: false);
    final right = b.runes.toList(growable: false);
    if (cutoff != null && (left.length - right.length).abs() > cutoff) {
      return cutoff + 1;
    }

    var previous = List<int>.generate(right.length + 1, (i) => i);
    for (var i = 1; i <= left.length; i++) {
      final current = List<int>.filled(right.length + 1, 0);
      current[0] = i;
      var rowMinimum = current[0];
      for (var j = 1; j <= right.length; j++) {
        final cost = left[i - 1] == right[j - 1] ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + cost;
        final value = [deletion, insertion, substitution].reduce(
          (x, y) => x < y ? x : y,
        );
        current[j] = value;
        if (value < rowMinimum) rowMinimum = value;
      }
      if (cutoff != null && rowMinimum > cutoff) return cutoff + 1;
      previous = current;
    }
    return previous.last;
  }
}

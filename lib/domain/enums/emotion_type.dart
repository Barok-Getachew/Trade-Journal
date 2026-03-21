enum EmotionType {
  calm('Calm', 'neutral'),
  confident('Confident', 'positive'),
  focused('Focused', 'positive'),
  excited('Excited / FOMO', 'negative'),
  fearful('Fearful', 'negative'),
  greedy('Greedy', 'negative'),
  frustrated('Frustrated', 'negative'),
  neutral('Neutral', 'neutral'),
  impatient('Impatient', 'negative'),
  undisciplined('Undisciplined', 'negative');

  const EmotionType(this.label, this.category);
  final String label;
  final String category;

  bool get isPositive => category == 'positive';
  bool get isNegative => category == 'negative';

  static EmotionType fromString(String value) {
    return EmotionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EmotionType.neutral,
    );
  }
}

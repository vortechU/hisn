/// A preset for the Tasbih counter, e.g. "SubhanAllah" with a target of 33.
class Dhikr {
  const Dhikr({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.target,
  });

  final String id;
  final String arabic;
  final String transliteration;
  final String translation;

  /// The number of repetitions that completes one set.
  final int target;

  factory Dhikr.fromJson(Map<String, dynamic> json) {
    return Dhikr(
      id: json['id'] as String,
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      translation: json['translation'] as String,
      target: json['target'] as int,
    );
  }
}

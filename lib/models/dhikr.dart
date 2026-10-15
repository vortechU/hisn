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

  String translationFor(String langCode) =>
      langCode == 'ur' ? (_urdu[id] ?? translation) : translation;

  static const _urdu = {
    'subhanallah': 'اللہ پاک ہے',
    'alhamdulillah': 'تمام تعریفیں اللہ کے لیے ہیں',
    'allahu_akbar': 'اللہ سب سے بڑا ہے',
    'tahlil': 'اللہ کے سوا کوئی معبود نہیں',
    'istighfar': 'میں اللہ سے بخشش مانگتا ہوں',
    'subhanallah_bihamdihi': 'اللہ پاک ہے اور اسی کی حمد ہے',
    'hawqala': 'اللہ کے بغیر نہ کوئی طاقت ہے نہ قوت',
    'salawat': 'اے اللہ! محمد پر درود بھیج',
  };

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

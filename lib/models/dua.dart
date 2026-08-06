/// A single supplication (dua / dhikr) with its Arabic text, transliteration,
/// translation, and source reference.
class Dua {
  /// The category id used for duas the user adds themselves.
  static const String customCategoryId = 'custom';

  const Dua({
    required this.id,
    required this.categoryId,
    required this.title,
    this.titleArabic,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.reference,
    this.repeat = 1,
    this.virtue,
    this.localizedTranslations = const {},
    this.localizedVirtues = const {},
    this.localizedReferences = const {},
  });

  final String id;
  final String categoryId;
  final String title;

  /// Arabic name of the dua, shown when the app is in Arabic. Falls back to
  /// [title] when absent.
  final String? titleArabic;

  final String arabic;
  final String transliteration;
  final String translation;

  /// Where the dua comes from (Qur'an verse or hadith collection).
  final String reference;

  /// How many times the dua is recited. `1` for most.
  final int repeat;

  /// Optional reward / benefit (fadl) of reciting the dua.
  final String? virtue;

  /// Per-language overrides of [translation], keyed by language code ('id',
  /// 'ar', …). Sourced from `assets/data/duas.<lang>.json` and attached at load
  /// time. The Arabic dua text itself is never localized — only what is said
  /// about it.
  final Map<String, String> localizedTranslations;

  /// Per-language overrides of [virtue], keyed by language code.
  final Map<String, String> localizedVirtues;

  /// Per-language overrides of [reference], keyed by language code.
  ///
  /// The source is a proper noun, not prose — "Sahih al-Bukhari 6306" is a
  /// Latin transliteration of a book whose name an Arabic reader knows as
  /// "صحيح البخاري ٦٣٠٦". It is overlaid rather than translated.
  final Map<String, String> localizedReferences;

  /// The translation (meaning) for [langCode], falling back to the English
  /// [translation] when no localized version exists.
  String translationFor(String langCode) =>
      localizedTranslations[langCode] ?? translation;

  /// The virtue for [langCode], falling back to the base [virtue].
  String? virtueFor(String langCode) =>
      localizedVirtues[langCode] ?? virtue;

  /// The source for [langCode], falling back to the base [reference].
  String referenceFor(String langCode) =>
      localizedReferences[langCode] ?? reference;

  /// A copy with localized translation/virtue/reference overlays attached.
  Dua withLocalized({
    Map<String, String>? translations,
    Map<String, String>? virtues,
    Map<String, String>? references,
  }) =>
      Dua(
        id: id,
        categoryId: categoryId,
        title: title,
        titleArabic: titleArabic,
        arabic: arabic,
        transliteration: transliteration,
        translation: translation,
        reference: reference,
        repeat: repeat,
        virtue: virtue,
        localizedTranslations: translations ?? localizedTranslations,
        localizedVirtues: virtues ?? localizedVirtues,
        localizedReferences: references ?? localizedReferences,
      );

  /// True for duas the user added themselves (kept in [CustomDuaService]).
  bool get isCustom => categoryId == customCategoryId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'title': title,
        if (titleArabic != null) 'titleArabic': titleArabic,
        'arabic': arabic,
        'transliteration': transliteration,
        'translation': translation,
        'reference': reference,
        'repeat': repeat,
        if (virtue != null) 'virtue': virtue,
      };

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      title: json['title'] as String,
      titleArabic: json['titleArabic'] as String?,
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      translation: json['translation'] as String,
      reference: json['reference'] as String,
      repeat: (json['repeat'] as int?) ?? 1,
      virtue: json['virtue'] as String?,
    );
  }
}

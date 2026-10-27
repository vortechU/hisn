/// A grouping of duas, e.g. "Morning Adhkar" or "Before Sleep".
class DuaCategory {
  /// Top-level sections the categories are grouped under on the home grid.
  static const groupDaily = 'daily_routine';
  static const groupSituational = 'situational';

  const DuaCategory({
    required this.id,
    required this.title,
    required this.titleArabic,
    required this.subtitle,
    this.subtitleArabic,
    this.group = groupSituational,
    this.localizedTitles = const {},
    this.localizedSubtitles = const {},
  });

  final String id;
  final String title;
  final String titleArabic;
  final String subtitle;

  /// Arabic descriptor, shown when the app is in Arabic. Falls back to
  /// [subtitle] when absent.
  final String? subtitleArabic;

  /// Which home-grid section this category belongs to ([groupDaily] or
  /// [groupSituational]). Defaults to situational for any untagged category.
  final String group;

  /// The title in the active language.
  String titleFor(bool arabic) => arabic ? titleArabic : title;

  /// The subtitle in the active language.
  String subtitleFor(bool arabic) =>
      arabic ? (subtitleArabic ?? subtitle) : subtitle;

  final Map<String, String> localizedTitles;
  final Map<String, String> localizedSubtitles;

  String titleForLang(String code) =>
      localizedTitles[code] ?? titleFor(code == 'ar');

  String subtitleForLang(String code) =>
      localizedSubtitles[code] ?? subtitleFor(code == 'ar');

  DuaCategory withLocalized({
    required Map<String, String> titles,
    required Map<String, String> subtitles,
  }) => DuaCategory(
    id: id,
    title: title,
    titleArabic: titleArabic,
    subtitle: subtitle,
    subtitleArabic: subtitleArabic,
    group: group,
    localizedTitles: titles,
    localizedSubtitles: subtitles,
  );

  factory DuaCategory.fromJson(Map<String, dynamic> json) {
    return DuaCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      titleArabic: json['titleArabic'] as String,
      subtitle: json['subtitle'] as String,
      subtitleArabic: json['subtitleArabic'] as String?,
      group: json['group'] as String? ?? groupSituational,
    );
  }
}

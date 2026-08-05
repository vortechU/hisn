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

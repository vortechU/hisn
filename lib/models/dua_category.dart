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

  String titleForLang(String code) =>
      code == 'ur' ? (_urdu[id]?.$1 ?? title) : titleFor(code == 'ar');

  String subtitleForLang(String code) =>
      code == 'ur' ? (_urdu[id]?.$2 ?? subtitle) : subtitleFor(code == 'ar');

  static const _urdu = <String, (String, String)>{
    'morning': ('صبح کے اذکار', 'فجر کے بعد طلوع آفتاب تک پڑھے جاتے ہیں'),
    'evening': ('شام کے اذکار', 'عصر کے بعد غروب آفتاب تک پڑھے جاتے ہیں'),
    'after_salah': ('نماز کے بعد', 'فرض نمازوں کے بعد پڑھے جاتے ہیں'),
    'waking': ('بیدار ہونے پر', 'نیند سے بیدار ہونے کے بعد'),
    'sleep': ('سونے سے پہلے', 'بستر پر جاتے وقت پڑھے جاتے ہیں'),
    'daily': ('روزمرہ زندگی', 'کھانا، گھر سے نکلنا اور دیگر مواقع'),
    'forgiveness': ('استغفار', 'توبہ کے ساتھ اللہ کی طرف رجوع'),
    'distress': ('پریشانی اور غم', 'فکر، غم یا تنگی کے وقت'),
    'travel': ('سفر', 'روانگی، قیام اور واپسی'),
    'mosque': ('مسجد اور اذان', 'اذان، مسجد میں داخلہ اور نکلنا'),
  };

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

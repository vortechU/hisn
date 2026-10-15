/// The former three-surah entries now have one card per surah. Keep this
/// mapping for installed apps and backups made before the content was split.
const splitDuaIds = <String, List<String>>{
  'morning_muawwidhat': ['morning_ikhlas', 'morning_falaq', 'morning_nas'],
  'evening_muawwidhat': ['evening_ikhlas', 'evening_falaq', 'evening_nas'],
  'salah_muawwidhat': ['salah_ikhlas', 'salah_falaq', 'salah_nas'],
  'sleep_three_quls': ['sleep_ikhlas', 'sleep_falaq', 'sleep_nas'],
};

Set<String> expandLegacyDuaIds(Iterable<String> ids) => {
  for (final id in ids) ...splitDuaIds[id] ?? [id],
};

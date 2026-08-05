import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/dua_repository.dart';
import 'data/quran_repository.dart';
import 'services/backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = DuaRepository();
  final quran = QuranRepository();
  final prefs = await SharedPreferences.getInstance();

  // Before anything reads its state: if a restore was interrupted last run,
  // undo the half of it that landed. Every service loads from prefs in its
  // constructor, so this has to settle first.
  await const BackupService().recoverInterruptedRestore(prefs);

  await Future.wait([repository.load(), quran.loadIndex()]);

  runApp(DuaApp(repository: repository, quran: quran, prefs: prefs));
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/dua_repository.dart';
import 'data/quran_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = DuaRepository();
  final quran = QuranRepository();
  final prefs = await SharedPreferences.getInstance();
  await Future.wait([repository.load(), quran.loadIndex()]);

  runApp(DuaApp(repository: repository, quran: quran, prefs: prefs));
}

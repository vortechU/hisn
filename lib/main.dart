import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/dua_repository.dart';
import 'data/quran_repository.dart';
import 'services/adhkar_audio_handler.dart';
import 'services/adhkar_audio_library.dart';
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

  final loaded = await Future.wait([
    repository.load(),
    quran.loadIndex(),
    AdhkarAudioLibrary.load(),
  ]);
  final audioLibrary = loaded[2] as AdhkarAudioLibrary;

  // The media session is a process-wide singleton — [AudioService.init] can
  // only be called once — so it is built here rather than in the provider
  // tree, which is discarded and rebuilt whenever a backup is restored.
  // Skipped entirely when nothing is recorded: no recitation, no session.
  final audio = audioLibrary.hasAnyAudio ? await initAdhkarAudio() : null;

  runApp(DuaApp(
    repository: repository,
    quran: quran,
    prefs: prefs,
    // The two travel together on purpose. Every listening affordance is gated
    // on the library having something in it, and each one then reaches for the
    // handler — so a library that survived a failed session init would offer a
    // button with nothing behind it.
    audioLibrary: audio == null ? AdhkarAudioLibrary.empty() : audioLibrary,
    audio: audio,
  ));
}

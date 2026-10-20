import 'dart:io';

import 'package:dua_app/services/adhan_audio.dart';
import 'package:dua_app/services/backup_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  // The preview player is built with the service and reaches for its plugin.
  const audioChannels = [
    MethodChannel('xyz.luan/audioplayers.global'),
    MethodChannel('xyz.luan/audioplayers'),
  ];
  setUpAll(() {
    for (final channel in audioChannels) {
      messenger.setMockMethodCallHandler(channel, (_) async => null);
    }
  });
  tearDownAll(() {
    for (final channel in audioChannels) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hisn_adhan_voice');
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<AdhanAudioService> service() async => AdhanAudioService(
    await SharedPreferences.getInstance(),
    storageDir: () async => tmp,
  );

  // Like the Android picker: byte-backed, and XFile reads the name off path.
  XFile audio(String name, int size) => XFile.fromData(
    Uint8List(size)..fillRange(0, size, 7),
    name: name,
    path: name,
  );

  test('defaults to the first bundled voice', () async {
    final adhan = await service();
    expect(adhan.voiceId, 'default');
    expect(adhan.effectiveVoiceId, 'default');
    expect(AdhanAudioService.assetPath, 'audio/adhan1.mp3');
  });

  test('importing copies the file into app storage and selects it', () async {
    final adhan = await service();
    expect(
      await adhan.importCustom(audio('My Adhan.MP3', 1024)),
      CustomAdhanResult.imported,
    );
    expect(adhan.voiceId, AdhanAudioService.customVoiceId);
    expect(adhan.effectiveVoiceId, AdhanAudioService.customVoiceId);
    expect(adhan.customFileName, 'My Adhan.MP3');
    final path = adhan.customFilePath!;
    expect(path, startsWith(tmp.path));
    expect(path, endsWith('.mp3'));
    expect(File(path).lengthSync(), 1024);
  });

  test('a second import replaces the first file', () async {
    final adhan = await service();
    await adhan.importCustom(audio('one.ogg', 10));
    final first = adhan.customFilePath!;
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await adhan.importCustom(audio('two.ogg', 20));
    expect(File(first).existsSync(), isFalse);
    expect(adhan.customFileName, 'two.ogg');
    expect(Directory('${tmp.path}/adhan').listSync(), hasLength(1));
  });

  test('empty and oversized files are refused and change nothing', () async {
    final adhan = await service();
    expect(
      await adhan.importCustom(audio('empty.mp3', 0)),
      CustomAdhanResult.unreadable,
    );
    expect(
      await adhan.importCustom(
        audio('huge.mp3', AdhanAudioService.maxCustomBytes + 1),
      ),
      CustomAdhanResult.tooLarge,
    );
    expect(adhan.voiceId, 'default');
    expect(adhan.customFilePath, isNull);
  });

  test('custom without its file plays the default voice', () async {
    // What a restored backup looks like: the choice came along, the file
    // didn't (and the path key isn't backed up at all).
    SharedPreferences.setMockInitialValues({
      'adhan_sound_voice': AdhanAudioService.customVoiceId,
    });
    final adhan = await service();
    expect(adhan.voiceId, AdhanAudioService.customVoiceId);
    expect(adhan.effectiveVoiceId, 'default');
  });

  test('an unknown bundled id falls back to the default', () async {
    SharedPreferences.setMockInitialValues({'adhan_sound_voice': 'retired'});
    expect((await service()).effectiveVoiceId, 'default');
  });

  test('the voice is backed up, the device-local file path is not', () {
    expect(BackupService.isBackedUp('adhan_sound_voice'), isTrue);
    expect(BackupService.isBackedUp('adhan_custom_file'), isFalse);
    expect(BackupService.isBackedUp('adhan_custom_name'), isFalse);
  });
}

import 'package:dua_app/services/custom_dua_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers adding and editing user-created duas (the "My Duas" section).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<CustomDuaService> newService() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return CustomDuaService(prefs);
  }

  test('add then update edits in place, preserving id and position', () async {
    final service = await newService();

    final first = await service.add(arabic: 'اللهم اغفر لي', title: 'First');
    final second = await service.add(arabic: 'بسم الله', title: 'Second');

    // Newest first: [second, first].
    expect(service.count, 2);
    expect(service.duas.first.id, second.id);
    expect(service.duas.last.id, first.id);

    await service.update(
      id: first.id,
      arabic: 'اللهم اغفر لي وارحمني',
      title: 'First (fixed)',
      repeat: 3,
    );

    expect(service.count, 2, reason: 'editing must not add a new dua');
    final edited = service.duas.firstWhere((d) => d.id == first.id);
    expect(edited.id, first.id, reason: 'id is preserved');
    expect(edited.arabic, 'اللهم اغفر لي وارحمني');
    expect(edited.title, 'First (fixed)');
    expect(edited.repeat, 3);
    // Position is unchanged (still last).
    expect(service.duas.last.id, first.id);
    // The other dua is untouched.
    expect(service.duas.first.id, second.id);
  });

  test('update on an unknown id is a no-op', () async {
    final service = await newService();
    await service.add(arabic: 'اللهم اغفر لي');
    await service.update(id: 'does_not_exist', arabic: 'changed');
    expect(service.count, 1);
    expect(service.duas.single.arabic, 'اللهم اغفر لي');
  });

  test('edits persist across a reload', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = CustomDuaService(prefs);
    final dua = await service.add(arabic: 'النص الأصلي');
    await service.update(id: dua.id, arabic: 'النص المعدّل');

    // A fresh service reading the same prefs should see the edit.
    final reloaded = CustomDuaService(prefs);
    expect(reloaded.count, 1);
    expect(reloaded.duas.single.arabic, 'النص المعدّل');
  });
}

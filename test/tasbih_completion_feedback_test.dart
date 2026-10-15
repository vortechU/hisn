import 'package:dua_app/services/tasbih_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'completed target stays visible until the next recitation tap',
    () async {
      SharedPreferences.setMockInitialValues({
        'tasbih_count_subhanallah': 32,
        'tasbih_laps_subhanallah': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final controller = TasbihController(prefs);
      addTearDown(controller.dispose);

      expect(await controller.increment('subhanallah', 33), isTrue);
      expect(controller.countFor('subhanallah'), 33);
      expect(controller.lapsFor('subhanallah'), 5);
      await Future<void>.delayed(const Duration(milliseconds: 750));
      expect(controller.countFor('subhanallah'), 33);
      expect(TasbihController(prefs).countFor('subhanallah'), 33);
      expect(await controller.increment('subhanallah', 33), isFalse);
      expect(controller.countFor('subhanallah'), 1);
      expect(controller.lapsFor('subhanallah'), 5);
      for (var i = 1; i < 33; i++) {
        await controller.increment('subhanallah', 33);
      }
      expect(controller.countFor('subhanallah'), 33);
      expect(controller.lapsFor('subhanallah'), 6);
      await controller.reset('subhanallah');
      expect(controller.countFor('subhanallah'), 0);
      expect(controller.lapsFor('subhanallah'), 0);
    },
  );

  test(
    'single-repetition sets count every tap and preserve completion',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = TasbihController(prefs);
      addTearDown(controller.dispose);
      for (var i = 1; i <= 3; i++) {
        expect(await controller.increment('once', 1), isTrue);
        expect(controller.countFor('once'), 1);
        expect(controller.lapsFor('once'), i);
      }
    },
  );
}

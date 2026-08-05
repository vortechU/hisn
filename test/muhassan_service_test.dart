import 'package:dua_app/services/muhassan_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verifies the daily streak is "forgiving": completing the essential adhkar
/// fortifies the day even without the optional 100× dhikr.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<MuhassanService> newService() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return MuhassanService(prefs);
  }

  test('finishing the essentials fortifies the day; 100× dhikr is optional',
      () async {
    final m = await newService();
    // morning has two essentials + one optional 100× dua; evening one essential.
    m.setEssential({'m1', 'm2'}, {'e1'});

    expect(m.morningTotal, 2);
    expect(m.eveningTotal, 1);

    m.markCompleted('morning', 'm1');
    m.markCompleted('morning', 'm2');
    // The long 100× dua is recorded but must not affect the count.
    m.markCompleted('morning', 'm_tahlil_100');
    expect(m.morningCount, 2);
    expect(m.morningDone, isTrue);

    expect(m.eveningDone, isFalse);
    m.markCompleted('evening', 'e1');
    expect(m.eveningDone, isTrue);

    // Day is now fully fortified without ever doing the 100× dhikr.
    expect(m.fortifiedToday, isTrue);
    expect(m.streak, 1);
    expect(m.percent, 100);
  });

  test('doing only the optional 100× dhikr does not fortify the day', () async {
    final m = await newService();
    m.setEssential({'m1'}, {'e1'});
    m.markCompleted('morning', 'm_tahlil_100'); // not in the essential set
    expect(m.morningCount, 0);
    expect(m.morningDone, isFalse);
    expect(m.fortifiedToday, isFalse);
  });
}

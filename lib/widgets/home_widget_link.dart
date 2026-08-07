import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../screens/category_duas_screen.dart';
import '../screens/home_screen.dart';
import '../screens/tasbih_screen.dart';
import '../services/adhan_widget_bridge.dart';
import '../services/tasbih_controller.dart';
import '../util/app_navigator.dart';

/// The app's end of the home-screen widgets.
///
/// Two jobs, both about the boundary between a widget and the app:
///
///  * **Opening.** A widget tap names where it wants to go. This puts the app
///    there, rather than dropping the reader on the home tab to find their own
///    way to the set they just tapped.
///  * **Re-reading.** The tasbih widget writes counts into the same preference
///    store this app caches in memory. Coming back to the foreground without
///    re-reading it would mean the next tap in the app was computed from a
///    count taken before the widget's, silently undoing them.
class HomeWidgetLink extends StatefulWidget {
  const HomeWidgetLink({super.key, required this.child});

  final Widget child;

  @override
  State<HomeWidgetLink> createState() => _HomeWidgetLinkState();
}

class _HomeWidgetLinkState extends State<HomeWidgetLink>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Taps that arrive while the app is already running.
    AdhanWidgetBridge.onRoute(_open);
    // A cold launch gets here before the navigator exists, so the route waits
    // natively until there is something able to act on it.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final route = await AdhanWidgetBridge.consumeRoute();
      if (route != null && mounted) _open(route);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    context.read<TasbihController>().reload();
  }

  /// Put the app where [route] asks.
  ///
  /// Anything already stacked is dismissed first: arriving from the home screen
  /// should feel like opening the app at that place, not like landing three
  /// screens deep in wherever it was left days ago.
  void _open(String route) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    final parts = route.split(':');

    switch (parts.first) {
      case 'prayer':
        navigator.popUntil((r) => r.isFirst);
        HomeScreen.tab.value = HomeScreen.tabPrayer;
      case 'tasbih':
        navigator.popUntil((r) => r.isFirst);
        HomeScreen.tab.value = HomeScreen.tabAdhkar;
        navigator.push(
          MaterialPageRoute(builder: (_) => const TasbihScreen()),
        );
      case 'adhkar':
        // The widget names the set it was showing, so the app opens the one
        // that was tapped even if the prayer period has since turned over.
        final category = context
            .read<DuaRepository>()
            .categoryById(parts.length > 1 ? parts[1] : 'morning');
        if (category == null) return;
        navigator.popUntil((r) => r.isFirst);
        HomeScreen.tab.value = HomeScreen.tabAdhkar;
        navigator.push(
          MaterialPageRoute(
            builder: (_) => CategoryDuasScreen(category: category),
          ),
        );
      case 'home':
        navigator.popUntil((r) => r.isFirst);
        HomeScreen.tab.value = HomeScreen.tabAdhkar;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

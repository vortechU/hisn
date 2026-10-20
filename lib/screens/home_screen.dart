import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/feature_tour_controller.dart';
import '../theme/motion.dart';
import '../widgets/feature_tour_anchor.dart';
import '../widgets/feature_tour_overlay.dart';
import 'adhkar_screen.dart';
import 'prayer_qibla_screen.dart';
import 'quran_screen.dart';
import 'settings_screen.dart';

/// Root scaffold holding the four primary tabs. Tasbih and Saved are reached
/// from the toolbar inside the Adhkar tab; Qibla lives in the combined Prayer
/// & Qibla tab.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const tabAdhkar = 0;
  static const tabQuran = 1;
  static const tabPrayer = 2;
  static const tabSettings = 3;

  /// Which primary tab is showing.
  ///
  /// Held outside the state because a home-screen widget can ask for a tab from
  /// outside the widget tree entirely — see `WidgetRoutes`. Everything that
  /// changes tabs, including the navigation bar itself, goes through here, so
  /// there is only ever one answer to which tab is current.
  static final ValueNotifier<int> tab = ValueNotifier<int>(tabAdhkar);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _index = HomeScreen.tab.value;
  final _surfaceKey = GlobalKey();
  FeatureTourController? _tour;
  bool _welcomeShown = false;
  Rect? _targetRect;
  int _preparedStep = -1;
  int _preparation = 0;

  static const _tourTargets = [
    FeatureTourTarget.tasbih,
    FeatureTourTarget.quranSearch,
    FeatureTourTarget.prayerQibla,
    FeatureTourTarget.appearance,
    FeatureTourTarget.notifications,
  ];
  static const _tourTabs = [0, 1, 2, 0, 3];

  static const _tabs = [
    AdhkarScreen(),
    QuranScreen(),
    PrayerQiblaScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    HomeScreen.tab.addListener(_onTabChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tour = context.read<FeatureTourController?>();
    if (!identical(tour, _tour)) {
      _tour?.removeListener(_onTourChanged);
      _tour = tour;
      tour?.addListener(_onTourChanged);
    }
    if (tour != null && !tour.seen && !_welcomeShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _offerGuide());
    }
    if (tour?.active == true && _preparedStep != tour!.step) {
      _prepareTarget();
    }
  }

  Future<void> _offerGuide() async {
    final tour = _tour;
    if (!mounted || tour == null || tour.seen || _welcomeShown || tour.active) {
      return;
    }
    if (ModalRoute.isCurrentOf(context) == false) return;
    _welcomeShown = true;
    final s = AppStrings.read(context);
    final view = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(s.guideWelcomeTitle),
        content: Text(s.guideWelcomeBody),
        actions: [
          TextButton(
            key: const ValueKey('feature_guide_welcome_skip'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.onboardSkip),
          ),
          FilledButton(
            key: const ValueKey('feature_guide_welcome_view'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.viewGuide),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (view == true) {
      tour.start();
    } else {
      await tour.finish();
    }
  }

  void _onTourChanged() {
    if (!mounted) return;
    setState(() {});
    final tour = _tour!;
    if (tour.active && _preparedStep != tour.step) {
      FocusManager.instance.primaryFocus?.unfocus();
      _prepareTarget();
    } else if (!tour.active) {
      _preparation++;
      _preparedStep = -1;
      _targetRect = null;
    }
  }

  void _prepareTarget() {
    final tour = _tour;
    if (tour == null || !tour.active) return;
    final step = tour.step;
    final preparation = ++_preparation;
    _preparedStep = step;
    _targetRect = null;
    HomeScreen.tab.value = _tourTabs[step];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var attempt = 0; attempt < 3; attempt++) {
        if (!mounted || !tour.active || preparation != _preparation) return;
        final targetContext = tour.keyFor(_tourTargets[step]).currentContext;
        if (targetContext != null && targetContext.mounted) {
          await Scrollable.ensureVisible(
            targetContext,
            alignment: 0.2,
            duration: Motion.of(context, Motion.settle),
            curve: Curves.easeOut,
          );
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted || !tour.active || preparation != _preparation) return;
          if (!targetContext.mounted) continue;
          final surface = _surfaceKey.currentContext?.findRenderObject();
          final target = targetContext.findRenderObject();
          if (surface is RenderBox &&
              target is RenderBox &&
              target.hasSize &&
              surface.hasSize) {
            final offset = target.localToGlobal(Offset.zero, ancestor: surface);
            final rect = offset & target.size;
            // Only spotlight a laid out, visible control. An orientation
            // change can briefly leave the old target outside the viewport.
            final visible = rect.intersect(Offset.zero & surface.size);
            if (visible.width <= 0 || visible.height <= 0) continue;
            setState(() => _targetRect = visible);
            return;
          }
        }
        await WidgetsBinding.instance.endOfFrame;
      }
    });
  }

  @override
  void didChangeMetrics() {
    if (_tour?.active == true && mounted) {
      setState(_prepareTarget);
    }
  }

  @override
  void dispose() {
    HomeScreen.tab.removeListener(_onTabChanged);
    _tour?.removeListener(_onTourChanged);
    WidgetsBinding.instance.removeObserver(this);
    _preparation++;
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() => _index = HomeScreen.tab.value);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final active = _tour?.active ?? false;
    final step = _tour?.step ?? 0;
    final titles = [
      s.navTasbih,
      s.navQuran,
      s.navPrayer,
      s.secAppearance,
      s.notifications,
    ];
    final bodies = [
      s.guideTasbihBody,
      s.guideQuranBody,
      s.guidePrayerBody,
      s.guideAppearanceBody,
      s.guideNotificationsBody,
    ];

    final home = Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      // No edge at all: the bar shares the page's ground, and the stadium
      // indicator alone says where you are.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => HomeScreen.tab.value = i,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: s.navAdhkar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories),
            label: s.navQuran,
          ),
          FeatureTourAnchor(
            target: FeatureTourTarget.prayerQibla,
            child: NavigationDestination(
              icon: const Icon(Icons.mosque_outlined),
              selectedIcon: const Icon(Icons.mosque),
              label: s.navPrayer,
            ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune),
            label: s.navSettings,
          ),
        ],
      ),
    );
    return PopScope<Object?>(
      canPop: !active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && active) _tour?.finish();
      },
      child: Stack(
        key: _surfaceKey,
        fit: StackFit.expand,
        children: [
          ExcludeFocus(
            excluding: active,
            child: ExcludeSemantics(excluding: active, child: home),
          ),
          if (active)
            Positioned.fill(
              child: FeatureTourOverlay(
                targetRect: _targetRect,
                title: titles[step],
                body: bodies[step],
                step: step + 1,
                total: FeatureTourController.stepCount,
                onNext: () => _tour!.next(),
                onSkip: () => _tour!.finish(),
              ),
            ),
        ],
      ),
    );
  }
}

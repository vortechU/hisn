import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/ornament.dart';
import 'home_screen.dart';

/// First-run welcome tour: a few tip pages introducing each tab, then a
/// permissions page that asks for location (prayer times + Qibla) and
/// notifications (prayer reminders). Shown once, gated by [seenKey].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.prefs});

  final SharedPreferences prefs;

  /// Pref flag marking the tour as completed (or skipped). Versioned so a
  /// future revised tour can be reshown by bumping the suffix.
  static const seenKey = 'onboarding_seen_v1';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  // Permission step state.
  bool _locationGranted = false;
  bool _locationBusy = false;
  bool _notifEnabled = false;
  bool _notifBusy = false;

  // The number of pages: 4 tip pages + 1 permissions page.
  static const _pageCount = 5;
  int get _lastIndex => _pageCount - 1;
  bool get _onLastPage => _page == _lastIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await widget.prefs.setBool(OnboardingScreen.seenKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _next() {
    if (_onLastPage) {
      _finish();
    } else {
      _controller.nextPage(
        duration: Motion.of(context, Motion.settle),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _requestLocation() async {
    setState(() => _locationBusy = true);
    final granted =
        await context.read<PrayerService>().requestLocationPermission();
    if (!mounted) return;
    setState(() {
      _locationGranted = granted;
      _locationBusy = false;
    });
  }

  Future<void> _enableNotifications() async {
    setState(() => _notifBusy = true);
    final notifications = context.read<NotificationService>();
    // Turning the master on both prompts for the OS permission and schedules
    // the rolling window of prayer-time reminders.
    await notifications.setMasterEnabled(true);
    if (!mounted) return;
    setState(() {
      _notifEnabled = !notifications.permissionDenied;
      _notifBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip — top trailing, hidden on the last page.
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AnimatedOpacity(
                opacity: _onLastPage ? 0 : 1,
                duration: Motion.of(context, Motion.quick),
                child: TextButton(
                  onPressed: _onLastPage ? null : _finish,
                  child: Text(s.onboardSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _TipPage(
                    icon: Icons.auto_awesome,
                    title: s.onboardWelcomeTitle,
                    body: s.onboardWelcomeBody,
                    hero: true,
                  ),
                  _TipPage(
                    icon: Icons.menu_book,
                    title: s.onboardAdhkarTitle,
                    body: s.onboardAdhkarBody,
                  ),
                  _TipPage(
                    icon: Icons.auto_stories,
                    title: s.onboardQuranTitle,
                    body: s.onboardQuranBody,
                  ),
                  _TipPage(
                    icon: Icons.mosque,
                    title: s.onboardPrayerTitle,
                    body: s.onboardPrayerBody,
                  ),
                  _PermissionsPage(
                    locationGranted: _locationGranted,
                    locationBusy: _locationBusy,
                    notifEnabled: _notifEnabled,
                    notifBusy: _notifBusy,
                    onLocation: _requestLocation,
                    onNotifications: _enableNotifications,
                  ),
                ],
              ),
            ),
            // Bottom bar: page dots + the primary advance / finish button.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  _Dots(count: _pageCount, active: _page),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                    child: Text(
                      _onLastPage ? s.onboardGetStarted : s.onboardNext,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single tip page: an illuminated mark, a title, and a short description.
///
/// The mark is a rosette carrying the tab's own icon, on the geometric ground
/// — the same vocabulary the rest of the app uses, so the tour introduces the
/// book rather than a separate onboarding aesthetic.
class _TipPage extends StatelessWidget {
  const _TipPage({
    required this.icon,
    required this.title,
    required this.body,
    this.hero = false,
  });

  final IconData icon;
  final String title;
  final String body;

  /// The welcome page gets the larger, gilt mark over the geometric ground.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    // Centre the leaf's content in the height the PageView actually gives it,
    // while still allowing it to scroll on short screens and at large text
    // scales. minHeight has to come from the real viewport — a fraction of the
    // window leaves the column anchored to the top of a short box.
    return LayoutBuilder(
      builder: (context, viewport) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewport.maxHeight - 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 158,
                height: 158,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (hero)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Ms.rPanel),
                          child: GirihField(
                              color: ms.rubric, opacity: 0.16, side: 14),
                        ),
                      ),
                    Icon(
                      icon,
                      size: hero ? 64 : 56,
                      color: hero ? ms.gilt : ms.rubric,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const RuleDivider(indent: 60),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The final page: a heading and the two permission requests.
class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage({
    required this.locationGranted,
    required this.locationBusy,
    required this.notifEnabled,
    required this.notifBusy,
    required this.onLocation,
    required this.onNotifications,
  });

  final bool locationGranted;
  final bool locationBusy;
  final bool notifEnabled;
  final bool notifBusy;
  final VoidCallback onLocation;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
      children: [
        Center(
          child: Icon(Icons.lock_outline, size: 42, color: ms.rubric),
        ),
        const SizedBox(height: 16),
        Text(
          s.onboardPermsTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const RuleDivider(indent: 56),
        Text(
          s.onboardPermsBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _PermissionTile(
          icon: Icons.location_on_outlined,
          title: s.onboardLocationTitle,
          body: s.onboardLocationBody,
          action: s.onboardLocationAction,
          granted: locationGranted,
          busy: locationBusy,
          onPressed: onLocation,
        ),
        const SizedBox(height: 16),
        _PermissionTile(
          icon: Icons.notifications_active_outlined,
          title: s.onboardNotifTitle,
          body: s.onboardNotifBody,
          action: s.onboardNotifAction,
          granted: notifEnabled,
          busy: notifBusy,
          onPressed: onNotifications,
        ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.granted,
    required this.busy,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final bool granted;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return JadwalFrame(
      accent: granted ? ms.gilt : null,
      emphasis: granted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 22, color: granted ? ms.gilt : ms.rubric),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(body, style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                if (granted)
                  Cartouche(
                    label: s.onboardGranted,
                    icon: Icons.check,
                    color: ms.gilt,
                    filled: true,
                  )
                else
                  OutlinedButton(
                    onPressed: busy ? null : onPressed,
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(action),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Page position, marked as a row of rules — the current page's rule struck
/// long and in the rubric, the rest short. Reads as a quire signature rather
/// than as a carousel's dots.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final selected = i == active;
        return AnimatedContainer(
          duration: Motion.of(context, Motion.quick),
          curve: Curves.easeOut,
          margin: const EdgeInsetsDirectional.only(end: 5),
          width: selected ? 20 : 9,
          height: 2,
          color: selected ? ms.rubric : ms.rule,
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/islamic_pattern.dart';
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
        duration: const Duration(milliseconds: 300),
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
                duration: const Duration(milliseconds: 200),
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

/// A single tip page: a large tinted icon, a title, and a short description.
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

  /// The welcome page uses the brand emerald gradient for its icon badge.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hero ? BrandTheme.of(context) : null,
              color: hero ? null : scheme.primary.withValues(alpha: 0.12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hero)
                  Positioned.fill(
                    child: ClipOval(
                      child: IslamicPattern(
                          color: Colors.white, opacity: 0.1, cell: 30),
                    ),
                  ),
                Icon(
                  icon,
                  size: 60,
                  color: hero ? Colors.white : scheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
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
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      children: [
        const SizedBox(height: 8),
        Icon(Icons.verified_user_outlined, size: 56, color: scheme.primary),
        const SizedBox(height: 20),
        Text(
          s.onboardPermsTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          s.onboardPermsBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
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
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: granted
              ? scheme.primary.withValues(alpha: 0.6)
              : scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                if (granted)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        s.onboardGranted,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

/// A small page-position indicator: a row of dots with the active one widened.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final selected = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsetsDirectional.only(end: 6),
          width: selected ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary
                : scheme.onSurfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

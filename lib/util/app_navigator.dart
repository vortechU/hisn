import 'package:flutter/widgets.dart';

/// App-wide navigator key, so non-widget code (e.g. a notification tap handler)
/// can push routes. Wired into `MaterialApp.navigatorKey` in `app.dart`.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

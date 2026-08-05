import 'package:flutter/material.dart';

/// Motion durations, gated on the platform's reduce-motion setting.
///
/// Every animated widget in the app takes its duration from here rather than
/// hard-coding one, so that turning on "Remove animations" in the OS
/// accessibility settings genuinely stops motion instead of merely shortening
/// it. [Motion.of] returns [Duration.zero] in that case, which makes implicit
/// animations snap to their end state.
class Motion {
  Motion._();

  /// State changes inside a control: a counter ticking, a chip selecting.
  static const Duration quick = Duration(milliseconds: 120);

  /// Progress meters filling, panels revealing.
  static const Duration settle = Duration(milliseconds: 260);

  /// The one place a longer beat is warranted: a completed set's illumination.
  static const Duration flourish = Duration(milliseconds: 420);

  /// Whether the user has asked for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or [Duration.zero] when the user has asked for reduced motion.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}

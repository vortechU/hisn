/// Bearing arithmetic for the compass, kept out of the widgets so the
/// wrap-around cases can be tested on their own.
///
/// Everything here is in degrees and treats 0° and 360° as the same bearing.
/// Dart's `%` already returns a non-negative result for a positive divisor,
/// which is what lets these stay one-liners.
library;

import 'dart:math' as math;

/// [degrees] folded into `[0, 360)`.
double normalizeDegrees(double degrees) => degrees % 360;

/// The shortest turn from [from] to [to], in `[-180, 180)`. Positive is
/// clockwise.
///
/// The `+ 540` is `+ 180` for the shift and `+ 360` to keep the modulo away
/// from negative input; the `- 180` puts the answer back around zero.
double signedDelta(double from, double to) => (to - from + 540) % 360 - 180;

/// A compass needle's motion: a critically damped spring pulling the drawn
/// heading toward the measured one.
///
/// Two things set this apart from smoothing each reading as it lands:
///
/// * It is stepped by **time**, once a frame, not once a reading. Readings
///   come at the sensor's rate and frames at the screen's; a needle that moves
///   only when a reading arrives moves in visible steps, however well each
///   step is smoothed.
/// * It carries **velocity**. A needle that gathers speed and sheds it reads as
///   an instrument, and a second-order filter shuts out far more of the
///   sensor's fast jitter than a first-order one does for the same lag.
///
/// Critically damped is the stiffest a spring can be without ringing, so the
/// needle settles onto a bearing instead of swinging past it and back.
///
/// Angles are kept *unwrapped*: they run on past 360 and below 0 rather than
/// folding back, so a rotation drawn from [angle] never jumps at the seam.
class NeedleSpring {
  NeedleSpring({this.naturalFrequency = 10});

  /// How quickly the needle answers, in radians per second. Higher follows
  /// faster and lets more jitter through. At 10 the needle trails a turning
  /// phone by a fifth of a second, and takes up nineteen-twentieths of a
  /// sudden turn in under half of one.
  final double naturalFrequency;

  /// Close enough to call arrived: a tenth of a pixel at the rim of the dial.
  static const double restWithin = 0.05;

  /// Slow enough to call stopped, in degrees per second.
  static const double restBelow = 0.5;

  double? _angle;
  double _target = 0;
  double _velocity = 0;

  /// Where the needle is drawn, in degrees, unwrapped. Null until the first
  /// [aim].
  double? get angle => _angle;

  /// Where the needle is going, unwrapped.
  double get target => _target;

  /// How fast the needle is turning, in degrees per second. Clockwise is
  /// positive.
  double get velocity => _velocity;

  /// Whether another frame would move the needle by less than anyone could
  /// see — and so whether there is any point drawing one.
  bool get atRest =>
      _angle == null ||
      ((_angle! - _target).abs() < restWithin && _velocity.abs() < restBelow);

  /// Point the needle at [bearing], in degrees.
  ///
  /// The first bearing is taken as it stands: there is nowhere for the needle
  /// to have come from, and sweeping in from north would only be a show.
  ///
  /// After that [bearing] is unwrapped against the previous target, not
  /// against the needle. Readings arrive far closer together than any hand
  /// can turn, so the step between two of them is the way the phone actually
  /// went; the gap to a needle still catching up is not.
  void aim(double bearing) {
    if (_angle == null) {
      _angle = _target = normalizeDegrees(bearing);
      _velocity = 0;
      return;
    }
    _target += signedDelta(_target, bearing);
  }

  /// Move the needle on by [seconds].
  ///
  /// This is the spring's exact solution, with the target held still over the
  /// step, rather than a numerical step toward it. A dropped frame lands the
  /// needle where the frames it missed would have, and no frame time, however
  /// long, can make it unstable.
  void advance(double seconds) {
    final angle = _angle;
    if (angle == null || seconds <= 0) return;

    final w = naturalFrequency;
    final gap = angle - _target;
    final b = _velocity + w * gap;
    final decay = math.exp(-w * seconds);
    _angle = _target + (gap + b * seconds) * decay;
    _velocity = (_velocity - w * b * seconds) * decay;

    // Arrived: put it exactly there, so that a needle at rest stays at rest
    // instead of creeping the last thousandth of a degree forever.
    if (atRest) {
      _angle = _target;
      _velocity = 0;
    }
  }
}

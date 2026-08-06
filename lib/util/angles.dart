/// Bearing arithmetic for the compass, kept out of the widgets so the
/// wrap-around cases can be tested on their own.
///
/// Everything here is in degrees and treats 0° and 360° as the same bearing.
/// Dart's `%` already returns a non-negative result for a positive divisor,
/// which is what lets these stay one-liners.
library;

/// [degrees] folded into `[0, 360)`.
double normalizeDegrees(double degrees) => degrees % 360;

/// The shortest turn from [from] to [to], in `[-180, 180)`. Positive is
/// clockwise.
///
/// The `+ 540` is `+ 180` for the shift and `+ 360` to keep the modulo away
/// from negative input; the `- 180` puts the answer back around zero.
double signedDelta(double from, double to) => (to - from + 540) % 360 - 180;

/// One step of exponential smoothing from [previous] toward [target], taken
/// along the shortest path so the 359°→0° seam doesn't swing the needle the
/// long way round.
///
/// [alpha] is how much of the gap to close per step: lower is steadier and
/// slower to catch up.
double smoothAngle(double previous, double target, double alpha) =>
    normalizeDegrees(previous + alpha * signedDelta(previous, target));

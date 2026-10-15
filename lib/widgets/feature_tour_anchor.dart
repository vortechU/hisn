import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/feature_tour_controller.dart';

/// Anchors actual controls without requiring the tour in standalone screens.
/// The app provides the controller; isolated screen/test hosts may omit it.
class FeatureTourAnchor extends StatelessWidget {
  const FeatureTourAnchor({
    super.key,
    required this.target,
    required this.child,
  });

  final FeatureTourTarget target;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tour = context.read<FeatureTourController?>();
    if (tour == null) return child;
    return KeyedSubtree(key: tour.keyFor(target), child: child);
  }
}

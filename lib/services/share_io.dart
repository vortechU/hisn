import 'dart:typed_data';
import 'dart:ui' as ui;

// Both layers: the capture is addressed by a GlobalKey (widgets) but what
// comes back and does the work is a RenderRepaintBoundary (rendering), and
// neither library re-exports the other's half.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../models/shareable.dart';

/// Why a card couldn't be turned into an image.
enum ShareCaptureError {
  /// The card wasn't on screen, or hadn't been painted yet.
  notReady,

  /// The platform refused to rasterise it (a web renderer without canvas
  /// support, or an out-of-memory rejection on a very tall card).
  unsupported,
}

/// Turns a passage into something that can leave the app.
///
/// Kept apart from the widgets so the encoding decisions — PNG, the capture
/// ratio, what the text form looks like — are in one place rather than spread
/// through a sheet's button handlers.
class ShareIo {
  const ShareIo();

  /// Logical-to-device pixel ratio used when rasterising. Three gives a
  /// 1080px-wide image from a 360px card without making the file enormous.
  static const double pixelRatio = 3.0;

  /// Rasterise the boundary [key] is attached to.
  ///
  /// Returns the PNG bytes, or the reason it couldn't. The widget must be in
  /// the tree and already painted — capture is driven from a button on the
  /// preview, which guarantees both.
  Future<(Uint8List?, ShareCaptureError?)> capture(GlobalKey key) async {
    final object = key.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) {
      return (null, ShareCaptureError.notReady);
    }
    // A boundary that still needs paint would rasterise as blank.
    if (object.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 32));
    }
    try {
      final image = await object.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return (null, ShareCaptureError.unsupported);
      return (data.buffer.asUint8List(), null);
    } catch (_) {
      return (null, ShareCaptureError.unsupported);
    }
  }

  /// Hand a rendered card to the system share sheet.
  ///
  /// The reference goes along as the accompanying text, not just baked into
  /// the picture: an image alone is invisible to search, to screen readers,
  /// and to anyone who has images turned off, and the source is the one part
  /// that must survive all three.
  Future<bool> shareImage(
    Uint8List png, {
    required Shareable passage,
    ui.Rect? origin,
  }) async {
    const name = 'hisn.png';
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          // From bytes, so no `dart:io` here and the web build still compiles.
          XFile.fromData(png, mimeType: 'image/png', name: name),
        ],
        // XFile.fromData drops the name on some platforms; this pins it.
        fileNameOverrides: [name],
        text: passage.reference,
        sharePositionOrigin: origin,
      ),
    );
    return result.status == ShareResultStatus.success;
  }

  /// Share the passage as plain text.
  Future<bool> shareText(Shareable passage, {ui.Rect? origin}) async {
    final result = await SharePlus.instance.share(
      ShareParams(text: passage.asText(), sharePositionOrigin: origin),
    );
    return result.status == ShareResultStatus.success;
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/quran_repository.dart';
import '../l10n/app_strings.dart';
import '../models/quran.dart';
import '../services/quran_service.dart';
import '../theme/app_theme.dart';
import '../util/arabic.dart';
import '../widgets/arabic_text.dart';
import '../widgets/ornament.dart';
import '../widgets/verse_row.dart';

/// The four inks a mushaf page is printed with, taken from the active palette
/// so the reader follows the user's chosen scheme and their light/dark mode
/// instead of being pinned to one hardcoded cream page.
@immutable
class _MushafInk {
  const _MushafInk(this.paper, this.ink, this.gold, this.green);

  /// The page.
  final Color paper;

  /// The body text.
  final Color ink;

  /// Verse-end marks, the frame, and bookmarks.
  final Color gold;

  /// Sūrah headers, the running head, and the basmalah.
  final Color green;

  factory _MushafInk.of(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    return _MushafInk(
      ms.paper,
      Theme.of(context).colorScheme.onSurface,
      ms.gilt,
      ms.rubric,
    );
  }
}

const double _refFontSize = 40;

// Memoised per-page measurements, keyed by page number alone. The 15-line
// TextPainter pass is the expensive part and its result does not depend on the
// frame — it is the page's own shape at a reference font size — so a rotation
// re-derives the layout arithmetically instead of measuring again.
final Map<int, _PageMetrics> _metricsCache = {};

bool _isSpecialLine(List<MushafWord> line) =>
    line.any((w) => w.isHeader || w.isBismillah);

/// The intrinsic shape of one mushaf page, measured once at [_refFontSize].
@immutable
class _PageMetrics {
  const _PageMetrics({
    required this.maxLineWidth,
    required this.maxLineHeight,
    required this.lineCount,
  });

  /// Width of the widest verse line, at [_refFontSize].
  final double maxLineWidth;

  /// Height of the tallest glyph block, at [_refFontSize].
  final double maxLineHeight;

  final int lineCount;

  /// Glyph block height per unit of font size.
  double get lineRatio => maxLineHeight / _refFontSize;

  /// The page's natural width-to-height ratio: how wide the text block wants to
  /// be for the height its lines need. Sizing the frame to this is what keeps
  /// full lines justified edge to edge, the way the page is printed.
  double get aspect => maxLineWidth / (lineCount * maxLineHeight);
}

/// How a page should be drawn into a given frame.
@immutable
class MushafPageLayout {
  const MushafPageLayout({required this.fontSize, required this.width});

  final double fontSize;

  /// The width the text block is actually drawn at — never wider than the
  /// page's natural proportions allow.
  final double width;
}

/// Fits [page] into a frame, exposed for tests.
///
/// The proportion rule this encodes — a page is letterboxed rather than
/// stretched — is invisible in a screenshot until it is wrong, so it is pinned
/// directly.
@visibleForTesting
MushafPageLayout mushafPageLayoutFor(
  MushafPage page,
  double availW,
  double availH,
) =>
    _layoutFor(page, availW, availH);

_PageMetrics _metricsFor(MushafPage page) =>
    _metricsCache[page.page] ??= _measure(page);

_PageMetrics _measure(MushafPage page) {
  // Measure the verse lines (ignoring decorative header/basmalah lines) to find
  // the widest and the tallest. Laying each line out here also warms its glyph
  // font as a side effect.
  var maxW = 1.0;
  var maxH = _refFontSize;
  for (final line in page.lines) {
    if (_isSpecialLine(line)) continue;
    final tp = TextPainter(
      text: TextSpan(children: [
        for (final w in line.reversed)
          TextSpan(
            text: w.glyph,
            style: TextStyle(
              fontFamily: w.font ?? page.font,
              fontSize: _refFontSize,
              height: 1.0,
            ),
          ),
      ]),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (tp.width > maxW) maxW = tp.width;
    if (tp.height > maxH) maxH = tp.height;
    tp.dispose();
  }
  return _PageMetrics(
    maxLineWidth: maxW,
    maxLineHeight: maxH,
    lineCount: page.lines.length,
  );
}

/// Fits [page] into the frame, keeping the page's own proportions.
///
/// A mushaf page is a tall block of fifteen justified lines. Given only a
/// height cap, a landscape frame would sit far wider than those lines need, and
/// the font — bound by the height — would shrink until the text was a narrow
/// ragged column adrift in the middle of the page. So the block is never
/// allowed to be wider than its natural aspect: in landscape it is letterboxed
/// to the width its lines actually want, which puts the width and height
/// constraints in agreement and leaves the lines justified at any orientation.
MushafPageLayout _layoutFor(MushafPage page, double availW, double availH) {
  final metrics = _metricsFor(page);
  final width = math.min(availW, availH * metrics.aspect);

  // Each line gets an equal share of the height, so the block fills the frame
  // top-to-bottom like the printed page.
  final slot = availH / metrics.lineCount;
  final widthFont = width / metrics.maxLineWidth * _refFontSize * 0.99;
  final heightFont = slot / metrics.lineRatio;

  return MushafPageLayout(
    fontSize: math.min(widthFont, heightFont),
    width: width,
  );
}

/// The Madani Mushaf reader: a swipeable, page-by-page view rendered with the
/// King Fahd Complex (QCF v4) page fonts — looks like the printed mushaf.
class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key, required this.startPage});

  final int startPage;

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _controller;
  // Drives the AppBar (title + bookmark) only. Updating it on swipe rebuilds
  // those two widgets — not the PageView — so the heavy page bodies are never
  // rebuilt by a page change.
  late final ValueNotifier<int> _currentPage;

  /// How far the page is zoomed: 0 is the framed page under the bar, 1 is the
  /// glyph block alone, edge to edge, with the apparatus — bar, running head,
  /// gold frame, folio — gone and its space given to the text.
  ///
  /// While two fingers are down this is written straight from the pinch, so the
  /// page follows the fingers and can be taken back mid-way; on release it
  /// settles to whichever end is nearer.
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  /// Where the zoom stood when the current pinch began, so a pinch that starts
  /// part-way through carries on from there rather than from zero.
  double _zoomAtPinchStart = 0;

  /// Whether the system bars are currently hidden.
  bool _immersive = false;

  /// The display's own insets, read while the bars are still up.
  ///
  /// Hiding them zeroes MediaQuery's padding, so laying the page out against a
  /// live reading would jerk it upwards the instant they went. The page keeps
  /// these in both states instead: that strip is a notch's worth of glass on
  /// many phones, and in portrait it buys no font size anyway — the fit is
  /// bound by the width, not the height.
  EdgeInsets _safeInsets = EdgeInsets.zero;

  int get _total => QuranRepository.totalPages;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_syncSystemBars);
    // Reading sessions are long and mostly touch-free; keep the screen awake
    // while the mushaf is open.
    WakelockPlus.enable();
    final start = widget.startPage.clamp(1, _total);
    _currentPage = ValueNotifier<int>(start);
    // The view scrolls right-to-left (reverse:true under the forced RTL in
    // build), so the view index is the mirror of the page: index = total - page.
    _controller = PageController(initialPage: _total - start);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranService>().setLastPage(start);
      _prefetchNeighbors(start);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only while the bars are up: once they are hidden this reads as zero, and
    // taking that would move the page out from under itself.
    if (!_immersive) _safeInsets = MediaQuery.viewPaddingOf(context);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    if (_immersive) _showSystemBars();
    _zoom.dispose();
    _controller.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  /// Hides the bars once the zoom is all the way in, and brings them back as
  /// soon as it starts coming out again. Tied to the zoom rather than to the
  /// gesture so every route out — pinch, back button, leaving the screen —
  /// goes through the one place.
  void _syncSystemBars() {
    if (!_immersive && _zoom.value >= 1) {
      _immersive = true;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else if (_immersive && _zoom.value < 0.9) {
      _immersive = false;
      _showSystemBars();
    }
  }

  /// Puts the status and navigation bars back.
  ///
  /// The bars have to be asked for by name here. Setting the mode to
  /// `edgeToEdge` on its own leaves `immersiveSticky`'s hide standing on
  /// current Android, which is why the page could come back out of the zoom
  /// while the status bar stayed gone — and why the first swipe home was
  /// swallowed by the system revealing the bars instead. Listing every overlay
  /// is what lifts it; `edgeToEdge` then returns the app to drawing behind
  /// them, where it was before the reader was opened.
  void _showSystemBars() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Drives the zoom from a live pinch: spreading the fingers by the full
  /// [_PinchDetector.outFactor] takes it all the way in, closing them by
  /// [_PinchDetector.inFactor] all the way back out, and anything less lands
  /// in between.
  void _onPinch(double ratio) {
    final travel = ratio >= 1
        ? (ratio - 1) / (_PinchDetector.outFactor - 1)
        : -(1 - ratio) / (1 - _PinchDetector.inFactor);
    _zoom.value = (_zoomAtPinchStart + travel).clamp(0.0, 1.0);
  }

  /// Runs the zoom to the nearer end when the fingers leave, at a speed set by
  /// how far it still has to go, so a nearly-finished pinch doesn't crawl.
  void _settleZoom() {
    final target = _zoom.value >= 0.5 ? 1.0 : 0.0;
    final remaining = (target - _zoom.value).abs();
    if (remaining == 0) return;
    _zoom.animateTo(
      target,
      duration: Duration(milliseconds: (240 * remaining).round().clamp(90, 240)),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    final page = _total - index;
    _currentPage.value = page;
    context.read<QuranService>().setLastPage(page);
    _prefetchNeighbors(page);
  }

  /// Warm the JSON, page font, and measurements for the pages on either side,
  /// so swiping onto them is instant rather than triggering a ~2 MB font parse
  /// and a fresh 15-line measurement mid-gesture.
  void _prefetchNeighbors(int page) {
    final repo = context.read<QuranRepository>();
    for (final p in [page + 1, page - 1, page + 2, page - 2]) {
      if (p < 1 || p > _total) continue;
      repo.loadPage(p).then((mp) {
        // Side effect: lays out each line with its font, warming the glyph
        // cache and filling _metricsCache for an instant first paint. The
        // measurement is frame-independent, so no size is needed here.
        if (mounted) _metricsFor(mp);
      });
    }
  }

  /// Jump straight to a page (used by the "go to verse" picker). reverse:true
  /// means the view index is the mirror of the page number.
  void _jumpToPage(int page) {
    final target = page.clamp(1, _total);
    _controller.jumpToPage(_total - target);
  }

  /// The verses printed on the page in view, so a particular āyah can be read
  /// as text and kept.
  ///
  /// Reached from the app bar rather than by tapping the page: the reader
  /// already spends taps on swiping and pinching, and a page that opened a
  /// sheet whenever it was touched would be unusable to read from.
  Future<void> _openPageVerses() async {
    final page = _currentPage.value;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PageVersesSheet(page: page),
    );
  }

  Future<void> _openGoToAyah() async {
    final repo = context.read<QuranRepository>();
    final currentSurah = repo.surahForPage(_currentPage.value).number;
    final page = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GoToAyahSheet(repo: repo, currentSurah: currentSurah),
    );
    if (page != null && mounted) _jumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final s = AppStrings.of(context);
    final inks = _MushafInk.of(context);

    final bar = AppBar(
      backgroundColor: inks.paper,
      foregroundColor: inks.ink,
      elevation: 0,
      title: ValueListenableBuilder<int>(
        valueListenable: _currentPage,
        builder: (context, page, _) => Text('${s.surahWord} '
            '${repo.surahForPage(page).nameFor(s.ar)}'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.format_list_bulleted),
          tooltip: s.versesOnThisPage,
          onPressed: _openPageVerses,
        ),
        IconButton(
          icon: const Icon(Icons.my_location),
          tooltip: s.goToAyah,
          onPressed: _openGoToAyah,
        ),
        // Rebuilds on page change (current page) and on bookmark toggles
        // only — never drags the PageView into a rebuild.
        ValueListenableBuilder<int>(
          valueListenable: _currentPage,
          builder: (context, page, _) => Consumer<QuranService>(
            builder: (context, quran, _) {
              final bookmarked = quran.isBookmarked(page);
              return IconButton(
                icon: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: bookmarked ? inks.gold : inks.ink),
                tooltip: bookmarked ? s.removeBookmark : s.bookmark,
                onPressed: () => quran.toggleBookmark(page),
              );
            },
          ),
        ),
      ],
    );

    final scaffold = Scaffold(
      backgroundColor: inks.paper,
      // The bar is laid over the pages rather than given to the Scaffold: as a
      // Scaffold appBar its height is fixed at build time, so shrinking it
      // through the zoom would mean rebuilding the whole Scaffold — PageView
      // and all — on every frame of the gesture. Over the top it fades and
      // slides on its own, and each page opens the space it leaves by itself.
      body: Stack(
        children: [
          // The mushaf is always read right-to-left, like the printed Qur'an. A
          // horizontal PageView derives its swipe direction from the ambient
          // Directionality, which MaterialApp.locale flips to LTR for English
          // and other non-Arabic languages — that would reverse the page turn.
          // Pin this subtree to RTL so paging stays right-to-left in every UI
          // language.
          Positioned.fill(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: _PinchDetector(
                onPinchStart: () => _zoomAtPinchStart = _zoom.value,
                onPinch: _onPinch,
                onPinchEnd: _settleZoom,
                child: PageView.builder(
                  controller: _controller,
                  reverse: true,
                  itemCount: _total,
                  onPageChanged: _onPageChanged,
                  // Pre-builds the adjacent page (one viewport of cache extent)
                  // so its glyph layout and raster are done before a swipe
                  // reveals it.
                  allowImplicitScrolling: true,
                  // RepaintBoundary isolates each page's painting (gold frames,
                  // glyphs) so a neighbour doesn't repaint during the swipe
                  // animation.
                  itemBuilder: (context, index) => RepaintBoundary(
                    child: _MushafPageView(
                      pageNumber: _total - index,
                      zoom: _zoom,
                      safeInsets: _safeInsets,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _zoom,
              // Built once and handed through: the bar's own contents don't
              // depend on the zoom, only its opacity and its place do.
              child: bar,
              builder: (context, child) {
                final t = _zoom.value;
                if (t >= 1) return const SizedBox.shrink();
                return IgnorePointer(
                  // Half-way out it is a ghost; taps there belong to the page.
                  ignoring: t > 0.5,
                  child: Opacity(
                    opacity: 1 - t,
                    child: Transform.translate(
                      offset: Offset(
                          0, -(_safeInsets.top + kToolbarHeight) * t),
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    // Zoomed in, the first back press brings the page back out instead of
    // leaving the reader. Only the PopScope is rebuilt as the zoom runs — the
    // scaffold below it is passed through untouched.
    return AnimatedBuilder(
      animation: _zoom,
      child: scaffold,
      builder: (context, child) => PopScope(
        canPop: _zoom.value == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _zoom.animateTo(0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic);
          }
        },
        child: child!,
      ),
    );
  }
}

/// Watches raw pointer events for a two-finger pinch without joining the
/// gesture arena, so the PageView's swipe keeps its normal feel. A symmetric
/// pinch moves the fingers in opposite directions, which the PageView's drag
/// (tracking their average) mostly cancels out — the page barely shifts.
///
/// Reports the span as a ratio of where it started, every frame the fingers
/// move, so the zoom can follow them rather than snapping when a threshold is
/// crossed.
class _PinchDetector extends StatefulWidget {
  const _PinchDetector({
    required this.onPinchStart,
    required this.onPinch,
    required this.onPinchEnd,
    required this.child,
  });

  /// Two fingers are down and the span has been baselined.
  final VoidCallback onPinchStart;

  /// The current span as a fraction of the baseline: >1 spreading, <1 closing.
  final ValueChanged<double> onPinch;

  /// Fewer than two fingers are left — settle wherever the pinch got to.
  final VoidCallback onPinchEnd;

  final Widget child;

  // Spread the fingers ~35% further apart to take the zoom all the way in;
  // bring them ~25% closer to take it all the way back out. Asymmetric so a
  // loose grip doesn't wander.
  static const outFactor = 1.35;
  static const inFactor = 0.75;

  @override
  State<_PinchDetector> createState() => _PinchDetectorState();
}

class _PinchDetectorState extends State<_PinchDetector> {
  final Map<int, Offset> _pointers = {};
  double? _startSpan;

  double get _span {
    final points = _pointers.values.toList();
    return (points[0] - points[1]).distance;
  }

  /// Takes the span as it stands now as the new zero. Called whenever the
  /// number of fingers changes: a pinch that gains or loses one is a new
  /// pinch, measured from where the last one left the page.
  void _rebaseline() {
    if (_pointers.length == 2) {
      _startSpan = _span;
      widget.onPinchStart();
    } else if (_startSpan != null) {
      _startSpan = null;
      widget.onPinchEnd();
    }
  }

  void _down(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    _rebaseline();
  }

  void _move(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    final start = _startSpan;
    if (start == null || _pointers.length != 2) return;
    widget.onPinch(_span / start);
  }

  void _up(int pointer) {
    _pointers.remove(pointer);
    _rebaseline();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: (e) => _up(e.pointer),
      onPointerCancel: (e) => _up(e.pointer),
      child: widget.child,
    );
  }
}

// The page's furniture, in logical pixels. Constants rather than intrinsic
// heights because the zoom has to know how much larger the text block can get
// *before* it lays anything out — see [_PageGeometry]. The running head is
// given a fixed box for the same reason; it sets one line either way.
const double _headHeight = 30;
const double _headGap = 5;
const double _folioHeight = 36; // 4 of padding above a 32 medallion.
const EdgeInsets _framedPadding = EdgeInsets.fromLTRB(14, 4, 14, 2);
const EdgeInsets _zoomedPadding = EdgeInsets.fromLTRB(6, 4, 6, 4);
// Rule, gutter, hairline, and the inner block's own padding — one side of the
// double gold frame.
const double _frameInsetX = Ms.stroke + Ms.gutter + 2 + Ms.hair + 10;
const double _frameInsetY = Ms.stroke + Ms.gutter + 2 + Ms.hair + 8;

/// Where the text block sits at each end of the zoom, worked out from the page
/// box alone.
///
/// The two ends are deliberately the *same block at two sizes* rather than two
/// independent fits: the zoomed block is the framed block scaled by [scale],
/// which is what lets the whole gesture be a single uniform transform instead
/// of a re-fit on every frame. In portrait the fit is bound by the width, so
/// this costs nothing in font size — the block simply keeps its proportions
/// instead of stretching its line spacing to the last pixel of the screen.
@immutable
class _PageGeometry {
  const _PageGeometry(this.page);

  /// The box the page is given, inside the display's own insets.
  final Size page;

  /// Space held for the app bar. Held whether or not the bar is showing, so
  /// that hiding it doesn't move the page.
  double get bar => kToolbarHeight;

  Size get framedInner => Size(
        math.max(1, page.width - _framedPadding.horizontal - 2 * _frameInsetX),
        math.max(
            1,
            page.height -
                bar -
                _framedPadding.vertical -
                _headHeight -
                _headGap -
                _folioHeight -
                2 * _frameInsetY),
      );

  /// Everything the block can have once the furniture is out of the way.
  Size get _free => Size(
        page.width - _zoomedPadding.horizontal,
        page.height - _zoomedPadding.vertical,
      );

  /// How much bigger the block gets, as one factor for both axes.
  double get scale => math.min(
        _free.width / framedInner.width,
        _free.height / framedInner.height,
      );

  Size get zoomedInner => framedInner * scale;

  /// The block's centre when framed — inside the frame, under the bar and the
  /// running head, above the folio.
  Offset get framedCentre => Offset(
        _framedPadding.left + _frameInsetX + framedInner.width / 2,
        bar +
            _framedPadding.top +
            _headHeight +
            _headGap +
            _frameInsetY +
            framedInner.height / 2,
      );

  /// And when zoomed: the middle of the page.
  Offset get zoomedCentre => page.center(Offset.zero);
}

class _MushafPageView extends StatefulWidget {
  const _MushafPageView({
    required this.pageNumber,
    required this.zoom,
    this.safeInsets = EdgeInsets.zero,
  });

  final int pageNumber;

  /// 0 framed under the bar, 1 edge to edge — see [_MushafScreenState._zoom].
  final Animation<double> zoom;

  /// The display's insets, held fixed across the zoom so hiding the system
  /// bars doesn't shift the page.
  final EdgeInsets safeInsets;

  @override
  State<_MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<_MushafPageView> {
  /// Between the two ends the page is painted from one rasterised copy of
  /// itself.
  ///
  /// Re-fitting the text to a slightly different box on every frame meant Skia
  /// re-rasterising the whole page — some five hundred QCF outlines, on each
  /// built page — at a size it had never seen before and would never see
  /// again, sixty times a second. That is what made the zoom crawl. The glyphs
  /// are now drawn once, at the size they end at, and the gesture scales that
  /// picture; the real text comes back the moment the zoom settles.
  final SnapshotController _snapshot = SnapshotController();

  @override
  void initState() {
    super.initState();
    widget.zoom.addListener(_syncSnapshot);
  }

  @override
  void dispose() {
    widget.zoom.removeListener(_syncSnapshot);
    _snapshot.dispose();
    super.dispose();
  }

  void _syncSnapshot() {
    final t = widget.zoom.value;
    _snapshot.allowSnapshotting = t > 0 && t < 1;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final inks = _MushafInk.of(context);

    // Already decoded (prefetched or visited before)? Render straight away —
    // no FutureBuilder, no spinner flash.
    final cached = repo.pageIfCached(widget.pageNumber);
    if (cached != null) return _buildPage(context, repo, cached, inks);

    return FutureBuilder<MushafPage>(
      future: repo.loadPage(widget.pageNumber),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(child: CircularProgressIndicator(color: inks.gold));
        }
        return _buildPage(context, repo, snap.data!, inks);
      },
    );
  }

  Widget _buildPage(BuildContext context, QuranRepository repo,
      MushafPage page, _MushafInk inks) {
    final surahName = page.surahs.isNotEmpty
        ? page.surahs.last.name
        : repo.surahForPage(widget.pageNumber).name;

    return Padding(
      padding: widget.safeInsets,
      child: LayoutBuilder(
        builder: (context, c) {
          final g = _PageGeometry(Size(c.maxWidth, c.maxHeight));

          // Both of these are built once per page box and handed to the
          // animation untouched: identical widgets skip their subtree's
          // rebuild, so a frame of the zoom is a transform and an opacity, not
          // fifteen lines of Arabic laid out again.
          final furniture = _furniture(g, page, surahName, inks);
          final body = SnapshotWidget(
            controller: _snapshot,
            child: _PageBody(page: page, inks: inks),
          );

          return AnimatedBuilder(
            animation: widget.zoom,
            builder: (context, _) {
              final t = widget.zoom.value;
              // The block is laid out at the size it rests at — framed at one
              // end, zoomed at the other — and scaled to wherever the pinch
              // has it. At both ends the scale is 1, so what the reader stops
              // on is always the real thing, set at its own size.
              final laidOutZoomed = t > 0;
              final size = laidOutZoomed ? g.zoomedInner : g.framedInner;
              final shown = 1 + (g.scale - 1) * t;
              final centre = Offset.lerp(g.framedCentre, g.zoomedCentre, t)!;

              return Stack(
                children: [
                  // The furniture goes early — well before the growing block
                  // would reach the rules it is framed by.
                  if (t < _furnitureFade)
                    Opacity(
                      opacity: 1 - t / _furnitureFade,
                      // Its own boundary, so fading it re-composites a picture
                      // that is already drawn rather than drawing it again.
                      child: RepaintBoundary(child: furniture),
                    ),
                  Positioned(
                    left: centre.dx - size.width / 2,
                    top: centre.dy - size.height / 2,
                    width: size.width,
                    height: size.height,
                    child: Transform.scale(
                      scale: shown / (laidOutZoomed ? g.scale : 1),
                      child: body,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// The running head, the double gold frame, and the folio — everything but
  /// the text. Laid out where it sits on the framed page and left there: it is
  /// gone long before the block has grown enough for its position to matter.
  Widget _furniture(_PageGeometry g, MushafPage page, String surahName,
      _MushafInk inks) {
    return Padding(
      padding: EdgeInsets.only(top: g.bar),
      child: Padding(
        padding: _framedPadding,
        child: Column(
          children: [
            SizedBox(
              height: _headHeight,
              // Scaled down rather than allowed to grow: the page's geometry is
              // fixed, and a running head that pushed the text block around at
              // a large system text size would take the zoom's arithmetic with
              // it.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: g.page.width - _framedPadding.horizontal,
                  child: _RunningHead(
                      surahName: surahName, juz: page.juz, inks: inks),
                ),
              ),
            ),
            const SizedBox(height: _headGap),
            // Double-ruled gold frame around the text, like the print.
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(Ms.gutter + 2),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: inks.gold.withValues(alpha: 0.75),
                      width: Ms.stroke),
                  borderRadius: BorderRadius.circular(Ms.rPanel),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: inks.gold.withValues(alpha: 0.4),
                        width: Ms.hair),
                    borderRadius: BorderRadius.circular(Ms.rSmall),
                  ),
                ),
              ),
            ),
            // The folio number, set in the khātam the printed mushaf marks it
            // with, in Arabic-Indic digits.
            SizedBox(
              height: _folioHeight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: StarMedallion(
                  size: 32,
                  color: inks.gold,
                  child: ArabicText(
                    toArabicDigits(widget.pageNumber),
                    fontSize: 12,
                    color: inks.ink,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How far into the zoom the page's furniture has finished fading.
const double _furnitureFade = 0.35;

/// Lists the verses printed on one mushaf page, as text.
///
/// The page itself is a run of glyphs with no verse identity in it, so the
/// verses are recovered from the surah files by page number — see
/// [QuranRepository.versesOnPage].
class _PageVersesSheet extends StatelessWidget {
  const _PageVersesSheet({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final repo = context.read<QuranRepository>();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Ms.margin, 0, Ms.margin, 6),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(s.versesOnThisPage,
                    style: theme.textTheme.titleMedium),
              ),
            ),
            const RuleDivider(indent: Ms.margin),
            Flexible(
              child: FutureBuilder<List<PageVerse>>(
                future: repo.versesOnPage(page, lang: s.lang.name),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                          child:
                              CircularProgressIndicator(color: ms.gilt)),
                    );
                  }
                  final verses = snap.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: verses.length,
                    separatorBuilder: (context, _) => Divider(
                      height: 1,
                      indent: Ms.margin,
                      endIndent: Ms.margin,
                      color: ms.rule,
                    ),
                    itemBuilder: (context, i) => VerseRow(
                      verse: verses[i],
                      // Several surahs can share a page, so each verse still
                      // names its own.
                      showSurahName: verses.length > 1 &&
                          verses.first.surah.number != verses.last.surah.number,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet picker: choose a surah + verse number and jump the reader to
/// that verse's mushaf page. Pops the chosen page number (or null if cancelled).
class _GoToAyahSheet extends StatefulWidget {
  const _GoToAyahSheet({required this.repo, required this.currentSurah});

  final QuranRepository repo;
  final int currentSurah;

  @override
  State<_GoToAyahSheet> createState() => _GoToAyahSheetState();
}

class _GoToAyahSheetState extends State<_GoToAyahSheet> {
  late int _surah = widget.currentSurah;
  final _ayahController = TextEditingController(text: '1');
  bool _loading = false;

  @override
  void dispose() {
    _ayahController.dispose();
    super.dispose();
  }

  Surah get _selected => widget.repo.surahByNumber(_surah)!;

  void _onSurahChanged(int? value) {
    if (value == null) return;
    setState(() {
      _surah = value;
      // Keep the verse field within the new surah's range.
      final cur = int.tryParse(_ayahController.text.trim()) ?? 1;
      final clamped = cur.clamp(1, widget.repo.surahByNumber(value)!.ayahCount);
      _ayahController.text = '$clamped';
    });
  }

  Future<void> _go() async {
    final max = _selected.ayahCount;
    final n = (int.tryParse(_ayahController.text.trim()) ?? 1).clamp(1, max);
    setState(() => _loading = true);
    final page = await widget.repo.pageForAyah(_surah, n);
    if (mounted) Navigator.of(context).pop(page);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final max = _selected.ayahCount;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          Ms.margin, 0, Ms.margin, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.goToAyah, style: theme.textTheme.titleMedium),
          const RuleDivider(ornament: false),
          const SizedBox(height: 4),
          _FieldLabel(s.chooseSurah),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: ms.rule),
              borderRadius: BorderRadius.circular(Ms.rSmall),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _surah,
                isExpanded: true,
                borderRadius: BorderRadius.circular(Ms.rSmall),
                dropdownColor: ms.paper,
                style: theme.textTheme.bodyLarge,
                icon: Icon(Icons.expand_more, color: ms.rubric, size: 20),
                items: [
                  for (final su in widget.repo.surahs)
                    DropdownMenuItem(
                      value: su.number,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${su.number} · ${su.nameFor(s.ar)}',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge),
                          ),
                          // Already named in Arabic on the left in an Arabic
                          // interface — don't set it twice.
                          if (!s.ar)
                            ArabicText(su.name,
                                fontSize: 17, color: ms.rubric, height: 1.5),
                        ],
                      ),
                    ),
                ],
                onChanged: _onSurahChanged,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _FieldLabel(s.verseNumber),
          const SizedBox(height: 5),
          TextField(
            controller: _ayahController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: s.verseRange(max)),
            onSubmitted: (_) => _go(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _go,
              icon: _loading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: theme.colorScheme.onPrimary),
                    )
                  : const Icon(Icons.arrow_forward, size: 18),
              label: Text(s.goAction),
            ),
          ),
        ],
      ),
    );
  }
}

/// The label above a field in the go-to-verse sheet, in the apparatus face.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      );
}

class _RunningHead extends StatelessWidget {
  const _RunningHead({
    required this.surahName,
    required this.juz,
    required this.inks,
  });

  final String surahName;
  final int juz;
  final _MushafInk inks;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          s.juzLabel(juz).toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: inks.green),
        ),
        ArabicText(surahName, fontSize: 18, color: inks.green, height: 1.5),
      ],
    );
  }
}

/// Renders the 15 glyph lines of a mushaf page.
///
/// Two things make it look like the printed page:
///  * Each line's word glyphs are reversed before rendering. The QCF glyphs are
///    Private-Use codepoints (bidi class L), so an in-order run would read
///    left-to-right; reversing puts the first word on the right.
///  * A single font size is computed (from the widest line) so full lines fill
///    the width — justified — while the 15 lines are spaced evenly down the page
///    and short surah-end lines centre naturally.
class _PageBody extends StatelessWidget {
  const _PageBody({required this.page, required this.inks});

  final MushafPage page;
  final _MushafInk inks;

  Color _colorFor(MushafWord w) {
    if (w.type == 'end') return inks.gold;
    if (w.isHeader) return inks.green;
    return inks.ink;
  }

  List<InlineSpan> _spans(List<MushafWord> words, double size) => [
        // Reversed → correct right-to-left word order.
        for (final w in words.reversed)
          TextSpan(
            text: w.glyph,
            style: TextStyle(
              fontFamily: w.font ?? page.font,
              color: _colorFor(w),
              fontSize: size,
              height: 1.0,
            ),
          ),
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final availH = c.maxHeight;
        // The expensive 15-line measurement is memoised per page; everything
        // here is arithmetic on top of it, so rotating costs nothing.
        final layout = _layoutFor(page, c.maxWidth, availH);
        final slot = availH / page.lines.length;

        // Centred, because in landscape the block is narrower than the frame:
        // the page sits in the middle of its surroundings rather than being
        // stretched to fill them.
        return Center(
          child: SizedBox(
            width: layout.width,
            height: availH,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                for (final line in page.lines)
                  SizedBox(
                    width: layout.width,
                    height: slot,
                    child: Center(
                      child: _isSpecialLine(line)
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text.rich(
                                TextSpan(children: _spans(line, layout.fontSize)),
                                textDirection: TextDirection.ltr,
                              ),
                            )
                          : Text.rich(
                              TextSpan(children: _spans(line, layout.fontSize)),
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                            ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

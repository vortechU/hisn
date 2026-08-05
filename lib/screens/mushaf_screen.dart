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

// Memoised per-page font size, keyed by page number + frame size. The 15-line
// TextPainter measurement that finds the fill size is expensive; its result
// only changes when the available space does (i.e. on rotation), so caching it
// keeps every revisit and rebuild free.
final Map<String, double> _fontSizeCache = {};

// The most recent inner frame size, captured during layout. Used to pre-compute
// (and warm the font for) neighbouring pages before they're swiped into view.
Size? _lastInnerSize;

bool _isSpecialLine(List<MushafWord> line) =>
    line.any((w) => w.isHeader || w.isBismillah);

/// The font size that makes the widest verse line on [page] fill the frame
/// width, capped so the 15 lines never overflow vertically. Memoised by page +
/// frame size.
double _fontSizeFor(MushafPage page, double availW, double availH) {
  final key = '${page.page}:${availW.round()}:${availH.round()}';
  return _fontSizeCache[key] ??= _measureFontSize(page, availW, availH);
}

double _measureFontSize(MushafPage page, double availW, double availH) {
  // Measure the verse lines (ignoring decorative header/basmalah lines) to find
  // the widest, then size the font so it fills the width. Laying each line out
  // here also warms its glyph font as a side effect.
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
  final lineRatio = maxH / _refFontSize; // glyph block height per unit font size
  // Each of the 15 lines gets an equal share of the page height so the block
  // always fills the frame top-to-bottom, like the printed mushaf.
  final slot = availH / page.lines.length;
  final widthFont = availW / maxW * _refFontSize * 0.99;
  final heightFont = slot / lineRatio; // cap so a glyph never overflows its slot
  return widthFont < heightFont ? widthFont : heightFont;
}

/// The Madani Mushaf reader: a swipeable, page-by-page view rendered with the
/// King Fahd Complex (QCF v4) page fonts — looks like the printed mushaf.
class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key, required this.startPage});

  final int startPage;

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late final PageController _controller;
  // Drives the AppBar (title + bookmark) only. Updating it on swipe rebuilds
  // those two widgets — not the PageView — so the heavy page bodies are never
  // rebuilt by a page change.
  late final ValueNotifier<int> _currentPage;

  // Fullscreen (immersive) reading: entered by pinching outwards on the page,
  // left by pinching inwards or pressing back.
  bool _fullscreen = false;

  int get _total => QuranRepository.totalPages;

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    WakelockPlus.disable();
    if (_fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _controller.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  void _setFullscreen(bool value) {
    if (_fullscreen == value) return;
    setState(() => _fullscreen = value);
    SystemChrome.setEnabledSystemUIMode(
      value ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _onPageChanged(int index) {
    final page = _total - index;
    _currentPage.value = page;
    context.read<QuranService>().setLastPage(page);
    _prefetchNeighbors(page);
  }

  /// Warm the JSON, page font, and layout for the pages on either side, so
  /// swiping onto them is instant rather than triggering a ~2 MB font parse and
  /// a fresh 15-line measurement mid-gesture.
  void _prefetchNeighbors(int page) {
    final repo = context.read<QuranRepository>();
    for (final p in [page + 1, page - 1, page + 2, page - 2]) {
      if (p < 1 || p > _total) continue;
      repo.loadPage(p).then((mp) {
        final size = _lastInnerSize;
        if (mounted && size != null) {
          // Side effect: lays out each line with its font, warming the glyph
          // cache and populating _fontSizeCache for an instant first paint.
          _fontSizeFor(mp, size.width, size.height);
        }
      });
    }
  }

  /// Jump straight to a page (used by the "go to verse" picker). reverse:true
  /// means the view index is the mirror of the page number.
  void _jumpToPage(int page) {
    final target = page.clamp(1, _total);
    _controller.jumpToPage(_total - target);
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

    // In fullscreen, the first back press restores the normal chrome instead
    // of leaving the reader.
    return PopScope(
      canPop: !_fullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _setFullscreen(false);
      },
      child: Scaffold(
        backgroundColor: inks.paper,
        appBar: _fullscreen
            ? null
            : AppBar(
                backgroundColor: inks.paper,
                foregroundColor: inks.ink,
                elevation: 0,
                title: ValueListenableBuilder<int>(
                  valueListenable: _currentPage,
                  builder: (context, page, _) =>
                      Text('${s.surahWord} ${repo.surahForPage(page).translit}'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.my_location),
                    tooltip: s.goToAyah,
                    onPressed: _openGoToAyah,
                  ),
                  // Rebuilds on page change (current page) and on bookmark
                  // toggles only — never drags the PageView into a rebuild.
                  ValueListenableBuilder<int>(
                    valueListenable: _currentPage,
                    builder: (context, page, _) => Consumer<QuranService>(
                      builder: (context, quran, _) {
                        final bookmarked = quran.isBookmarked(page);
                        return IconButton(
                          icon: Icon(
                              bookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: bookmarked ? inks.gold : inks.ink),
                          tooltip:
                              bookmarked ? s.removeBookmark : s.bookmark,
                          onPressed: () => quran.toggleBookmark(page),
                        );
                      },
                    ),
                  ),
                ],
              ),
        // The mushaf is always read right-to-left, like the printed Qur'an. A
        // horizontal PageView derives its swipe direction from the ambient
        // Directionality, which MaterialApp.locale flips to LTR for English and
        // other non-Arabic languages — that would reverse the page turn. Pin
        // this subtree to RTL so paging stays right-to-left in every UI
        // language.
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: _PinchDetector(
            onPinchOut: () => _setFullscreen(true),
            onPinchIn: () => _setFullscreen(false),
            child: PageView.builder(
              controller: _controller,
              reverse: true,
              itemCount: _total,
              onPageChanged: _onPageChanged,
              // Pre-builds the adjacent page (one viewport of cache extent) so
              // its glyph layout and raster are done before a swipe reveals it.
              allowImplicitScrolling: true,
              // RepaintBoundary isolates each page's painting (gold frames,
              // glyphs) so a neighbour doesn't repaint during the swipe
              // animation.
              itemBuilder: (context, index) => RepaintBoundary(
                child: _MushafPageView(pageNumber: _total - index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Watches raw pointer events for a two-finger pinch without joining the
/// gesture arena, so the PageView's swipe keeps its normal feel. A symmetric
/// pinch moves the fingers in opposite directions, which the PageView's drag
/// (tracking their average) mostly cancels out — the page barely shifts.
/// Fires at most once per gesture.
class _PinchDetector extends StatefulWidget {
  const _PinchDetector({
    required this.onPinchOut,
    required this.onPinchIn,
    required this.child,
  });

  final VoidCallback onPinchOut;
  final VoidCallback onPinchIn;
  final Widget child;

  @override
  State<_PinchDetector> createState() => _PinchDetectorState();
}

class _PinchDetectorState extends State<_PinchDetector> {
  final Map<int, Offset> _pointers = {};
  double? _startSpan;
  bool _fired = false;

  // Spread the fingers ~35% further apart → fullscreen; bring them ~25%
  // closer → back to normal. Asymmetric so a loose grip doesn't flicker.
  static const _outFactor = 1.35;
  static const _inFactor = 0.75;

  double get _span {
    final points = _pointers.values.toList();
    return (points[0] - points[1]).distance;
  }

  void _rebaseline() {
    _startSpan = _pointers.length == 2 ? _span : null;
    _fired = false;
  }

  void _down(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    _rebaseline();
  }

  void _move(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    final start = _startSpan;
    if (start == null || _fired) return;
    final ratio = _span / start;
    if (ratio >= _outFactor) {
      _fired = true;
      widget.onPinchOut();
    } else if (ratio <= _inFactor) {
      _fired = true;
      widget.onPinchIn();
    }
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

class _MushafPageView extends StatelessWidget {
  const _MushafPageView({required this.pageNumber});

  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final inks = _MushafInk.of(context);

    // Already decoded (prefetched or visited before)? Render straight away —
    // no FutureBuilder, no spinner flash.
    final cached = repo.pageIfCached(pageNumber);
    if (cached != null) return _buildPage(context, repo, cached, inks);

    return FutureBuilder<MushafPage>(
      future: repo.loadPage(pageNumber),
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
        : repo.surahForPage(pageNumber).name;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
        child: Column(
          children: [
            _RunningHead(surahName: surahName, juz: page.juz, inks: inks),
            const SizedBox(height: 5),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: inks.gold.withValues(alpha: 0.4),
                        width: Ms.hair),
                    borderRadius: BorderRadius.circular(Ms.rSmall),
                  ),
                  child: _PageBody(page: page, inks: inks),
                ),
              ),
            ),
            // The folio number, set in the khātam the printed mushaf marks it
            // with, in Arabic-Indic digits.
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: StarMedallion(
                size: 32,
                color: inks.gold,
                child: ArabicText(
                  toArabicDigits(pageNumber),
                  fontSize: 12,
                  color: inks.ink,
                  height: 1.2,
                ),
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
                            child: Text('${su.number} · ${su.translit}',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge),
                          ),
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
        final availW = c.maxWidth;
        final availH = c.maxHeight;
        // Remember the frame size so neighbouring pages can be pre-measured.
        _lastInnerSize = Size(availW, availH);

        // Memoised — the expensive 15-line measurement runs once per page/size.
        final fontSize = _fontSizeFor(page, availW, availH);
        final slot = availH / page.lines.length;

        return SizedBox(
          height: availH,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              for (final line in page.lines)
                SizedBox(
                  width: availW,
                  height: slot,
                  child: Center(
                    child: _isSpecialLine(line)
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text.rich(
                              TextSpan(children: _spans(line, fontSize)),
                              textDirection: TextDirection.ltr,
                            ),
                          )
                        : Text.rich(
                            TextSpan(children: _spans(line, fontSize)),
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
        );
      },
    );
  }
}

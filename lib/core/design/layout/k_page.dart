import 'package:flutter/material.dart';

import '../ambient/k_ambient_scene.dart';
import '../ambient/k_backdrop.dart';
import '../components/k_icon_button.dart';
import '../components/k_metal_text.dart';
import '../motion/k_reveal.dart';
import '../icons/k_glyphs.dart';
import '../theme/theme_context.dart';
import '../tokens/k_spacing.dart';

/// Page chrome supplied by the app shell: [onSettings] puts a settings gear
/// at the top right of every top-level page inside it.
class KPageChrome extends InheritedWidget {
  const KPageChrome({super.key, required this.onSettings, required super.child});

  final VoidCallback onSettings;

  static KPageChrome? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KPageChrome>();

  @override
  bool updateShouldNotify(KPageChrome oldWidget) => oldWidget.onSettings != onSettings;
}

/// Standard top-level page: the theme's live scene behind a large title, then
/// scrollable content whose cards arrive in a short stagger. Respects
/// status-bar and bottom-dock insets.
class KPage extends StatefulWidget {
  const KPage({
    super.key,
    required this.children,
    this.title,
    this.eyebrow,
    this.header,
    this.actions = const [],
    this.sceneHeight = 300,
    this.backdrop,
  });

  /// This page's painted backdrop; null keeps the drawn skyline.
  final KBackdrop? backdrop;

  /// Height of the live scene below the status bar. Home uses a taller,
  /// cinematic scene.
  final double sceneHeight;

  /// Large page title. Ignored when [header] is given.
  final String? title;

  /// Small tracked label above the title.
  final String? eyebrow;

  /// Custom header that replaces [eyebrow] + [title].
  final Widget? header;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  State<KPage> createState() => _KPageState();
}

class _KPageState extends State<KPage> {
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    // Parallax only matters while the scene is in view; clamping stops repaints
    // once it has scrolled away.
    _scroll.addListener(
      () => _offset.value = _scroll.offset.clamp(
        0,
        widget.backdrop != null ? 640 : widget.sceneHeight * 1.8 + 80,
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final KPage(:title, :eyebrow, :header, :actions, :children) = widget;
    final p = context.palette;
    final text = context.textStyles;
    final insets = MediaQuery.paddingOf(context);
    final statusBand = Color.alphaBlend(p.ambient.withValues(alpha: p.ambient.a * 0.5), p.canvas);

    final tactical = context.style.isTactical;
    final chrome = KPageChrome.maybeOf(context);
    // Pushed as its own route (Settings): a back button above the title.
    final pushed = ModalRoute.of(context)?.canPop ?? false;

    // Tactical: a console header — status square, capitalised title, and a
    // lit underline segment. Feline: a quiet silver eyebrow, a title set in
    // sentence case, and a hairline that fades away.
    final headerContent =
        header ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow != null) ...[
              Row(
                children: [
                  if (tactical) ...[
                    Container(width: 6, height: 6, color: p.accent),
                    const SizedBox(width: KSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      eyebrow.toUpperCase(),
                      style: text.labelSmall?.copyWith(color: tactical ? p.accentStrong : p.signal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KSpacing.xs),
            ],
            if (title != null)
              Semantics(
                header: true,
                child: KMetalText(tactical ? title.toUpperCase() : title, style: text.displaySmall),
              ),
            const SizedBox(height: KSpacing.sm),
            if (tactical)
              Row(
                children: [
                  Container(width: 36, height: 2, color: p.accent),
                  const SizedBox(width: KSpacing.xs),
                  Container(width: 10, height: 2, color: p.outlineStrong),
                ],
              )
            else
              Container(
                width: 120,
                height: KStroke.hairline,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [p.signal.withValues(alpha: 0.6), p.signal.withValues(alpha: 0)],
                  ),
                ),
              ),
          ],
        );

    return Scaffold(
      body: Stack(
        children: [
          // A picture fills the whole screen behind the page; the drawn
          // skyline sits behind the header only.
          if (widget.backdrop != null)
            Positioned.fill(
              child: KLiveScene(scroll: _offset, backdrop: widget.backdrop),
            )
          else
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: insets.top + widget.sceneHeight,
              child: KLiveScene(scroll: _offset),
            ),
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  KSpacing.gutter,
                  insets.top + KSpacing.xl + (pushed ? 40 : 0),
                  // Room for the gear at the top right.
                  KSpacing.gutter + (chrome != null && header == null ? 40 : 0),
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: headerContent),
                      ...actions,
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  KSpacing.gutter,
                  KSpacing.xl,
                  KSpacing.gutter,
                  insets.bottom + KSpacing.xxl,
                ),
                sliver: SliverList.list(
                  children: [for (final (i, child) in children.indexed) KReveal(order: i, child: child)],
                ),
              ),
            ],
          ),
          // Opaque under the status bar so scrolled content never collides with the
          // system icons, then a short fade. Tinted with some ambient light so the
          // band blends into the glow when the page is at rest.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: insets.top + KSpacing.xl,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, insets.top / (insets.top + KSpacing.xl), 1],
                    colors: [statusBand, statusBand, statusBand.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          if (pushed)
            Positioned(
              top: insets.top + KSpacing.xs,
              left: KSpacing.gutter - KSpacing.sm,
              child: KIconButton(
                glyph: KGlyphs.back,
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          if (chrome != null)
            Positioned(
              top: insets.top + KSpacing.xs,
              right: KSpacing.gutter - KSpacing.sm,
              child: KIconButton(
                glyph: KGlyphs.settings,
                tooltip: 'Settings',
                variant: KIconButtonVariant.tonal,
                onPressed: chrome.onSettings,
              ),
            ),
        ],
      ),
    );
  }
}

/// Pushed detail page: compact app bar with a glyph back button, then a
/// padded scrolling column.
class KSubpage extends StatelessWidget {
  const KSubpage({super.key, required this.title, required this.children, this.actions = const []})
    : body = null;

  /// The same page with any [body] (e.g. a lazily built list) in place of the
  /// padded column. The body handles its own padding and scrolling.
  const KSubpage.custom({super.key, required this.title, required Widget this.body, this.actions = const []})
    : children = const [];

  final String title;
  final List<Widget> actions;
  final List<Widget> children;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: canPop ? 0 : KSpacing.gutter,
        leading: canPop
            ? KIconButton(
                glyph: KGlyphs.back,
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(title),
        actions: [
          ...actions,
          const SizedBox(width: KSpacing.sm),
        ],
      ),
      body:
          body ??
          ListView(
            padding: EdgeInsets.fromLTRB(
              KSpacing.gutter,
              KSpacing.lg,
              KSpacing.gutter,
              insets.bottom + KSpacing.xxl,
            ),
            children: children,
          ),
    );
  }
}

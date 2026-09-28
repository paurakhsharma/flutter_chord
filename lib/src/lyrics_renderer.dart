import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'chord_lyric_row.dart';
import 'chord_transposer.dart';
import 'song_document.dart';
import 'song_layout.dart';

/// Renders a song as one scrolling column of chord + lyric rows, with
/// optional linear auto-scroll.
class LyricsRenderer extends StatefulWidget {
  final String lyrics;
  final TextStyle textStyle;
  final TextStyle chordStyle;
  final bool showChord;
  final void Function(String chord) onTapChord;

  /// Transpose increment for the chords, in semitones.
  final int transposeIncrement;

  /// Auto-scroll speed in logical pixels per second; 0 means no scroll.
  final int scrollSpeed;

  /// Extra height between rows.
  final double lineHeight;

  /// Widget before the lyrics start.
  final Widget? leadingWidget;

  /// Widget after the lyrics finish.
  final Widget? trailingWidget;

  final CrossAxisAlignment horizontalAlignment;

  /// Scale factor of chords and lyrics.
  final double scaleFactor;

  /// Notation handled by the transposer.
  final ChordNotation chordNotation;

  final ScrollPhysics scrollPhysics;

  /// Defaults to the bold version of [textStyle].
  final TextStyle? chorusStyle;

  /// Defaults to the italic version of [textStyle].
  final TextStyle? capoStyle;

  /// Defaults to a smaller italic version of [textStyle].
  final TextStyle? commentStyle;

  /// Optional external scroll controller, otherwise created internally.
  final ScrollController? scrollController;

  /// Stanza scrolled to the top on first layout and after a reflow (font,
  /// width, chords, transpose). Out-of-range values are clamped.
  final int initialStanza;

  /// Called with the first stanza whose start is visible when scrolling
  /// settles, so a parent can restore the reading position elsewhere.
  final ValueChanged<int>? onStanzaChanged;

  const LyricsRenderer({
    super.key,
    required this.lyrics,
    required this.textStyle,
    required this.chordStyle,
    required this.onTapChord,
    this.chorusStyle,
    this.commentStyle,
    this.capoStyle,
    this.scaleFactor = 1.0,
    this.showChord = true,
    this.transposeIncrement = 0,
    this.scrollSpeed = 0,
    this.lineHeight = 8.0,
    this.horizontalAlignment = CrossAxisAlignment.center,
    this.scrollPhysics = const ClampingScrollPhysics(),
    this.leadingWidget,
    this.trailingWidget,
    this.chordNotation = ChordNotation.american,
    this.scrollController,
    this.initialStanza = 0,
    this.onStanzaChanged,
  });

  @override
  State<LyricsRenderer> createState() => _LyricsRendererState();
}

class _LyricsRendererState extends State<LyricsRenderer> {
  late final ScrollController _controller;

  String? _parsedLyrics;
  late SongDocument _document;

  Object? _layoutKey;
  late SongLayout _layout;

  /// Keys on each stanza's first row, to find where stanzas are.
  List<GlobalKey> _stanzaKeys = [];

  /// Stanza to keep at the top across reflows.
  late int _anchor = widget.initialStanza;

  @override
  void initState() {
    super.initState();
    _controller = widget.scrollController ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void dispose() {
    if (widget.scrollController == null) _controller.dispose();
    super.dispose();
  }

  LyricsStyle get _style => LyricsStyle(
        lyrics: widget.textStyle,
        chords: widget.chordStyle,
        chorus: widget.chorusStyle,
        comment: widget.commentStyle,
        textScaler: TextScaler.linear(widget.scaleFactor),
      );

  SongLayout _layoutFor(double maxWidth) {
    if (_parsedLyrics != widget.lyrics) {
      _document = parseSong(widget.lyrics);
      _parsedLyrics = widget.lyrics;
    }
    final style = _style;
    final key = Object.hash(
      _document,
      style,
      maxWidth,
      widget.transposeIncrement,
      widget.chordNotation,
      widget.showChord,
      widget.lineHeight,
    );
    if (key != _layoutKey) {
      _layout = layoutSong(
        _document,
        style: style,
        maxWidth: maxWidth,
        transpose: widget.transposeIncrement,
        notation: widget.chordNotation,
        showChords: widget.showChord,
        rowSpacing: widget.lineHeight,
      );
      final isReflow = _layoutKey != null;
      _layoutKey = key;
      if (_stanzaKeys.length != _layout.stanzas.length) {
        _stanzaKeys = [for (final _ in _layout.stanzas) GlobalKey()];
      }
      if (isReflow || _anchor > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToAnchor());
      }
    }
    return _layout;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final layout = _layoutFor(constraints.maxWidth);
      if (layout.stanzas.isEmpty) return const SizedBox();
      final style = _style;
      final capo = _document.capo;

      return NotificationListener<ScrollEndNotification>(
        onNotification: (_) {
          _updateAnchor();
          return false;
        },
        child: SingleChildScrollView(
          controller: _controller,
          physics: widget.scrollPhysics,
          child: Column(
            crossAxisAlignment: widget.horizontalAlignment,
            children: [
              if (widget.leadingWidget != null) widget.leadingWidget!,
              if (capo != null)
                Text(
                  'Capo: $capo',
                  style: widget.capoStyle ??
                      widget.textStyle.copyWith(fontStyle: FontStyle.italic),
                ),
              for (var s = 0; s < layout.stanzas.length; s++) ...[
                if (s > 0) SizedBox(height: layout.stanzaGap),
                for (var r = 0; r < layout.stanzas[s].rows.length; r++) ...[
                  if (r > 0) SizedBox(height: widget.lineHeight),
                  ChordLyricRow(
                    key: r == 0 ? _stanzaKeys[s] : null,
                    row: layout.stanzas[s].rows[r],
                    style: style,
                    onTapChord: widget.onTapChord,
                  ),
                ],
              ],
              if (widget.trailingWidget != null) widget.trailingWidget!,
            ],
          ),
        ),
      );
    });
  }

  /// Scroll offset that puts [stanza]'s first row at the top.
  double? _offsetOf(int stanza) {
    final box = _stanzaKeys[stanza].currentContext?.findRenderObject();
    if (box == null) return null;
    return RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
  }

  void _updateAnchor() {
    if (!_controller.hasClients) return;
    final offset = _controller.offset;
    for (var s = 0; s < _stanzaKeys.length; s++) {
      final top = _offsetOf(s);
      if (top != null && top >= offset - 1) {
        if (s != _anchor) {
          _anchor = s;
          widget.onStanzaChanged?.call(s);
        }
        return;
      }
    }
  }

  void _jumpToAnchor() {
    if (!mounted || !_controller.hasClients || _stanzaKeys.isEmpty) return;
    final stanza = _anchor.clamp(0, _stanzaKeys.length - 1);
    final top = stanza == 0 ? 0.0 : _offsetOf(stanza);
    if (top == null) return;
    _controller.jumpTo(top.clamp(0, _controller.position.maxScrollExtent));
  }

  @override
  void didUpdateWidget(covariant LyricsRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollSpeed != widget.scrollSpeed) _scrollToEnd();
  }

  void _scrollToEnd() {
    if (!_controller.hasClients) return;
    if (widget.scrollSpeed <= 0) {
      // Stop scrolling when the speed is 0 or less.
      _controller.jumpTo(_controller.offset);
      return;
    }

    final position = _controller.position;
    if (_controller.offset >= position.maxScrollExtent) return;

    final seconds = (position.maxScrollExtent / widget.scrollSpeed).floor();
    _controller.animateTo(
      position.maxScrollExtent,
      duration: Duration(seconds: seconds),
      curve: Curves.linear,
    );
  }
}

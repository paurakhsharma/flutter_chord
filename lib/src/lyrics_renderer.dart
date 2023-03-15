import 'package:flutter/material.dart';
import 'chord_transposer.dart';
import 'model/chord_lyrics_line.dart';
import 'chord_parser.dart';

class LyricsRenderer extends StatefulWidget {
  final String lyrics;
  final TextStyle textStyle;
  final TextStyle chordStyle;
  final bool showChord;
  final Function onTapChord;
  final Function onTap;

  /// To help stop overflow, this should be the sum of left & right padding
  final int widgetPadding;

  /// Transpose Increment for the Chords,
  /// default value is 0, which means no transpose is applied
  final int transposeIncrement;

  /// Auto Scroll Speed,
  /// default value is 0, which means no auto scroll is applied
  final int scrollSpeed;

  /// Extra height between each line
  final double lineHeight;

  /// Widget before the lyrics starts
  final Widget? leadingWidget;

  /// Widget after the lyrics finishes
  final Widget? trailingWidget;

  /// Horizontal alignment
  final CrossAxisAlignment horizontalAlignment;

  /// Scale factor of chords and lyrics
  final double scaleFactor;

  /// Notation that will be handled by the transposer
  final ChordNotation chordNotation;

  /// Define physics of scrolling
  final ScrollPhysics scrollPhysics;

  /// If not defined it will be the bold version of [textStyle]
  final TextStyle? chorusStyle;

  /// If not defined it will be the italic version of [textStyle]
  final TextStyle? capoStyle;

  // display the chord and lyrics on the same line
  final bool singleLine;

  // display chord after the word
  final bool chordAfter;

  const LyricsRenderer(
      {Key? key,
      required this.lyrics,
      required this.textStyle,
      required this.chordStyle,
      required this.onTapChord,
      required this.onTap,
      this.chorusStyle,
      this.capoStyle,
      this.scaleFactor = 1.0,
      this.showChord = true,
      this.widgetPadding = 0,
      this.transposeIncrement = 0,
      this.scrollSpeed = 0,
      this.lineHeight = 8.0,
      this.horizontalAlignment = CrossAxisAlignment.center,
      this.scrollPhysics = const ClampingScrollPhysics(),
      this.leadingWidget,
      this.trailingWidget,
      this.singleLine = true,
      this.chordAfter = true,
      this.chordNotation = ChordNotation.american})
      : super(key: key);

  @override
  State<LyricsRenderer> createState() => _LyricsRendererState();
}

class _LyricsRendererState extends State<LyricsRenderer> {
  late final ScrollController _controller;
  late TextStyle chorusStyle;
  late TextStyle capoStyle;
  bool _isChorus = false;
  var isPause = false;

  @override
  void initState() {
    super.initState();
    chorusStyle = widget.chorusStyle ??
        widget.textStyle.copyWith(fontWeight: FontWeight.bold);
    capoStyle = widget.capoStyle ??
        widget.textStyle.copyWith(fontStyle: FontStyle.italic);
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // executes after build
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ChordProcessor _chordProcessor =
        ChordProcessor(context, widget.chordNotation);
      final chordLyricsDocument = _chordProcessor.processText(
        text: widget.lyrics,
        lyricsStyle: widget.textStyle,
        chordStyle: widget.chordStyle,
        widgetPadding: widget.widgetPadding,
        scaleFactor: widget.scaleFactor,
        transposeIncrement: widget.transposeIncrement,
        singleLine: widget.singleLine,
        chordAfter: widget.chordAfter,
      );

    if (chordLyricsDocument.chordLyricsLines.isEmpty) return Container();
    return GestureDetector(
      onTap: () {
        widget.onTap();
        if (_controller.position.maxScrollExtent ==
            _controller.position.pixels) {
          isPause = true;
          return;
        }
        if (_controller.position.pixels == 0) {
          _scrollToEnd();
          return;
        }
        isPause = !isPause;
        if (!_controller.position.isScrollingNotifier.value &&
            isPause == true) {
          _scrollToEnd();
        }
      },
      child: SingleChildScrollView(
        controller: _controller,
        physics: widget.scrollPhysics,
        child: Column(
          crossAxisAlignment: widget.horizontalAlignment,
          children: [
            if (widget.leadingWidget != null) widget.leadingWidget!,
            if (chordLyricsDocument.capo != null)
              Text('Capo: ${chordLyricsDocument.capo!}', style: capoStyle),
            ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => SizedBox(
                height: widget.lineHeight,
              ),
              itemBuilder: (context, index) {
                final ChordLyricsLine line =
                    chordLyricsDocument.chordLyricsLines[index];
                if (line.isStartOfChorus()) {
                  _isChorus = true;
                }
                if (line.isEndOfChorus()) {
                  _isChorus = false;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showChord && !widget.singleLine)
                      Row(
                        children: line.chords
                            .map((chord) => Row(
                                  children: [
                                    SizedBox(
                                      width: chord.leadingSpace,
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          widget.onTapChord(chord.chordText),
                                      child: RichText(
                                        textScaleFactor: widget.scaleFactor,
                                        text: TextSpan(
                                          text: chord.chordText,
                                          style: widget.chordStyle,
                                        ),
                                      ),
                                    )
                                  ],
                                ))
                            .toList(),
                      ),
                    RichText(
                      textScaleFactor: widget.scaleFactor,
                      text: TextSpan(
                        text: line.lyrics,
                        style: _isChorus ? chorusStyle : widget.textStyle,
                      ),
                    )
                  ],
                );
              },
              itemCount: chordLyricsDocument.chordLyricsLines.length,
            ),
            if (widget.trailingWidget != null) widget.trailingWidget!,
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant LyricsRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollSpeed != widget.scrollSpeed) {
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    if (widget.scrollSpeed <= 0) {
      isPause = true;
      // stop scrolling if the speed is 0 or less
      _controller.jumpTo(_controller.offset);
      return;
    }

    if (_controller.offset >= _controller.position.maxScrollExtent) return;

    final seconds =
        (_controller.position.maxScrollExtent / (widget.scrollSpeed)).floor();

    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: Duration(
        seconds: seconds,
      ),
      curve: Curves.linear,
    );
  }
}

class TextRender extends CustomPainter {
  final String text;
  final TextStyle style;
  TextRender(this.text, this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: text,
      style: style,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

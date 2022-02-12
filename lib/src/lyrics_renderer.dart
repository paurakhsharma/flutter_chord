import 'package:flutter/material.dart';

import '../flutter_chord.dart';

class LyricsRenderer extends StatefulWidget {
  final String lyrics;
  final TextStyle textStyle;
  final TextStyle chordStyle;
  final bool showChord;
  final Function onTapChord;

  /// To help stop overflow, this should be the sum of left & right padding
  final int widgetPadding;

  /// Transpose Increment for the Chords,
  /// defaule value is 0, which means no transpose is applied
  final int transposeIncrement;

  /// Auto Scroll Speed,
  /// default value is 0, which means no auto scroll is applied
  final int scrollSpeed;

  const LyricsRenderer({
    Key? key,
    required this.lyrics,
    required this.textStyle,
    required this.chordStyle,
    required this.onTapChord,
    this.showChord = true,
    this.widgetPadding = 0,
    this.transposeIncrement = 0,
    this.scrollSpeed = 0,
  }) : super(key: key);

  @override
  State<LyricsRenderer> createState() => _LyricsRendererState();
}

class _LyricsRendererState extends State<LyricsRenderer> {
  late final ScrollController _controller;

  @override
  Widget build(BuildContext context) {
    ChordProcessor _chordProcessor = ChordProcessor(context);
    final chordLyricsDocument = _chordProcessor.processText(
      text: widget.lyrics,
      lyricsStyle: widget.textStyle,
      chordStyle: widget.chordStyle,
      widgetPadding: widget.widgetPadding,
      transposeIncrement: widget.transposeIncrement,
    );
    if (chordLyricsDocument.chordLyricsLines.isEmpty) return Container();
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            controller: _controller,
            physics: BouncingScrollPhysics(),
            separatorBuilder: (context, index) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final line = chordLyricsDocument.chordLyricsLines[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showChord)
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
                    text: TextSpan(
                      text: line.lyrics,
                      style: widget.textStyle,
                    ),
                  )
                ],
              );
            },
            itemCount: chordLyricsDocument.chordLyricsLines.length,
          ),
        ),
      ],
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

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      // executes after build
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class TextRender extends CustomPainter {
  final String text;
  final TextStyle style;
  TextRender(this.text, this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: this.text,
      style: this.style,
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

import 'package:flutter/material.dart';

import '../flutter_chord.dart';

class LyricsRenderer extends StatefulWidget {
  final String lyrics;
  final TextStyle textStyle;
  final TextStyle chordStyle;
  final bool showChord;
  final Function onTapChord;
  final int transposeIncrement;

  const LyricsRenderer({
    Key? key,
    required this.lyrics,
    required this.textStyle,
    required this.chordStyle,
    this.showChord = true,
    this.transposeIncrement = 0,
    required this.onTapChord,
  }) : super(key: key);

  @override
  State<LyricsRenderer> createState() => _LyricsRendererState();
}

class _LyricsRendererState extends State<LyricsRenderer> {
  @override
  Widget build(BuildContext context) {
    ChordProcessor _chordProcessor = ChordProcessor(context);
    final chordLyricsDocument = _chordProcessor.processText(
      text: widget.lyrics,
      lyricsStyle: widget.textStyle,
      chordStyle: widget.chordStyle,
      transposeIncrement: widget.transposeIncrement,
    );
    if (chordLyricsDocument.chordLyricsLines.isEmpty) return Container();
    return Column(
      children: [          
        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
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

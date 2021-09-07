import 'package:flutter/material.dart';

import '../flutter_chord.dart';

class LyricsRenderer extends StatelessWidget {
  final String lyrics;
  final TextStyle textStyle;
  final TextStyle chordStyle;
  final bool showChord;
  final Function onTapChord;

  const LyricsRenderer({
    Key? key,
    required this.lyrics,
    required this.textStyle,
    required this.chordStyle,
    this.showChord = true,
    required this.onTapChord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ChordProcessor _chordProcessor = ChordProcessor(context);
    final chordLyricsDocument = _chordProcessor.processText(
      text: lyrics,
      lyricsStyle: textStyle,
      chordStyle: chordStyle,
    );
    if (chordLyricsDocument.chordLyricsLines.isEmpty) return Container();
    return ListView.separated(
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      physics: BouncingScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final line = chordLyricsDocument.chordLyricsLines[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showChord)
              Row(
                children: line.chords
                    .map((chord) => Row(
                          children: [
                            SizedBox(
                              width: chord.leadingSpace,
                            ),
                            GestureDetector(
                              onTap: () => onTapChord(chord.chordText),
                              child: RichText(
                                text: TextSpan(
                                  text: chord.chordText,
                                  style: chordStyle,
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
                style: textStyle,
              ),
            )
          ],
        );
      },
      itemCount: chordLyricsDocument.chordLyricsLines.length,
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

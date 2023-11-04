import 'package:flutter/material.dart';
import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can parse single line chord', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, _) {
          String text = '[C]This is t[D]he lyrics[E]';
          final textStyle = TextStyle(fontSize: 18, color: Colors.green);

          final processor = ChordProcessor(context);
          final chordDocument = processor.processText(
            text: text,
            lyricsStyle: textStyle,
            chordStyle: textStyle,
            chorusStyle: textStyle,
          );

          expect(
            chordDocument.chordLyricsLines.length,
            1,
          );
          expect(
            chordDocument.chordLyricsLines.first.chords.length,
            3,
          );
          expect(
            chordDocument.chordLyricsLines.first.chords.first.chordText,
            'C',
          );
          expect(
            chordDocument.chordLyricsLines.first.chords.first.leadingSpace,
            0.0,
          );

          expect(
            chordDocument.chordLyricsLines.first.chords[1].chordText,
            'D',
          );

          final textWidth = processor.textWidth('This is t', textStyle);
          final chordWidth = processor.textWidth('C', textStyle);
          expect(
            chordDocument.chordLyricsLines.first.chords[1].leadingSpace,
            textWidth - chordWidth,
          );

          // The builder function must return a widget.
          return Container();
        },
      ),
    );
  });

  testWidgets('Can parse multiple lines lyrics', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, _) {
          String text =
              '[C]This is t[D]he lyrics[E]\n[A]This is t[D]he se[B]cond line[E]';
          final textStyle = TextStyle(fontSize: 18, color: Colors.green);

          final processor = ChordProcessor(context);
          final chordDocument = processor.processText(
            text: text,
            lyricsStyle: textStyle,
            chordStyle: textStyle,
            chorusStyle: textStyle,
          );

          expect(
            chordDocument.chordLyricsLines.length,
            2,
          );
          expect(
            chordDocument.chordLyricsLines.last.chords.length,
            4,
          );
          expect(
            chordDocument.chordLyricsLines.last.chords.last.chordText,
            'E',
          );
          expect(
            chordDocument.chordLyricsLines.first.chords.first.leadingSpace,
            0.0,
          );

          expect(
            chordDocument.chordLyricsLines.first.chords[1].chordText,
            'D',
          );

          final textWidth = processor.textWidth('This is t', textStyle);
          final chordWidth = processor.textWidth('C', textStyle);
          expect(
            chordDocument.chordLyricsLines.first.chords[1].leadingSpace,
            textWidth - chordWidth,
          );

          // The builder function must return a widget.
          return Container();
        },
      ),
    );
  });

  testWidgets('Can parse title, artist and capo lines in lyrics',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, _) {
          String text =
              '{capo: 3}\n{title: Test title}\n{artist: artist test}\n[C]This is t[D]he lyrics[E]\n[A]This is t[D]he se[B]cond line[E]';
          final textStyle = TextStyle(fontSize: 18, color: Colors.green);

          final processor = ChordProcessor(context);
          final chordDocument = processor.processText(
            text: text,
            lyricsStyle: textStyle,
            chordStyle: textStyle,
            chorusStyle: textStyle,
          );

          expect(chordDocument.capo, 3);
          expect(chordDocument.artist, 'artist test');
          expect(chordDocument.title, 'Test title');

          expect(
            chordDocument.chordLyricsLines.length,
            2,
          );
          expect(
            chordDocument.chordLyricsLines.last.chords.length,
            4,
          );
          expect(
            chordDocument.chordLyricsLines.last.chords.last.chordText,
            'E',
          );
          expect(
            chordDocument.chordLyricsLines.first.chords.first.leadingSpace,
            0.0,
          );

          expect(
            chordDocument.chordLyricsLines.first.chords[1].chordText,
            'D',
          );

          final textWidth = processor.textWidth('This is t', textStyle);
          final chordWidth = processor.textWidth('C', textStyle);
          expect(
            chordDocument.chordLyricsLines.first.chords[1].leadingSpace,
            textWidth - chordWidth,
          );

          // The builder function must return a widget.
          return Container();
        },
      ),
    );
  });

  testWidgets('Can split long lyrics into multiple lines',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, _) {
          String text =
              '[C]This is t[D]he lyrics[E] [A]This is t[D]he se[B]cond line[E] This [A]makes it [G]overflow';
          final textStyle = TextStyle(fontSize: 18, color: Colors.green);

          final processor = ChordProcessor(context);
          final chordDocument = processor.processText(
            text: text,
            lyricsStyle: textStyle,
            chordStyle: textStyle,
            chorusStyle: textStyle,
          );

          expect(
            chordDocument.chordLyricsLines.length,
            2,
          );
          expect(
            chordDocument.chordLyricsLines.first.chords.length,
            7,
          );
          expect(
            chordDocument.chordLyricsLines.last.lyrics,
            'This makes it overflow',
          );
          expect(
            chordDocument.chordLyricsLines.first.chords.first.leadingSpace,
            0.0,
          );

          expect(
            chordDocument.chordLyricsLines.first.chords.last.chordText,
            'E',
          );

          expect(
            chordDocument.chordLyricsLines.last.chords.first.chordText,
            'A',
          );

          // The builder function must return a widget.
          return Container();
        },
      ),
    );
  });
}

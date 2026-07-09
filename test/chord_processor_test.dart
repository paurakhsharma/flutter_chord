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
            breakingCharacters: [' '],
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
              '{soc}\n[C]This is t[D]he Cho[D]rus\n{eoc}\n[C]This is t[D]he lyrics[E]\n[A]This is t[D]he se[B]cond line[E]';
          final textStyle = TextStyle(fontSize: 18, color: Colors.green);
          final chorusStyle = TextStyle(
              fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white);

          final processor = ChordProcessor(context);
          final chordDocument = processor.processText(
            text: text,
            lyricsStyle: textStyle,
            chordStyle: textStyle,
            chorusStyle: chorusStyle,
            breakingCharacters: [' '],
          );

          expect(
            chordDocument.chordLyricsLines.length,
            5,
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
            chordDocument.chordLyricsLines[1].chords.first.leadingSpace,
            0.0,
          );
          expect(
            chordDocument.chordLyricsLines[1].chords[1].chordText,
            'D',
          );

          final textWidth = processor.textWidth('This is t', textStyle);
          final chordWidth = processor.textWidth('C', textStyle);
          expect(
            chordDocument.chordLyricsLines[3].chords[1].leadingSpace,
            textWidth - chordWidth,
          );

          final chorusTextWidth = processor.textWidth('This is t', chorusStyle);
          final chorusChordWidth = processor.textWidth('C', textStyle);
          expect(
            chordDocument.chordLyricsLines[1].chords[1].leadingSpace,
            chorusTextWidth - chorusChordWidth,
          ); // The builder function must return a widget.
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
            breakingCharacters: [' '],
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
            breakingCharacters: [' '],
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

  testWidgets('Can split lyrics based on custom break',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, _) {
          String text =
              '[C]もーもたろさんももたろさん、おこしにつけた[D]…[C]もーもたろさんももたろさん、おこしにつけた[D]…';
          final textStyle = TextStyle(fontSize: 22, color: Colors.green);

          final processor = ChordProcessor(context);
          final chordDocument = processor.processText(
            text: text,
            lyricsStyle: textStyle,
            chordStyle: textStyle,
            chorusStyle: textStyle,
            breakingCharacters: ['、', '…'],
          );

          expect(
            chordDocument.chordLyricsLines.length,
            2,
          );
          expect(
            chordDocument.chordLyricsLines.first.chords.length,
            3,
          );
          expect(
            chordDocument.chordLyricsLines.last.lyrics,
            'おこしにつけた…',
          );
          expect(
            chordDocument.chordLyricsLines.first.chords.first.leadingSpace,
            0.0,
          );

          expect(
            chordDocument.chordLyricsLines.first.chords.last.chordText,
            'C',
          );

          expect(
            chordDocument.chordLyricsLines.last.chords.first.chordText,
            'D',
          );

          // The builder function must return a widget.
          return Container();
        },
      ),
    );
  });

  testWidgets(
      'Chord positions do not drift on a line with many chords — '
      'regression test for a bug where a chord gap measured from the '
      "line's absolute start (instead of from the previous chord) "
      'double-counted earlier text, pushing later chords in a line '
      'progressively further right than their real position',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, _) {
          String text = '[Dm]Deep[F] into[C] the[G] night we go';
          final textStyle = TextStyle(fontSize: 18, color: Colors.green);

          final processor = ChordProcessor(context);
          final chordDocument = processor.processText(
            text: text,
            lyricsStyle: textStyle,
            chordStyle: textStyle,
            chorusStyle: textStyle,
            breakingCharacters: [' '],
          );

          final line = chordDocument.chordLyricsLines.single;
          expect(line.chords.length, 4);

          // The plain lyrics reconstructed by the processor, with each
          // chord's known attachment point.
          expect(line.lyrics, 'Deep into the night we go');
          const attachPoints = [0, 4, 9, 13];
          var runningX = 0.0;
          for (var i = 0; i < line.chords.length; i++) {
            runningX += line.chords[i].leadingSpace;
            final expectedX = processor.textWidth(
              line.lyrics.substring(0, attachPoints[i]),
              textStyle,
            );
            expect(
              runningX,
              closeTo(expectedX, 0.5),
              reason: 'chord ${line.chords[i].chordText} drifted from its '
                  'expected position',
            );
            runningX +=
                processor.textWidth(line.chords[i].chordText, textStyle);
          }

          // The builder function must return a widget.
          return Container();
        },
      ),
    );
  });
}

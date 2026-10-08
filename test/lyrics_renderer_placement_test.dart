import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/real_songs.dart';

/// Phone portrait and iPad landscape screens.
const screens = [Size(390, 844), Size(1194, 834)];

/// Pumps the renderer the way the song display screen does (12 pt side
/// padding, start-aligned) and reads back what was painted.
Future<List<RenderedLine>> renderSong(
  WidgetTester tester,
  Size screen,
  String lyrics, {
  bool showChord = true,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LyricsRenderer(
            lyrics: lyrics,
            textStyle: lyricStyle,
            chordStyle: chordStyle,
            showChord: showChord,
            onTapChord: (_) {},
          ),
        ),
      ),
    ),
  );

  // Paint order: each line's chord texts, then its lyric text.
  final lines = <RenderedLine>[];
  var pendingChords = <(String, double)>[];
  for (final element in find.byType(RichText).evaluate()) {
    final widget = element.widget as RichText;
    final span = widget.text as TextSpan;
    final left = tester.getTopLeft(find.byWidget(widget)).dx;
    if (span.style == chordStyle) {
      pendingChords.add((span.text!, left));
      continue;
    }
    lines.add(RenderedLine(span.text!, [
      for (final (text, x) in pendingChords) RenderedChord(text, x - left),
    ]));
    pendingChords = [];
  }
  return lines;
}

/// Lyric rows that wrapped onto a second visual line or were cut off,
/// either of which leaves the chord row above out of step.
List<String> wrappedRows(WidgetTester tester) {
  final singleLine = (TextPainter(
    text: const TextSpan(text: 'A', style: lyricStyle),
    textDirection: TextDirection.ltr,
  )..layout())
      .height;
  return [
    for (final paragraph
        in tester.renderObjectList<RenderParagraph>(find.byType(RichText)))
      if ((paragraph.text as TextSpan).style != chordStyle &&
          (paragraph.didExceedMaxLines ||
              paragraph.size.height > singleLine * 1.5))
        '"${(paragraph.text as TextSpan).text}" does not fit one line',
  ];
}

void main() {
  final songs = loadRealSongs();

  for (final song in songs) {
    for (final screen in screens) {
      final label = '${song.category} ${screen.width.round()}w';

      testWidgets('$label: painted chords sit over their syllables',
          (tester) async {
        final lines = await renderSong(tester, screen, song.nepaliLyrics);
        final violations = placementViolations(
          source: song.nepaliLyrics,
          lines: lines,
          maxWidth: screen.width - horizontalPadding,
        );
        expect(violations, isEmpty, reason: violations.join('\n'));
      });

      testWidgets('$label: every lyric row stays on one line', (tester) async {
        await renderSong(tester, screen, song.nepaliLyrics);
        final wrapped = wrappedRows(tester);
        expect(wrapped, isEmpty, reason: wrapped.join('\n'));
      });
    }

    testWidgets('${song.category}: chords off hides every chord',
        (tester) async {
      final lines = await renderSong(
        tester,
        screens.first,
        song.nepaliLyrics,
        showChord: false,
      );
      expect(lines.expand((l) => l.chords), isEmpty);
      expect(lines, isNotEmpty);
    });
  }
}

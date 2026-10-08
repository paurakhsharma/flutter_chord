import 'package:flutter/material.dart';
import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/real_songs.dart';

void main() {
  final longest =
      loadRealSongs().firstWhere((s) => s.category == 'longest').nepaliLyrics;
  final stanzas = parseSong(longest).stanzas;

  Widget renderer({required double fontSize, int initialStanza = 0}) {
    return MaterialApp(
      home: Scaffold(
        body: LyricsRenderer(
          lyrics: longest,
          textStyle: lyricStyle.copyWith(fontSize: fontSize),
          chordStyle: chordStyle,
          onTapChord: (_) {},
          initialStanza: initialStanza,
        ),
      ),
    );
  }

  /// Top of the lyric row that starts [stanza], relative to the screen.
  double topOfStanza(WidgetTester tester, int stanza) {
    // The first painted row is a prefix of the first line (it may wrap).
    final firstLine = stanzas[stanza].lines.first.lyrics;
    final row = find.byWidgetPredicate((widget) {
      if (widget is! RichText) return false;
      final text = (widget.text as TextSpan).text ?? '';
      return text.length > 3 && firstLine.startsWith(text);
    });
    return tester.getTopLeft(row.first).dy;
  }

  testWidgets('opens at the initial stanza', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(renderer(fontSize: 20, initialStanza: 4));
    await tester.pumpAndSettle();

    // Chord row sits above the lyric row, so allow its height.
    expect(topOfStanza(tester, 4), inInclusiveRange(0, 40));
  });

  testWidgets('keeps the reading stanza at the top after a font change',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(renderer(fontSize: 20));
    // Scroll until stanza 3 is the first one starting on screen.
    await tester.drag(
      find.byType(SingleChildScrollView),
      Offset(0, -(topOfStanza(tester, 3) - 30)),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(renderer(fontSize: 26));
    await tester.pumpAndSettle();

    expect(topOfStanza(tester, 3), inInclusiveRange(0, 40));
  });

  testWidgets('reports the reading stanza when scrolling settles',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final reported = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LyricsRenderer(
          lyrics: longest,
          textStyle: lyricStyle,
          chordStyle: chordStyle,
          onTapChord: (_) {},
          onStanzaChanged: reported.add,
        ),
      ),
    ));
    await tester.drag(
      find.byType(SingleChildScrollView),
      Offset(0, -(topOfStanza(tester, 2) - 30)),
    );
    await tester.pumpAndSettle();

    expect(reported.last, 2);
  });
}

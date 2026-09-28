import 'package:flutter_test/flutter_test.dart';

import 'support/real_songs.dart';

/// Phone portrait, a 2-column iPad column, and a wide 1-column window.
const widths = [360.0, 568.0, 1168.0];

/// Lays [text] out as if the screen were [width] wide.
Future<List<RenderedLine>> layoutAt(
  WidgetTester tester,
  double width,
  String text, {
  int transpose = 0,
}) async =>
    renderLines(
      text,
      maxWidth: width - horizontalPadding,
      transpose: transpose,
    );

Future<void> expectPlacement(
  WidgetTester tester,
  double width,
  String text, {
  int transpose = 0,
}) async {
  final lines = await layoutAt(tester, width, text, transpose: transpose);
  final violations = placementViolations(
    source: text,
    lines: lines,
    maxWidth: width - horizontalPadding,
    transpose: transpose,
  );
  expect(violations, isEmpty, reason: violations.join('\n'));
}

void main() {
  final songs = loadRealSongs();

  group('real songs', () {
    for (final song in songs) {
      for (final version in song.versions.entries) {
        for (final width in widths) {
          for (final transpose in [0, 2]) {
            testWidgets(
              '${song.category} ${version.key} w${width.round()} '
              't$transpose: chords stay over their syllables',
              (tester) => expectPlacement(
                tester,
                width,
                version.value,
                transpose: transpose,
              ),
            );
          }
        }
      }
    }
  });

  group('transpose', () {
    for (final song in songs) {
      testWidgets('${song.category}: keeps the text and chord count',
          (tester) async {
        final original = await layoutAt(tester, 568, song.nepaliLyrics);
        final transposed = await layoutAt(
          tester,
          568,
          song.nepaliLyrics,
          transpose: 3,
        );
        // Rows can re-wrap: a wider chord name at a line end moves the
        // last word down with it. The text and chords stay the same.
        String text(List<RenderedLine> lines) =>
            lines.map((l) => l.lyrics.trim()).join(' ');
        int chords(List<RenderedLine> lines) =>
            lines.fold(0, (sum, l) => sum + l.chords.length);
        expect(text(transposed), text(original));
        expect(chords(transposed), chords(original));
      });
    }
  });

  group('edge cases', () {
    final cases = {
      'chord at line end': 'यो जीवन स्वर्गमा[C]',
      'chord at line start': '[G]स्वर्ग जाने मुल बाटो',
      'adjacent chords': '[C][G]हो उद्धार आज छ',
      'adjacent chords then room': '[C][G]हो उद्धार आज छ [Am]येशू',
      'chords only': '[Am]  [G]  [C]',
      'chord mid-word': 'भेट्[Am]टायौं',
      'repeat brackets': '([D]पबि[A]त्रता)-३ ख्री[D]ष्ट',
      'label prefix': 'को: ([A]येशुमा [Bm]बिश्वास गरि [A]मुक्ति',
      'slash and extended chords': '[C/E]मेरो [Gsus4]येशू [F#m7]राजा',
      'very long line': List.filled(
        12,
        '[C]आराधनाको [G]बाटो [Am]भएर',
      ).join(' '),
      'long line, chord at break': List.filled(
        20,
        'आराधनाको[D]',
      ).join(' '),
      'multiple spaces': 'हो   [C]उद्धार    [G]आज',
      'latin label line': 'Verse 2\n[G]Swagat [D]gardachhau',
    };
    for (final entry in cases.entries) {
      for (final width in widths) {
        testWidgets('${entry.key} w${width.round()}',
            (tester) => expectPlacement(tester, width, entry.value));
      }
    }
  });
}

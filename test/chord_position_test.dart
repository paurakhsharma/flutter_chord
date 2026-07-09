import 'package:flutter/material.dart';
import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';

const _lyricStyle = TextStyle(fontSize: 18, color: Colors.green);
const _chordStyle = TextStyle(fontSize: 14, color: Colors.white);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first chord leading space equals width of lyrics before it', () {
    const lyrics = 'This is the lyrics';
    final positions = computeChordPositions(
      lyrics: lyrics,
      charIndices: const [8],
      chordTexts: const ['C'],
      lyricStyle: _lyricStyle,
      chordStyle: _chordStyle,
    );

    expect(
      positions.single.leadingSpace,
      measureTextWidth('This is ', _lyricStyle),
    );
  });

  test(
      'second chord leading space is measured since the previous chord, '
      'not from the start of the line', () {
    const lyrics = 'This is the lyrics';
    final positions = computeChordPositions(
      lyrics: lyrics,
      charIndices: const [4, 8],
      chordTexts: const ['C', 'D'],
      lyricStyle: _lyricStyle,
      chordStyle: _chordStyle,
    );

    expect(
      positions[1].leadingSpace,
      measureTextWidth(' is ', _lyricStyle) -
          measureTextWidth('C', _chordStyle),
    );
  });

  test(
      'cumulative x-offset of every chord matches its charIndex in the '
      'lyrics — regression test for the drift bug where measuring each '
      "chord's gap from the line's absolute start (instead of from the "
      'previous chord) double-counted earlier text and pushed later chords '
      'in a line further right than they belonged, eventually off the edge '
      'of their container', () {
    const lyrics = 'Dm F C G rest of the line keeps going';
    const chordTexts = ['Dm', 'F', 'C', 'G'];
    const charIndices = [0, 3, 5, 7];

    final positions = computeChordPositions(
      lyrics: lyrics,
      charIndices: charIndices,
      chordTexts: chordTexts,
      lyricStyle: _lyricStyle,
      chordStyle: _chordStyle,
    );

    var cumulativeX = 0.0;
    for (var i = 0; i < positions.length; i++) {
      cumulativeX += positions[i].leadingSpace;
      final expectedX =
          measureTextWidth(lyrics.substring(0, charIndices[i]), _lyricStyle);
      expect(
        cumulativeX,
        closeTo(expectedX, 0.5),
        reason: 'chord ${chordTexts[i]} (position $i) drifted from its '
            'charIndex position',
      );
      cumulativeX += measureTextWidth(chordTexts[i], _chordStyle);
    }
  });

  test('leadingSpace is never negative when a chord overlaps the gap', () {
    const lyrics = 'Hi C';
    final positions = computeChordPositions(
      lyrics: lyrics,
      charIndices: const [0, 1],
      chordTexts: const ['Asus4', 'B'],
      lyricStyle: _lyricStyle,
      chordStyle: _chordStyle,
    );

    for (final position in positions) {
      expect(position.leadingSpace, greaterThanOrEqualTo(0));
    }
  });

  test('empty charIndices returns empty positions', () {
    final positions = computeChordPositions(
      lyrics: 'no chords here',
      charIndices: const [],
      chordTexts: const [],
      lyricStyle: _lyricStyle,
      chordStyle: _chordStyle,
    );

    expect(positions, isEmpty);
  });
}

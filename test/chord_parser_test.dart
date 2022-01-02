import 'package:flutter/material.dart';
import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  test(
    'Can transpose chord by 1',
    () {
      final chordTable = [
        ["C", "C#"],
        ["C#", "D"],
        ["D", "D#"],
        ["E", "F"],
        ["A#", "B"],
      ];
      final context = MockBuildContext();
      for (var chordPair in chordTable) {
        final transposedChord = ChordProcessor(context).transposeChord(
          chordPair[0],
          1,
        );
        expect(transposedChord, chordPair[1]);
      }
    },
  );

  test(
    'Can transpose chord by 2',
    () {
      final chordTable = [
        ["C", "D"],
        ["C#", "D#"],
        ["D", "E"],
        ["D#", "F"],
        ["E", "F#"],
      ];
      final context = MockBuildContext();
      for (var chordPair in chordTable) {
        final transposedChord = ChordProcessor(context).transposeChord(
          chordPair[0],
          2,
        );
        expect(transposedChord, chordPair[1]);
      }
    },
  );
}

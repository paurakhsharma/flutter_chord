import 'package:flutter/material.dart';
import 'package:flutter_chord/src/chord_transposer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  test(
    'Can transpose american chord by 1',
    () {
      final chordTable = [
        ["C", "C#"],
        ["C#", "D"],
        ["D", "D#"],
        ["E", "F"],
        ["A#", "B"],
      ];
      for (var chordPair in chordTable) {
        final transposedChord =
            ChordTransposer(ChordNotation.american, transpose: 1)
                .transposeChord(chordPair[0]);
        expect(transposedChord, chordPair[1]);
      }
    },
  );

  test(
    'Can transpose italian chord by 1',
    () {
      final chordTable = [
        ["Do", "Do#"],
        ["Do#", "Re"],
        ["Re", "Re#"],
        ["Mi", "Fa"],
        ["La#", "Si"],
      ];
      for (var chordPair in chordTable) {
        final transposedChord =
            ChordTransposer(ChordNotation.italian, transpose: 1)
                .transposeChord(chordPair[0]);
        expect(transposedChord, chordPair[1]);
      }
    },
  );

  test(
    'Can transpose flat italian chord by 1',
    () {
      final chordTable = [
        ["Dob", "Do"],
        ["Sib", "Si"],
        ["Mib", "Mi"],
        ["Reb", "Re"],
      ];
      for (var chordPair in chordTable) {
        final transposedChord =
            ChordTransposer(ChordNotation.italian, transpose: 1)
                .transposeChord(chordPair[0]);
        expect(transposedChord, chordPair[1]);
      }
    },
  );

  test(
    'Can transpose more complex italian chords by 1',
    () {
      final chordTable = [
        ["Dob7", "Do7"],
        ["Si7/5", "Do7/5"],
        ["Sol/Si", "Sol#/Do"],
        ["Re4/7", "Re#4/7"],
        ["Doadd9", "Do#add9"],
      ];
      for (var chordPair in chordTable) {
        final transposedChord =
            ChordTransposer(ChordNotation.italian, transpose: 1)
                .transposeChord(chordPair[0]);
        expect(transposedChord, chordPair[1]);
      }
    },
  );

  test(
    'Can transpose more complex american chords by 1',
    () {
      final chordTable = [
        ["Cb7", "C7"],
        ["B7/5", "C7/5"],
        ["G/B", "G#/C"],
        ["D4/7", "D#4/7"],
        ["Cadd9", "C#add9"],
      ];
      for (var chordPair in chordTable) {
        final transposedChord =
            ChordTransposer(ChordNotation.american, transpose: 1)
                .transposeChord(chordPair[0]);
        expect(transposedChord, chordPair[1]);
      }
    },
  );

  test(
    'Can transpose american chord by 2',
    () {
      final chordTable = [
        ["C", "D"],
        ["C#", "D#"],
        ["D", "E"],
        ["D#", "F"],
        ["E", "F#"],
      ];
      for (var chordPair in chordTable) {
        final transposedChord =
            ChordTransposer(ChordNotation.american, transpose: 2)
                .transposeChord(chordPair[0]);
        expect(transposedChord, chordPair[1]);
      }
    },
  );

  test(
    'Can transpose italian chord by 2',
    () {
      final chordTable = [
        ["Do", "Re"],
        ["Do#", "Re#"],
        ["Re", "Mi"],
        ["Mi", "Fa#"],
        ["Re#", "Fa"],
        ["La#", "Do"],
      ];
      for (var chordPair in chordTable) {
        final transposedChord =
            ChordTransposer(ChordNotation.italian, transpose: 2)
                .transposeChord(chordPair[0]);
        expect(transposedChord, chordPair[1]);
      }
    },
  );
}

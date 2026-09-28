import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseLine', () {
    test('lifts chords out at the index of the following character', () {
      final line = parseLine('[C]This is t[D]he lyrics[E]');
      expect(line.lyrics, 'This is the lyrics');
      expect(line.chords, const [
        ChordMark(0, 'C'),
        ChordMark(9, 'D'),
        ChordMark(18, 'E'),
      ]);
    });

    test('keeps whitespace between chords on a chords-only line', () {
      final line = parseLine('[Am]  [G]  [C]');
      expect(line.lyrics, '    ');
      expect(line.chords, const [
        ChordMark(0, 'Am'),
        ChordMark(2, 'G'),
        ChordMark(4, 'C'),
      ]);
    });

    test('keeps adjacent chords at the same index', () {
      final line = parseLine('[C][G]हो');
      expect(line.chords, const [ChordMark(0, 'C'), ChordMark(0, 'G')]);
    });

    test('keeps an unclosed bracket as lyrics', () {
      final line = parseLine('see [ref');
      expect(line.lyrics, 'see [ref');
      expect(line.chords, isEmpty);
    });
  });

  group('parseSong', () {
    test('splits stanzas on blank lines, collapsing repeats', () {
      final song = parseSong('a\nb\n\n\n\nc\n');
      expect(song.stanzas.map((s) => s.lines.map((l) => l.lyrics)), [
        ['a', 'b'],
        ['c'],
      ]);
    });

    test('trims source lines before lifting chords', () {
      final song = parseSong('   [G]स्वर्ग जाने  ');
      expect(song.lines.single.lyrics, 'स्वर्ग जाने');
      expect(song.lines.single.chords, const [ChordMark(0, 'G')]);
    });

    test('reads metadata and leaves it out of the lyrics', () {
      final song = parseSong(
        '{title: Song}\n{artist: Someone}\n{key: G}\n{capo: 2}\n[G]words',
      );
      expect(song.title, 'Song');
      expect(song.artist, 'Someone');
      expect(song.key, 'G');
      expect(song.capo, 2);
      expect(song.lines.map((l) => l.lyrics), ['words']);
    });

    test('marks lines inside {soc} … {eoc} as chorus', () {
      final song = parseSong('verse\n{soc}\nsing\nloud\n{eoc}\nafter');
      expect(
        song.lines.map((l) => '${l.lyrics}:${l.isChorus}'),
        ['verse:false', 'sing:true', 'loud:true', 'after:false'],
      );
    });

    test('reads {comment: } lines', () {
      final line = parseSong('{comment: Slowly}').lines.single;
      expect(line.lyrics, 'Slowly');
      expect(line.kind, LineKind.comment);
    });

    test('treats a lone short chordless line as a label', () {
      final song = parseSong(
        'Verse 2\n\n[G]Swagat [D]gardachhau\n\nकोरस\n\n'
        '[C]a line\n\nIntro : D | C | D | C |',
      );
      expect(song.stanzas.map((s) => s.isLabel), [
        true,
        false,
        true,
        false,
        true,
      ]);
    });

    test('lists chord names in reading order', () {
      final song = parseSong('[C]a [G]b\n\n[Am]c');
      expect(song.chordNames, ['C', 'G', 'Am']);
    });
  });
}

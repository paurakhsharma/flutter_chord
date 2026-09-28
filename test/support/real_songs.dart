import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chord/flutter_chord.dart';

/// Real songs from the Nepali Christian Lyrics catalog, picked to cover
/// the shapes that matter for layout (very short, median, p90, longest,
/// chorus-heavy, long lines, Latin script + section labels, description).
class RealSong {
  final String category;
  final String name;
  final String nepaliLyrics;
  final String? translitLyrics;

  const RealSong(
    this.category,
    this.name,
    this.nepaliLyrics,
    this.translitLyrics,
  );

  /// Nepali lyrics plus the transliteration when the song has one.
  Map<String, String> get versions => {
        'nepali': nepaliLyrics,
        if (translitLyrics != null && translitLyrics!.isNotEmpty)
          'roman': translitLyrics!,
      };
}

List<RealSong> loadRealSongs() {
  final file = File('test/fixtures/songs.json');
  final json = jsonDecode(file.readAsStringSync()) as List;
  return [
    for (final song in json.cast<Map<String, dynamic>>())
      RealSong(
        song['fixtureCategory'] as String,
        song['name'] as String,
        song['nepaliLyrics'] as String,
        song['translitLyrics'] as String?,
      ),
  ];
}

// Styles close to the app's song display (lyrics 20, chords 14).
const lyricStyle = TextStyle(fontSize: 20, height: 1.6);
const chordStyle = TextStyle(
  fontSize: 14,
  height: 1.6,
  letterSpacing: 0.8,
  fontWeight: FontWeight.w500,
);
/// Horizontal padding around the lyrics in the song display screen.
const horizontalPadding = 24.0;

/// A chord as rendered: its text and x offset from the lyric line's start.
class RenderedChord {
  final String text;
  final double x;

  const RenderedChord(this.text, this.x);

  @override
  String toString() => '$text@${x.toStringAsFixed(1)}';
}

/// One rendered row pair: the chord row above and the lyric row below.
class RenderedLine {
  final String lyrics;
  final List<RenderedChord> chords;

  const RenderedLine(this.lyrics, this.chords);

  @override
  String toString() => 'RenderedLine("$lyrics", $chords)';
}

/// The single entry point into the package's layout. Everything else in
/// the placement tests is independent of the package API, so a redesign
/// only has to change this function.
List<RenderedLine> renderLines(
  String text, {
  required double maxWidth,
  int transpose = 0,
}) {
  final layout = layoutSong(
    parseSong(text),
    style: LyricsStyle(lyrics: lyricStyle, chords: chordStyle),
    maxWidth: maxWidth,
    transpose: transpose,
  );
  return [
    for (final row in layout.rows)
      RenderedLine(row.lyrics, [
        for (final chord in row.chords) RenderedChord(chord.name, chord.x),
      ]),
  ];
}

final _chordPattern = RegExp(r'\[([^\]]*)\]');
final _metadataPattern = RegExp(r'^ *\{.*}');

/// A chord in the source text, anchored to the count of non-space lyric
/// characters before it in the whole song, plus the spaces between the
/// last of those letters (or the line start) and the chord. Letters are
/// counted without whitespace because wrapping is allowed to trim it.
class SourceChord {
  final String text;
  final int anchor;
  final int gap;

  const SourceChord(this.text, this.anchor, this.gap);
}

class SourceSong {
  /// All lyric characters of the song with chords and whitespace removed.
  final String letters;
  final List<SourceChord> chords;

  const SourceSong(this.letters, this.chords);
}

/// Reads the `[X]` markup straight from the source text, independently of
/// the package parser.
SourceSong parseSource(String text, {int transpose = 0}) {
  final transposer = ChordTransposer(
    ChordNotation.american,
    transpose: transpose,
  );
  final letters = StringBuffer();
  final chords = <SourceChord>[];
  for (final rawLine in text.split('\n')) {
    if (_metadataPattern.hasMatch(rawLine)) continue;
    // Lines are trimmed before rendering.
    final line = rawLine.trim();
    var cursor = 0;
    var gap = 0;
    void consume(String lyrics) {
      for (final char in lyrics.split('')) {
        if (char.trim().isEmpty) {
          gap++;
        } else {
          letters.write(char);
          gap = 0;
        }
      }
    }

    for (final match in _chordPattern.allMatches(line)) {
      consume(line.substring(cursor, match.start));
      chords.add(SourceChord(
        transposer.transposeChord(match.group(1)!),
        letters.length,
        gap,
      ));
      cursor = match.end;
    }
    consume(line.substring(cursor));
  }
  return SourceSong(letters.toString(), chords);
}

String _stripSpace(String text) => text.replaceAll(RegExp(r'\s'), '');

/// Index in [lyrics] where a chord with [letters] non-space characters
/// and then [gap] spaces before it attaches. At the start of a wrapped row
/// the gap can only be as wide as the whitespace that survived trimming.
int chordCharIndex(String lyrics, int letters, int gap) {
  var index = 0;
  var seen = 0;
  while (seen < letters && index < lyrics.length) {
    if (lyrics[index].trim().isNotEmpty) seen++;
    index++;
  }
  var spaces = 0;
  while (spaces < gap &&
      index < lyrics.length &&
      lyrics[index].trim().isEmpty) {
    spaces++;
    index++;
  }
  return index;
}

/// Where a chord must sit: over its syllable, unless the previous chord is
/// still in the way, in which case directly after it.
double expectedChordX({
  required String lyrics,
  required int charIndex,
  required RenderedChord? previous,
}) {
  final target = measureTextWidth(lyrics.substring(0, charIndex), lyricStyle);
  if (previous == null) return target;
  final previousEnd =
      previous.x + measureTextWidth(previous.text, chordStyle);
  return max(target, previousEnd);
}

/// Checks every placement rule for one laid-out song and returns a list of
/// human-readable violations (empty when the layout is correct).
List<String> placementViolations({
  required String source,
  required List<RenderedLine> lines,
  required double maxWidth,
  int transpose = 0,
  double tolerance = 0.5,
}) {
  final violations = <String>[];
  final expected = parseSource(source, transpose: transpose);

  // No lyric lost or invented.
  final renderedLetters = lines.map((l) => _stripSpace(l.lyrics)).join();
  if (renderedLetters != expected.letters) {
    violations.add('lyrics differ from source');
  }

  // No chord lost, invented or reordered.
  final renderedChords = [for (final l in lines) ...l.chords];
  final expectedNames = expected.chords.map((c) => c.text).toList();
  final renderedNames = renderedChords.map((c) => c.text).toList();
  if (renderedNames.join(' ') != expectedNames.join(' ')) {
    violations.add(
      'chords differ from source:\n'
      '  expected $expectedNames\n  rendered $renderedNames',
    );
    return violations;
  }

  // Each chord on the line holding its syllable, over that syllable.
  var chordIndex = 0;
  var lineStart = 0;
  for (final line in lines) {
    final lineLetters = _stripSpace(line.lyrics).length;
    RenderedChord? previous;
    for (final chord in line.chords) {
      final source = expected.chords[chordIndex];
      final anchor = source.anchor;
      final offset = anchor - lineStart;
      if (offset < 0 || offset > lineLetters) {
        violations.add(
          'chord #$chordIndex ${chord.text} rendered on "${line.lyrics}" '
          'but belongs to letter $anchor',
        );
      } else {
        final x = expectedChordX(
          lyrics: line.lyrics,
          charIndex: chordCharIndex(line.lyrics, offset, source.gap),
          previous: previous,
        );
        if ((chord.x - x).abs() > tolerance) {
          violations.add(
            'chord #$chordIndex ${chord.text} on "${line.lyrics}" at '
            'x=${chord.x.toStringAsFixed(1)}, expected ${x.toStringAsFixed(1)}',
          );
        }
      }
      previous = chord;
      chordIndex++;
    }
    lineStart += lineLetters;
  }

  // Chords stay on screen: no chord row hangs past the available width,
  // unless the row is one word that cannot move.
  for (final line in lines) {
    if (line.chords.isEmpty || !line.lyrics.trim().contains(' ')) continue;
    final last = line.chords.last;
    final end = last.x + measureTextWidth(last.text, chordStyle);
    if (end > maxWidth + tolerance) {
      violations.add(
        'chord ${last.text} on "${line.lyrics}" ends at ${end.round()}, '
        'max ${maxWidth.round()}',
      );
    }
  }

  // Wrapped lyric rows fit the available width.
  for (final line in lines) {
    // Trailing whitespace is invisible, so it may overhang.
    final width = measureTextWidth(line.lyrics.trimRight(), lyricStyle);
    if (width > maxWidth + tolerance) {
      violations.add(
        '"${line.lyrics}" is ${width.round()} wide, max ${maxWidth.round()}',
      );
    }
  }
  return violations;
}

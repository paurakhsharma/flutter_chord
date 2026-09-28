import 'dart:math';

import 'package:flutter/widgets.dart';

import 'chord_transposer.dart';
import 'song_document.dart';

/// Text styles for laying out and painting a song.
class LyricsStyle {
  final TextStyle lyrics;
  final TextStyle chords;
  final TextStyle chorus;
  final TextStyle comment;
  final TextScaler textScaler;

  LyricsStyle({
    required this.lyrics,
    required this.chords,
    TextStyle? chorus,
    TextStyle? comment,
    this.textScaler = TextScaler.noScaling,
  })  : chorus = chorus ?? lyrics.copyWith(fontWeight: FontWeight.bold),
        comment = comment ??
            lyrics.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: (lyrics.fontSize ?? 14) - 2,
            );

  TextStyle lyricStyleFor(LyricLine line) {
    if (line.kind == LineKind.comment) return comment;
    return line.isChorus ? chorus : lyrics;
  }

  @override
  bool operator ==(Object other) =>
      other is LyricsStyle &&
      other.lyrics == lyrics &&
      other.chords == chords &&
      other.chorus == chorus &&
      other.comment == comment &&
      other.textScaler == textScaler;

  @override
  int get hashCode => Object.hash(lyrics, chords, chorus, comment, textScaler);
}

/// Measures [text] on a single line.
Size measureText(
  String text,
  TextStyle style, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textScaler: textScaler,
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}

double measureTextWidth(
  String text,
  TextStyle style, {
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    measureText(text, style, textScaler: textScaler).width;

/// A chord placed on a row, [x] from the row's left edge.
class PlacedChord {
  final String name;
  final double x;
  final double width;

  const PlacedChord(this.name, this.x, this.width);

  double get end => x + width;

  @override
  String toString() => '$name@${x.toStringAsFixed(1)}';
}

/// One painted row: an optional chord row above one line of lyrics that
/// fits the available width.
class LaidOutRow {
  final String lyrics;
  final TextStyle lyricStyle;
  final List<PlacedChord> chords;
  final double lyricWidth;
  final double lyricHeight;

  /// Zero when the row shows no chords.
  final double chordRowHeight;

  const LaidOutRow({
    required this.lyrics,
    required this.lyricStyle,
    required this.chords,
    required this.lyricWidth,
    required this.lyricHeight,
    required this.chordRowHeight,
  });

  double get height => chordRowHeight + lyricHeight;

  double get width =>
      chords.isEmpty ? lyricWidth : max(lyricWidth, chords.last.end);
}

class LaidOutStanza {
  final List<LaidOutRow> rows;

  /// Keep on the same column or page as the stanza after it.
  final bool keepWithNext;

  /// Vertical space between rows.
  final double rowSpacing;

  const LaidOutStanza(
    this.rows, {
    required this.rowSpacing,
    this.keepWithNext = false,
  });

  double get height =>
      rows.fold<double>(0, (sum, row) => sum + row.height) +
      rowSpacing * max(0, rows.length - 1);
}

class SongLayout {
  final List<LaidOutStanza> stanzas;

  /// Vertical space between stanzas.
  final double stanzaGap;

  const SongLayout(this.stanzas, {required this.stanzaGap});

  Iterable<LaidOutRow> get rows => stanzas.expand((s) => s.rows);
}

/// Lays [document] out for [maxWidth]: transposes chords, wraps long lines
/// and places every chord over its syllable.
SongLayout layoutSong(
  SongDocument document, {
  required LyricsStyle style,
  required double maxWidth,
  int transpose = 0,
  ChordNotation notation = ChordNotation.american,
  bool showChords = true,
  double rowSpacing = 0,
}) {
  final transposer = ChordTransposer(notation, transpose: transpose);
  final stanzas = [
    for (final stanza in document.stanzas)
      LaidOutStanza(
        [
          for (final line in stanza.lines)
            ...layoutLine(
              line,
              style: style,
              maxWidth: maxWidth,
              transposer: transposer,
              showChords: showChords,
            ),
        ],
        rowSpacing: rowSpacing,
        keepWithNext: stanza.isLabel,
      ),
  ];
  // A blank line's worth of space, like the source's blank lines.
  final stanzaGap =
      measureText(' ', style.lyrics, textScaler: style.textScaler).height +
          rowSpacing;
  return SongLayout(stanzas, stanzaGap: stanzaGap);
}

/// Wraps [line] into rows no wider than [maxWidth] and places its chords.
/// Every chord sits over the character it is attached to, unless the
/// previous chord on the row is still in the way; then it follows it.
///
/// A chord after the last syllable can hang past the lyrics. When that
/// pushes a row past [maxWidth], the line is re-wrapped narrower so the
/// last word moves down with its chord.
List<LaidOutRow> layoutLine(
  LyricLine line, {
  required LyricsStyle style,
  required double maxWidth,
  ChordTransposer? transposer,
  bool showChords = true,
}) {
  var wrapWidth = maxWidth;
  var rows = _layoutRows(line, style, wrapWidth, transposer, showChords);
  for (var attempt = 0; attempt < 3; attempt++) {
    final overhang = rows.fold<double>(
      0,
      (most, row) => max(most, row.width - maxWidth),
    );
    if (overhang <= 0.5 || wrapWidth - overhang < maxWidth / 2) break;
    wrapWidth -= overhang;
    rows = _layoutRows(line, style, wrapWidth, transposer, showChords);
  }
  return rows;
}

List<LaidOutRow> _layoutRows(
  LyricLine line,
  LyricsStyle style,
  double maxWidth,
  ChordTransposer? transposer,
  bool showChords,
) {
  final lyricStyle = style.lyricStyleFor(line);
  final scaler = style.textScaler;
  final segments = wrapText(line.lyrics, lyricStyle, maxWidth, scaler);

  int segmentFor(int charIndex) {
    for (var i = segments.length - 1; i > 0; i--) {
      if (charIndex >= segments[i].start) return i;
    }
    return 0;
  }

  final chordsBySegment = List.generate(segments.length, (_) => <ChordMark>[]);
  if (showChords) {
    for (final chord in line.chords) {
      chordsBySegment[segmentFor(chord.charIndex)].add(chord);
    }
  }

  final chordRowHeight = measureText('A', style.chords, textScaler: scaler);
  return [
    for (var i = 0; i < segments.length; i++)
      _row(
        segments[i],
        chordsBySegment[i],
        lyricStyle: lyricStyle,
        style: style,
        transposer: transposer,
        chordRowHeight: chordRowHeight.height,
      ),
  ];
}

LaidOutRow _row(
  TextSegment segment,
  List<ChordMark> chords, {
  required TextStyle lyricStyle,
  required LyricsStyle style,
  required ChordTransposer? transposer,
  required double chordRowHeight,
}) {
  final scaler = style.textScaler;
  final placed = <PlacedChord>[];
  var previousEnd = 0.0;
  for (final chord in chords) {
    final local = (chord.charIndex - segment.start).clamp(
      0,
      segment.text.length,
    );
    final target = measureTextWidth(
      segment.text.substring(0, local),
      lyricStyle,
      textScaler: scaler,
    );
    final name = transposer?.transposeChord(chord.name) ?? chord.name;
    final width = measureTextWidth(name, style.chords, textScaler: scaler);
    final x = max(target, previousEnd);
    placed.add(PlacedChord(name, x, width));
    previousEnd = x + width;
  }

  final lyricSize = measureText(
    // An empty row (chords only) still takes a lyric line of height.
    segment.text.isEmpty ? ' ' : segment.text,
    lyricStyle,
    textScaler: scaler,
  );
  return LaidOutRow(
    lyrics: segment.text,
    lyricStyle: lyricStyle,
    chords: placed,
    lyricWidth: segment.text.isEmpty ? 0 : lyricSize.width,
    lyricHeight: lyricSize.height,
    chordRowHeight: placed.isEmpty ? 0 : chordRowHeight,
  );
}

/// A wrapped piece of a line: its [text] and where it starts in the line.
class TextSegment {
  final String text;
  final int start;

  const TextSegment(this.text, this.start);

  @override
  String toString() => 'TextSegment("$text"@$start)';
}

final _tokens = RegExp(r'^\s+|\S+\s*');

/// Greedily wraps [text] at whitespace so each segment fits [maxWidth].
/// A single word wider than [maxWidth] is broken between characters
/// (grapheme clusters, so Devanagari conjuncts stay whole). Character
/// offsets map back exactly to [text], so chords land in the right
/// segment. Whitespace at a break is dropped from the end of the segment.
List<TextSegment> wrapText(
  String text,
  TextStyle style,
  double maxWidth, [
  TextScaler textScaler = TextScaler.noScaling,
]) {
  double width(String s) => measureTextWidth(s, style, textScaler: textScaler);

  if (text.isEmpty || width(text.trimRight()) <= maxWidth) {
    return [TextSegment(text, 0)];
  }

  final pieces = <TextSegment>[];
  for (final match in _tokens.allMatches(text)) {
    final token = match.group(0)!;
    if (width(token.trimRight()) <= maxWidth) {
      pieces.add(TextSegment(token, match.start));
      continue;
    }
    // Break an over-long word into runs of characters that fit.
    var run = '';
    var runStart = match.start;
    var offset = match.start;
    for (final char in token.characters) {
      if (run.isNotEmpty && width((run + char).trimRight()) > maxWidth) {
        pieces.add(TextSegment(run, runStart));
        run = '';
        runStart = offset;
      }
      run += char;
      offset += char.length;
    }
    if (run.isNotEmpty) pieces.add(TextSegment(run, runStart));
  }

  final segments = <TextSegment>[];
  var current = '';
  var currentStart = 0;
  for (final piece in pieces) {
    final candidate = current + piece.text;
    if (current.isNotEmpty && width(candidate.trimRight()) > maxWidth) {
      segments.add(TextSegment(current.trimRight(), currentStart));
      current = piece.text;
      currentStart = piece.start;
    } else {
      if (current.isEmpty) currentStart = piece.start;
      current = candidate;
    }
  }
  if (current.isNotEmpty) segments.add(TextSegment(current, currentStart));
  return segments;
}

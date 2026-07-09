import 'dart:math';

import 'package:flutter/widgets.dart';

/// A chord positioned relative to the chord immediately before it.
class ChordPosition {
  final double leadingSpace;
  final String chordText;

  const ChordPosition(this.leadingSpace, this.chordText);

  @override
  String toString() =>
      'ChordPosition(leadingSpace: $leadingSpace, chordText: $chordText)';
}

double measureTextWidth(
  String text,
  TextStyle style, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return (TextPainter(
    text: TextSpan(text: text, style: style),
    textScaler: textScaler,
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout())
      .size
      .width;
}

/// Computes each chord's horizontal gap ("leadingSpace") so that, laid out
/// left-to-right as `SizedBox(width: leadingSpace) + Text(chordText)` pairs
/// in a Row, every chord lands at the same x-offset as its entry in
/// [charIndices] within [lyrics].
///
/// Each chord's gap is measured only against the lyric text since the
/// *previous* chord, not from the start of [lyrics] — measuring from an
/// absolute start on every chord double-counts the earlier text once per
/// prior chord and drifts later chords further right the more chords a
/// line has (they can end up rendered outside their container).
List<ChordPosition> computeChordPositions({
  required String lyrics,
  required List<int> charIndices,
  required List<String> chordTexts,
  required TextStyle lyricStyle,
  required TextStyle chordStyle,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  assert(charIndices.length == chordTexts.length);

  final positions = <ChordPosition>[];
  var previousIndex = 0;
  var previousChordWidth = 0.0;

  for (var i = 0; i < charIndices.length; i++) {
    final charIndex = charIndices[i].clamp(0, lyrics.length);
    final segment = lyrics.substring(min(previousIndex, charIndex), charIndex);
    final sizeOfLeadingLyrics =
        measureTextWidth(segment, lyricStyle, textScaler: textScaler);
    final leadingSpace = max(0.0, sizeOfLeadingLyrics - previousChordWidth);

    positions.add(ChordPosition(leadingSpace, chordTexts[i]));

    previousChordWidth =
        measureTextWidth(chordTexts[i], chordStyle, textScaler: textScaler);
    previousIndex = charIndex;
  }

  return positions;
}

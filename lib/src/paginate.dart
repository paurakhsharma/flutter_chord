import 'dart:math';

import 'song_layout.dart';

/// A run of rows from one stanza placed in a column.
class ColumnPiece {
  final int stanza;

  /// Rows [startRow, endRow) of the stanza.
  final int startRow;
  final int endRow;

  const ColumnPiece(this.stanza, this.startRow, this.endRow);

  @override
  bool operator ==(Object other) =>
      other is ColumnPiece &&
      other.stanza == stanza &&
      other.startRow == startRow &&
      other.endRow == endRow;

  @override
  int get hashCode => Object.hash(stanza, startRow, endRow);

  @override
  String toString() => 'ColumnPiece($stanza, $startRow–$endRow)';
}

/// One screen of columns.
class LyricsPage {
  final List<List<ColumnPiece>> columns;

  const LyricsPage(this.columns);

  /// The stanza the page starts with.
  int get firstStanza => columns.first.first.stanza;

  /// The stanza to remember as the reading position: the first stanza
  /// that starts on this page. A page that opens mid-stanza would
  /// otherwise send a reflow back to the previous page, where that stanza
  /// starts. Falls back to [firstStanza] when no stanza starts here.
  int get readingStanza {
    for (final column in columns) {
      for (final piece in column) {
        if (piece.startRow == 0) return piece.stanza;
      }
    }
    return firstStanza;
  }

  bool containsStanzaStart(int stanza) => columns.any(
        (column) => column.any((p) => p.stanza == stanza && p.startRow == 0),
      );

  @override
  String toString() => 'LyricsPage($columns)';
}

/// Flows [layout]'s stanzas newspaper-style into columns of
/// [columnHeight], [columns] per page.
///
/// - Stanzas stay whole unless one is taller than a column; then it is
///   split between rows, so a chord row never leaves its lyric row.
/// - A label stanza (`Verse 2`) stays with the start of the next stanza.
/// - When the whole song fits one page, stanzas are balanced across the
///   columns instead of filling the first column first.
/// - A stanza that doesn't fit the rest of a column may be split to fill
///   the gap (at least [minSplitRows] rows on each side), but only when
///   that saves a page turn. Otherwise stanzas stay whole.
List<LyricsPage> paginate(
  SongLayout layout, {
  required int columns,
  required double columnHeight,
  int minSplitRows = 2,
}) {
  assert(columns >= 1);
  if (layout.stanzas.isEmpty) return const [];

  final whole = _flow(layout, columnHeight, false, minSplitRows);
  if (columns > 1 && whole.length <= columns) {
    final balanced = _balance(layout, columns, columnHeight);
    if (balanced != null) return [LyricsPage(balanced)];
  }

  int pageCount(List<List<ColumnPiece>> flowed) =>
      (flowed.length / columns).ceil();
  final filled = _flow(layout, columnHeight, true, minSplitRows);
  final flowed = pageCount(filled) < pageCount(whole) ? filled : whole;
  return [
    for (var i = 0; i < flowed.length; i += columns)
      LyricsPage(flowed.sublist(i, min(i + columns, flowed.length))),
  ];
}

double _rowsHeight(LaidOutStanza stanza, int start, int end) {
  var height = 0.0;
  for (var r = start; r < end; r++) {
    height += stanza.rows[r].height;
    if (r > start) height += stanza.rowSpacing;
  }
  return height;
}

/// Height a stanza needs to start in a column: itself, plus for a label
/// the gap and the stanza it labels. That stanza moves whole when it fits
/// a column, so the label needs room for all of it; a taller one is split
/// anyway, so its first row is enough.
double _startNeed(SongLayout layout, int index, double columnHeight) {
  final stanza = layout.stanzas[index];
  if (!stanza.keepWithNext || index + 1 >= layout.stanzas.length) {
    return stanza.height;
  }
  final next = layout.stanzas[index + 1];
  final nextNeed = next.height <= columnHeight
      ? next.height
      : (next.rows.isEmpty ? 0.0 : next.rows.first.height);
  return stanza.height + layout.stanzaGap + nextNeed;
}

List<List<ColumnPiece>> _flow(
  SongLayout layout,
  double columnHeight,
  bool fillGaps,
  int minSplitRows,
) {
  final result = <List<ColumnPiece>>[[]];
  var used = 0.0;

  void newColumn() {
    if (result.last.isNotEmpty) result.add([]);
    used = 0;
  }

  for (var s = 0; s < layout.stanzas.length; s++) {
    final stanza = layout.stanzas[s];
    final gap = result.last.isEmpty ? 0.0 : layout.stanzaGap;

    // Whole stanza, and whatever must stay with it, fits here. A label
    // whose company can't fit even a fresh column is placed on its own.
    final need = _startNeed(layout, s, columnHeight);
    final fitsHere = used + gap + stanza.height <= columnHeight &&
        (need > columnHeight || used + gap + need <= columnHeight);
    if (fitsHere) {
      result.last.add(ColumnPiece(s, 0, stanza.rows.length));
      used += gap + stanza.height;
      continue;
    }

    // Fill the gap: rows that fit here stay, the rest continues below.
    var start = 0;
    if (fillGaps && !stanza.keepWithNext && result.last.isNotEmpty) {
      var fit = 0;
      while (fit < stanza.rows.length &&
          used + gap + _rowsHeight(stanza, 0, fit + 1) <= columnHeight) {
        fit++;
      }
      if (fit >= minSplitRows && stanza.rows.length - fit >= minSplitRows) {
        result.last.add(ColumnPiece(s, 0, fit));
        start = fit;
      }
    }

    // Fits a fresh column whole.
    if (start == 0 && stanza.height <= columnHeight) {
      newColumn();
      result.last.add(ColumnPiece(s, 0, stanza.rows.length));
      used = stanza.height;
      continue;
    }

    // Taller than a column (or the rest after filling a gap): start fresh
    // and split between rows.
    newColumn();
    while (start < stanza.rows.length) {
      var end = start + 1;
      while (end < stanza.rows.length &&
          _rowsHeight(stanza, start, end + 1) <= columnHeight) {
        end++;
      }
      result.last.add(ColumnPiece(s, start, end));
      used = _rowsHeight(stanza, start, end);
      if (end < stanza.rows.length) newColumn();
      start = end;
    }
  }
  return result;
}

/// Splits whole stanzas across [columns] columns so the tallest column is
/// as short as possible. Returns null when that needs a stanza split or a
/// column taller than [columnHeight].
List<List<ColumnPiece>>? _balance(
  SongLayout layout,
  int columns,
  double columnHeight,
) {
  final count = layout.stanzas.length;
  if (count < columns) return null;

  double heightOf(int from, int to) {
    var height = 0.0;
    for (var s = from; s < to; s++) {
      height += layout.stanzas[s].height;
      if (s > from) height += layout.stanzaGap;
    }
    return height;
  }

  bool canBreakBefore(int s) => !layout.stanzas[s - 1].keepWithNext;

  // Best split into [columns] runs, searched over break positions.
  // columns is small (1–3), so a direct search is enough.
  List<int>? best;
  var bestHeight = double.infinity;
  void search(List<int> breaks, int from) {
    if (breaks.length == columns - 1) {
      final bounds = [0, ...breaks, count];
      var tallest = 0.0;
      for (var c = 0; c < columns; c++) {
        tallest = max(tallest, heightOf(bounds[c], bounds[c + 1]));
      }
      if (tallest <= columnHeight && tallest < bestHeight) {
        bestHeight = tallest;
        best = List.of(breaks);
      }
      return;
    }
    final remaining = columns - 1 - breaks.length;
    for (var b = from; b <= count - remaining; b++) {
      if (!canBreakBefore(b)) continue;
      search([...breaks, b], b + 1);
    }
  }

  search([], 1);
  final breaks = best;
  if (breaks == null) return null;

  final bounds = [0, ...breaks, count];
  return [
    for (var c = 0; c < columns; c++)
      [
        for (var s = bounds[c]; s < bounds[c + 1]; s++)
          ColumnPiece(s, 0, layout.stanzas[s].rows.length),
      ],
  ];
}

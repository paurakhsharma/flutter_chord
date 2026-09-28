import 'package:flutter/widgets.dart';
import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/real_songs.dart';

const _gap = 10.0;

LaidOutRow _row(double height) => LaidOutRow(
      lyrics: 'x',
      lyricStyle: const TextStyle(),
      chords: const [],
      lyricWidth: 10,
      lyricHeight: height,
      chordRowHeight: 0,
    );

/// A stanza of [rows] rows, 10 high each.
LaidOutStanza _stanza(int rows, {bool label = false}) => LaidOutStanza(
      List.generate(rows, (_) => _row(10)),
      rowSpacing: 0,
      keepWithNext: label,
    );

SongLayout _song(List<LaidOutStanza> stanzas) =>
    SongLayout(stanzas, stanzaGap: _gap);

List<List<String>> _describe(List<LyricsPage> pages) => [
      for (final page in pages)
        [
          for (final column in page.columns)
            column
                .map((p) => '${p.stanza}:${p.startRow}-${p.endRow}')
                .join(' '),
        ],
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fills columns newspaper-style and pages the overflow', () {
    // Stanzas of 40; a 100-high column takes two (40 + 10 gap + 40).
    final pages = paginate(
      _song(List.generate(5, (_) => _stanza(4))),
      columns: 2,
      columnHeight: 100,
    );
    expect(_describe(pages), [
      ['0:0-4 1:0-4', '2:0-4 3:0-4'],
      ['4:0-4'],
    ]);
  });

  test('balances a song that fits one page across the columns', () {
    // Greedy would put 0,1 in column 1 and 2 alone in column 2.
    final pages = paginate(
      _song([_stanza(3), _stanza(3), _stanza(3)]),
      columns: 2,
      columnHeight: 100,
    );
    expect(_describe(pages), [
      ['0:0-3', '1:0-3 2:0-3'],
    ]);
  });

  test('splits a stanza taller than a column between rows', () {
    final pages = paginate(
      _song([_stanza(15)]),
      columns: 2,
      columnHeight: 100,
    );
    expect(_describe(pages), [
      ['0:0-10', '0:10-15'],
    ]);
  });

  test('splits stanzas to fill gaps when that saves a page', () {
    // Stanzas of 60: whole, one per 100-high column, 5 columns = 3 pages.
    // Filling gaps packs them into 4 columns = 2 pages.
    final pages = paginate(
      _song(List.generate(5, (_) => _stanza(6))),
      columns: 2,
      columnHeight: 100,
    );
    expect(_describe(pages), [
      ['0:0-6 1:0-3', '1:3-6 2:0-6'],
      ['3:0-6 4:0-3', '4:3-6'],
    ]);
  });

  test('keeps stanzas whole when splitting saves no page', () {
    // Four stanzas of 60: 2 pages whole, still 2 pages when filled.
    final pages = paginate(
      _song(List.generate(4, (_) => _stanza(6))),
      columns: 2,
      columnHeight: 100,
    );
    expect(_describe(pages), [
      ['0:0-6', '1:0-6'],
      ['2:0-6', '3:0-6'],
    ]);
  });

  test('a gap split leaves at least two rows on each side', () {
    // Stanza 1 (3 rows) could only leave 1 row behind: it moves whole.
    final pages = paginate(
      _song([_stanza(7), _stanza(3), _stanza(7), _stanza(7)]),
      columns: 1,
      columnHeight: 100,
    );
    for (final page in pages) {
      for (final piece in page.columns.expand((c) => c)) {
        expect(piece.endRow - piece.startRow, greaterThanOrEqualTo(2));
      }
    }
  });

  test('keeps a label with the stanza after it', () {
    // Label (10) fits under stanza 0 (60 + 10 + 10) but its verse does
    // not, so both move to the next column.
    final pages = paginate(
      _song([_stanza(6), _stanza(1, label: true), _stanza(5), _stanza(8)]),
      columns: 1,
      columnHeight: 100,
    );
    expect(_describe(pages), [
      ['0:0-6'],
      ['1:0-1 2:0-5'],
      ['3:0-8'],
    ]);
  });

  test('never balances a break right after a label', () {
    final pages = paginate(
      _song([_stanza(2), _stanza(1, label: true), _stanza(2), _stanza(2)]),
      columns: 2,
      columnHeight: 100,
    );
    for (final column in pages.single.columns) {
      final last = column.last.stanza;
      expect(last == 1, isFalse, reason: 'label ends a column');
    }
  });

  test('a page that opens mid-stanza reads from the next stanza start', () {
    // Stanza 1 (15 rows) is taller than a column, so page 2 opens with
    // its continuation; the reading position is stanza 2.
    final pages = paginate(
      _song([_stanza(3), _stanza(15), _stanza(3)]),
      columns: 1,
      columnHeight: 100,
    );
    final page = pages.firstWhere((p) => p.columns.first.first.startRow > 0);
    expect(page.firstStanza, 1);
    expect(page.readingStanza, 2);
    expect(
      pages.indexWhere((p) => p.containsStanzaStart(page.readingStanza)),
      pages.indexOf(page),
    );
  });

  test('one column is plain flow', () {
    final pages = paginate(
      _song([_stanza(3), _stanza(3), _stanza(3)]),
      columns: 1,
      columnHeight: 100,
    );
    expect(_describe(pages), [
      ['0:0-3 1:0-3'],
      ['2:0-3'],
    ]);
  });

  group('real songs', () {
    final style = LyricsStyle(lyrics: lyricStyle, chords: chordStyle);
    for (final song in loadRealSongs()) {
      for (final (columns, height) in [(1, 600.0), (2, 680.0), (2, 400.0)]) {
        test(
            '${song.category} $columns×${height.round()}: every row once, '
            'in order, within the column', () {
          final layout = layoutSong(
            parseSong(song.nepaliLyrics),
            style: style,
            maxWidth: 540,
          );
          final pages = paginate(
            layout,
            columns: columns,
            columnHeight: height,
          );

          final seen = [
            for (final page in pages)
              for (final column in page.columns)
                for (final piece in column)
                  for (var r = piece.startRow; r < piece.endRow; r++)
                    (piece.stanza, r),
          ];
          final expected = [
            for (var s = 0; s < layout.stanzas.length; s++)
              for (var r = 0; r < layout.stanzas[s].rows.length; r++) (s, r),
          ];
          expect(seen, expected);

          for (final page in pages) {
            expect(page.columns.length, lessThanOrEqualTo(columns));
            for (final column in page.columns) {
              var used = 0.0;
              for (var i = 0; i < column.length; i++) {
                final piece = column[i];
                final stanza = layout.stanzas[piece.stanza];
                if (i > 0) used += layout.stanzaGap;
                for (var r = piece.startRow; r < piece.endRow; r++) {
                  used += stanza.rows[r].height;
                  if (r > piece.startRow) used += stanza.rowSpacing;
                }
              }
              expect(used, lessThanOrEqualTo(height));
            }
          }
        });
      }
    }
  });
}

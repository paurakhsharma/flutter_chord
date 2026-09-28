/// A chord attached to a lyric line at a character index.
class ChordMark {
  /// Index into [LyricLine.lyrics] the chord sits over.
  final int charIndex;

  /// Chord name as written in the source, e.g. `Am`, `C/E`. Not transposed.
  final String name;

  const ChordMark(this.charIndex, this.name);

  @override
  bool operator ==(Object other) =>
      other is ChordMark && other.charIndex == charIndex && other.name == name;

  @override
  int get hashCode => Object.hash(charIndex, name);

  @override
  String toString() => 'ChordMark($name@$charIndex)';
}

enum LineKind { lyric, comment }

/// One source line with its `[X]` chord markup lifted out.
class LyricLine {
  /// Lyrics with chord markup removed. The source line is trimmed first;
  /// whitespace around chords is kept as written.
  final String lyrics;
  final List<ChordMark> chords;
  final LineKind kind;

  /// Inside a `{soc}` … `{eoc}` chorus block.
  final bool isChorus;

  const LyricLine(
    this.lyrics, {
    this.chords = const [],
    this.kind = LineKind.lyric,
    this.isChorus = false,
  });

  bool get hasChords => chords.isNotEmpty;

  @override
  String toString() => 'LyricLine("$lyrics", $chords)';
}

/// A block of lines separated from its neighbours by blank lines.
class Stanza {
  final List<LyricLine> lines;

  const Stanza(this.lines);

  /// A lone short line with no chords, like `Verse 2`, `कोरस` or
  /// `Intro : D | C |`. It labels the stanza after it, so layouts keep the
  /// two together.
  bool get isLabel =>
      lines.length == 1 &&
      !lines.single.hasChords &&
      lines.single.lyrics.length <= _maxLabelLength;

  static const _maxLabelLength = 32;

  @override
  String toString() => 'Stanza($lines)';
}

/// A song parsed once, independently of width, font and transpose.
class SongDocument {
  final List<Stanza> stanzas;
  final int? capo;
  final String? title;
  final String? artist;
  final String? key;

  const SongDocument(
    this.stanzas, {
    this.capo,
    this.title,
    this.artist,
    this.key,
  });

  Iterable<LyricLine> get lines => stanzas.expand((s) => s.lines);

  /// Every chord name in reading order.
  Iterable<String> get chordNames =>
      lines.expand((l) => l.chords).map((c) => c.name);
}

final _metadata = RegExp(r'^\{(\w+):\s*(.*?)\s*\}$');
final _chorusStart = RegExp(r'\{(soc|start_of_chorus)\}');
final _chorusEnd = RegExp(r'\{(eoc|end_of_chorus)\}');
final _comment = RegExp(r'^\{(comment|c):\s*(.*?)\s*\}$');

/// Parses ChordPro-style text: `[X]` inline chords, blank lines between
/// stanzas, `{title: }` / `{artist: }` / `{key: }` / `{capo: }` metadata,
/// `{soc}` / `{eoc}` chorus markers and `{comment: }` lines.
SongDocument parseSong(String text) {
  final stanzas = <Stanza>[];
  var current = <LyricLine>[];
  var isChorus = false;
  int? capo;
  String? title, artist, key;

  void closeStanza() {
    if (current.isNotEmpty) stanzas.add(Stanza(current));
    current = [];
  }

  for (final rawLine in text.split('\n')) {
    var line = rawLine.trim();

    final comment = _comment.firstMatch(line);
    if (comment != null) {
      current.add(LyricLine(
        comment.group(2)!,
        kind: LineKind.comment,
        isChorus: isChorus,
      ));
      continue;
    }

    final metadata = _metadata.firstMatch(line);
    if (metadata != null) {
      final value = metadata.group(2)!;
      switch (metadata.group(1)) {
        case 'title':
          title ??= value;
          continue;
        case 'artist':
          artist ??= value;
          continue;
        case 'key':
          key ??= value;
          continue;
        case 'capo':
          capo ??= int.tryParse(value);
          continue;
      }
    }

    if (_chorusStart.hasMatch(line)) {
      isChorus = true;
      line = line.replaceAll(_chorusStart, '').trim();
      if (line.isEmpty) continue;
    }
    final endsChorus = _chorusEnd.hasMatch(line);
    if (endsChorus) line = line.replaceAll(_chorusEnd, '').trim();

    if (line.isEmpty) {
      if (!endsChorus) closeStanza();
      isChorus = isChorus && !endsChorus;
      continue;
    }

    current.add(parseLine(line, isChorus: isChorus));
    if (endsChorus) isChorus = false;
  }
  closeStanza();

  return SongDocument(
    stanzas,
    capo: capo,
    title: title,
    artist: artist,
    key: key,
  );
}

/// Lifts `[X]` chord markup out of a single, already trimmed line. An
/// unclosed `[` is kept as lyrics.
LyricLine parseLine(String line, {bool isChorus = false}) {
  final lyrics = StringBuffer();
  final chords = <ChordMark>[];
  var index = 0;
  while (index < line.length) {
    final open = line.indexOf('[', index);
    final close = open < 0 ? -1 : line.indexOf(']', open);
    if (open < 0 || close < 0) {
      lyrics.write(line.substring(index));
      break;
    }
    lyrics.write(line.substring(index, open));
    chords.add(ChordMark(lyrics.length, line.substring(open + 1, close)));
    index = close + 1;
  }

  // Whitespace between chords is kept: chords-only lines like
  // `[Am]  [G]  [C]` use it for spacing.
  return LyricLine(lyrics.toString(), chords: chords, isChorus: isChorus);
}

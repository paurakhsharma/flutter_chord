import 'chord_lyrics_line.dart';

class ChordLyricsDocument {
  final List<ChordLyricsLine> chordLyricsLines;
  final int? capo;
  final String? title;
  final String? artist;
  final String? key;

  ChordLyricsDocument(this.chordLyricsLines,
      {this.capo, this.title, this.artist, this.key});
}

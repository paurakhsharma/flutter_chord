class ChordLyricsLine {
  List<Chord> chords;
  String lyrics;

  ChordLyricsLine(this.chords, this.lyrics);

  @override
  String toString() {
    return 'ChordLyricsLine($chords, lyrics: $lyrics)';
  }
}

class Chord {
  double leadingSpace;
  String chordText;

  Chord(this.leadingSpace, this.chordText);

  @override
  String toString() {
    return 'Chord(leadingSpace: $leadingSpace, chordText: $chordText)';
  }
}

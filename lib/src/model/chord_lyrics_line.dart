class ChordLyricsLine {
  List<Chord> chords;
  String lyrics;

  ChordLyricsLine(this.chords, this.lyrics);

  @override
  String toString() {
    return '{Chord: $chords, lyrics: $lyrics }\n';
  }
}

class Chord {
  double leadingSpace;
  String chordText;

  Chord(this.leadingSpace, this.chordText);

  @override
  String toString() {
    return 'leadingSpace: $leadingSpace \n chordText: $chordText';
  }
}

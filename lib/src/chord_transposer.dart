enum ChordNotation {
  italian,
  american,
  german,
  traditionalGerman,
  french,
  portuguese
}

class ChordTransposer {
  ChordTransposer(this.chordNotation, {this.transpose = 0}) {
    switch (chordNotation) {
      case ChordNotation.italian:
        cycle = italianNotes;
        break;
      case ChordNotation.american:
        cycle = americanNotes;
        break;
      default:
        throw ('Other languages not implemented yet');
    }
  }

  final ChordNotation chordNotation;
  late List<String> cycle;
  int transpose;

  static const List<String> americanNotes = [
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B"
  ];

  static const List<String> italianNotes = [
    "Do",
    "Do#",
    "Re",
    "Re#",
    "Mi",
    "Fa",
    "Fa#",
    "Sol",
    "Sol#",
    "La",
    "La#",
    "Si"
  ];

  /// Transpose the chord text by the given increment
  String transposeChord(String chord) {
    if (transpose == 0) {
      return chord;
    }
    final List<String> outChord = <String>[];

    ///Repeat for every note in chord
    ///i.e. C/B
    for (final String partChord in chord.split('/')) {
      outChord.add(_processChord(partChord));
    }
    return outChord.join('/');
  }

  ///1. Find chord
  ///2. Find alterations
  ///3. Keep away the rest
  ///4. Transpose
  ///5. Join all together
  String _processChord(String chord) {
    /// 1. Find chord
    int index = cycle.lastIndexWhere((note) => chord.startsWith(note));
    if (index == -1) {
      return chord;
    }
    final String chordFound = cycle[index];
    String simpleChord = chord.substring(0, chordFound.length);

    ///String containing other annotations of the chord
    late String otherPartChord;

    if (chord.startsWith('b', simpleChord.length)) {
      otherPartChord = chord.substring(simpleChord.length + 1);
    } else {
      otherPartChord = chord.substring(simpleChord.length);
    }

    ///2. Find alteration & 3. Keep away the rest
    /// Meaning that some special characters was added
    if (simpleChord.length < chord.length) {
      simpleChord = _handleFlatOrSharp(chord, simpleChord);

      ///Update index of the chord (particulary useful in case of chord with flat)
      index = cycle.indexOf(simpleChord);
    }

    ///4. Transpose
    final int newInd = (index + transpose + cycle.length) % cycle.length;
    final String newChord = cycle[newInd];

    ///5. Join all together
    return newChord + otherPartChord;
  }

  ///Add sharp to chord if present, or transform flat to sharp if present and add it to chord
  String _handleFlatOrSharp(String chord, String simpleChord) {
    if (chord.startsWith('#', simpleChord.length)) {
      simpleChord += '#';
    }
    if (chord.startsWith('b', simpleChord.length)) {
      simpleChord = _fromFlatToSharp(simpleChord);
    }
    return simpleChord;
  }

  /// We suppose that [simpleChord] is the most basic form of the chord without flat or sharp in the end
  String _fromFlatToSharp(String simpleChord) {
    final int index = cycle.indexOf(simpleChord) - 1 + cycle.length;
    return cycle[index % cycle.length];
  }
}

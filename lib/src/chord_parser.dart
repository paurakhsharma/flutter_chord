import 'dart:math';

import 'package:flutter/material.dart';
import 'model/chord_lyrics_document.dart';
import 'model/chord_lyrics_line.dart';
import 'chord_transposer.dart';

class ChordProcessor {
  final BuildContext context;
  final ChordNotation chordNotation;
  final ChordTransposer chordTransposer;
  final double media;
  late double _textScaleFactor;

  ChordProcessor(this.context, [this.chordNotation = ChordNotation.american])
      : chordTransposer = ChordTransposer(chordNotation),
        media = MediaQuery.of(context).size.width;

  /// Process the text to get the parsed ChordLyricsDocument
  ChordLyricsDocument processText({
    required String text,
    required TextStyle lyricsStyle,
    required TextStyle chordStyle,
    double scaleFactor = 1.0,
    int widgetPadding = 0,
    int transposeIncrement = 0,
  }) {
    final List<String> lines = text.split('\n');
    final MetadataHandler metadata = MetadataHandler();
    _textScaleFactor = scaleFactor;
    chordTransposer.transpose = transposeIncrement;

    String spaceChar = " ";
    double minNumLeadingSpaces = 1;
    double spaceWidth = textWidth(spaceChar, lyricsStyle);
    double minLeadingSpace = minNumLeadingSpaces * spaceWidth;

    /// List to store our updated lines without overflows
    final List<String> newLines = <String>[];
    String currentLine = '';

    ///loop through the lines
    for (int i = 0; i < lines.length; i++) {
      currentLine = lines[i];

      ///If it finds some metadata skip to the next line
      if (metadata.parseLine(currentLine)) {
        continue;
      }

      // obtain the lyrics portions in lyricsList
      // and the chords in chordList and
      // calculate paddingString before each chord

      // Regular exp for chord
      RegExp chordRe = RegExp(r'(\[[^\[]*\])');
      List<String> lyricsList = currentLine.split(chordRe);
      Iterable<RegExpMatch> matches = chordRe.allMatches(currentLine);

      List<String> chordList = [];
      for (RegExpMatch match in matches) {
        String chordText = currentLine.substring(match.start, match.end);
        chordList.add(chordText);
      }

      int lyricIdx = 0;
      String paddingString = "";
      String lyricsBeforeChord = lyricsList[lyricIdx++];
      String correctedLine = lyricsBeforeChord;
      chordList.forEach((chordText) {
        lyricsBeforeChord = lyricsList[lyricIdx++];
        double lyricsBetwChordsWidth =
            textWidth(lyricsBeforeChord, lyricsStyle);
        double chordWidth = textWidth(chordText, chordStyle);
        String lastLyricChar = (lyricsBeforeChord.length > 0)
            ? lyricsBeforeChord.substring(lyricsBeforeChord.length - 1)
            : '';
        int numAddSpaces = 0;
        double spaceDiff = (lyricsBetwChordsWidth - chordWidth);
        if (spaceDiff < 0) {
          numAddSpaces = ((minLeadingSpace - spaceDiff) / spaceWidth).round();
          if (lastLyricChar != ' ') {
            int numSpacesRight = ((numAddSpaces - 1) / 2).round();
            int numSpacesLeft = numAddSpaces - 1 - numSpacesRight;
            paddingString = (spaceChar * numSpacesLeft) +
                "-" +
                (spaceChar * numSpacesRight);
          } else if (lastLyricChar == ' ') {
            paddingString = spaceChar * numAddSpaces;
          }
        }
        if (lyricIdx == lyricsList.length) {
          paddingString = "";
        }
        correctedLine += chordText + lyricsBeforeChord + paddingString;
      });
      //String endLyrics = lyricsList[lyricIdx];
      //correctedLine += endLyrics;
      currentLine = correctedLine;

      //check if we have a long line
      if (textWidth(currentLine, lyricsStyle) >= media) {
        _handleLongLine(
            currentLine: currentLine,
            newLines: newLines,
            lyricsStyle: lyricsStyle,
            widgetPadding: widgetPadding);
      } else {
        //otherwise just add the regular line
        newLines.add(currentLine.trim());
      }
    }

    List<ChordLyricsLine> _chordLyricsLines = newLines
        .map<ChordLyricsLine>(
            (line) => _processLine(line, lyricsStyle, chordStyle))
        .toList();

    return ChordLyricsDocument(_chordLyricsLines,
        capo: metadata.capo,
        artist: metadata.artist,
        title: metadata.title,
        key: metadata.key);
  }

  void _handleLongLine(
      {required List<String> newLines,
      required String currentLine,
      required TextStyle lyricsStyle,
      required int widgetPadding}) {
    String _character = '';
    int _characterIndex = 0;
    String _currentCharacters = '';
    bool _chordHasStartedOuter = false;
    int _lastSpace = 0;

    //print('found a big line $currentLine');

    //work our way through the line and split when we need to
    for (var j = 0; j < currentLine.length; j++) {
      _character = currentLine[j];
      if (_character == '[') {
        _chordHasStartedOuter = true;
      } else if (_character == ']') {
        _chordHasStartedOuter = false;
      } else if (!_chordHasStartedOuter) {
        _currentCharacters += _character;
        if (_character == ' ') {
          //use this marker to only split where there are spaces. We can trim later.
          _lastSpace = j;
        }

        //This is the point where we need to split
        //widgetPadding has been added as a parameter to be passed from the build function
        //It is intended to allow for padding in the widget when comparing it to screen width
        //An additional buffer of around 10 might be needed to definitely stop overflow (ie. padding + 10).
        if (textWidth(_currentCharacters, lyricsStyle) + widgetPadding >=
            media) {
          newLines
              .add(currentLine.substring(_characterIndex, _lastSpace).trim());
          _currentCharacters = '';
          _characterIndex = _lastSpace;
        }
      }
    }
    //add the rest of the long line
    newLines
        .add(currentLine.substring(_characterIndex, currentLine.length).trim());
  }

  /// Return the textwidth of the text in the given style
  double textWidth(String text, TextStyle textStyle) {
    return (TextPainter(
      textScaleFactor: _textScaleFactor,
      text: TextSpan(text: text, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout())
        .size
        .width;
  }

  ChordLyricsLine _processLine(
      String line, TextStyle lyricsStyle, TextStyle chordStyle) {
    ChordLyricsLine _chordLyricsLine = ChordLyricsLine();
    String _lyricsSoFar = '';
    String _chordsSoFar = '';
    bool _chordHasStarted = false;
    line.split('').forEach((character) {
      if (character == ']') {
        final sizeOfLeadingLyrics = textWidth(_lyricsSoFar, lyricsStyle);

        final lastChordText = _chordLyricsLine.chords.isNotEmpty
            ? _chordLyricsLine.chords.last.chordText
            : '';

        final lastChordWidth = textWidth(lastChordText, chordStyle);
        // final sizeOfThisChord = textWidth(_chordsSoFar, chordStyle);

        double leadingSpace = max(0, sizeOfLeadingLyrics - lastChordWidth);

        final transposedChord = chordTransposer.transposeChord(_chordsSoFar);

        _chordLyricsLine.chords.add(Chord(leadingSpace, transposedChord));
        _chordLyricsLine.lyrics += _lyricsSoFar;
        _lyricsSoFar = '';
        _chordsSoFar = '';
        _chordHasStarted = false;
      } else if (character == '[') {
        _chordHasStarted = true;
      } else {
        if (_chordHasStarted) {
          _chordsSoFar += character;
        } else {
          _lyricsSoFar += character;
        }
      }
    });

    _chordLyricsLine.lyrics += _lyricsSoFar;

    return _chordLyricsLine;
  }
}

class MetadataHandler {
  /// As specifications says "meta data is specified using “tags” surrounded by { and } characters"
  final RegExp regMetadata = RegExp(r'^ *\{.*}');
  final RegExp regCapo = RegExp(r'^\{capo:.*[0-9]+\}');
  final RegExp regArtist = RegExp(r'^\{artist:.*\}');
  final RegExp regTitle = RegExp(r'^\{title:.*\}');
  final RegExp regKey = RegExp(r'^\{key:.*\}');
  int? capo;
  String? artist;
  String? title;
  String? key;

  /// Try to find and parse metadata in the string.
  /// Return true if there was a match
  bool parseLine(String line) {
    return _setCapoIfMatch(line) ||
        _setArtistIfMatch(line) ||
        _setKeyIfMatch(line) ||
        _setTitleIfMatch(line);
  }

  /// Get key in line if it's present
  /// Return true if match was found
  bool _setKeyIfMatch(String line) {
    String? tmpKey =
        regKey.hasMatch(line) ? _getMetadataFromLine(line, 'key:') : null;
    key ??= tmpKey;
    return tmpKey != null;
  }

  /// Get capo in line if it's present
  /// Return true if match was found
  bool _setCapoIfMatch(String line) {
    int? tmpCapo = regCapo.hasMatch(line)
        ? int.parse(_getMetadataFromLine(line, 'capo:'))
        : null;
    capo ??= tmpCapo;
    return tmpCapo != null;
  }

  /// Get artist in line if it's present
  /// Return true if match was found
  bool _setArtistIfMatch(String line) {
    String? tmpArtist =
        regArtist.hasMatch(line) ? _getMetadataFromLine(line, 'artist:') : null;
    artist ??= tmpArtist;
    return tmpArtist != null;
  }

  /// Get title in line if it's present
  /// Return true if match was found
  bool _setTitleIfMatch(String line) {
    String? tmpTitle =
        regTitle.hasMatch(line) ? _getMetadataFromLine(line, 'title:') : null;
    title ??= tmpTitle;
    return tmpTitle != null;
  }

  String _getMetadataFromLine(String line, String key) {
    return line.split(key).last.split('}').first.trim();
  }
}

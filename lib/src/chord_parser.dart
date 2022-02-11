import 'dart:math';

import 'package:flutter/material.dart';
import 'model/chord_lyrics_document.dart';
import 'model/chord_lyrics_line.dart';

class ChordProcessor {
  final BuildContext context;
  ChordProcessor(this.context);

  /// Process the text to get the parsed ChordLyricsDocument
  ChordLyricsDocument processText({
    required String text,
    required TextStyle lyricsStyle,
    required chordStyle,
    widgetPadding = 0,
    int transposeIncrement = 0,
  }) {
    final lines = text.split('\n');

    bool _chordHasStartedOuter = false;
    String _currentCharacters = '';
    int _lastSpace = 0;
    String _currentLine = '';
    String _character = '';
    double _media = MediaQuery.of(context).size.width;
    int _characterIndex = 0;

    //list to store our updated lines without overflows
    final _newLines = <String>[];

    //loop through the lines
    for (var i = 0; i < lines.length; i++) {
      _characterIndex = 0;
      _currentCharacters = '';
      _currentLine = lines[i];

      //check if we have a long line
      if (textWidth(_currentLine, lyricsStyle) >= _media) {
        print('found a big line $_currentLine');
        //work our way through the line and split when we need to
        for (var j = 0; j < _currentLine.length; j++) {
          _character = _currentLine[j];
          if (_character == '[')
            _chordHasStartedOuter = true;
          else if (_character == ']')
            _chordHasStartedOuter = false;
          else if (!_chordHasStartedOuter) {
            _currentCharacters += _character;
            if (_character == ' ') {
              //use this marker to only split where there are spaces. We can trim later.
              _lastSpace = j;
            }

            //This is the point where we need to split
            //widgetPadding has been added as a parameter to be passed from the build function
            //It is intended to allow for padding in the widget when comparing it to screen width
            //An additional buffer of around 10 might be needed to definitely stop overflow (ie. padding + 10).
            if (textWidth(_currentCharacters, lyricsStyle) + widgetPadding >= _media) {
              _newLines.add(_currentLine.substring(_characterIndex, _lastSpace).trim());
              _currentCharacters = '';
              _characterIndex = _lastSpace;
            }
          }
        }
        //add the rest of the long line
        _newLines.add(_currentLine.substring(_characterIndex, _currentLine.length).trim());
        
      } else {
        //otherwise just add the regular line
        _newLines.add(_currentLine.trim());
      }
    }
    
    List<ChordLyricsLine> _chordLyricsLines =
        _newLines.map<ChordLyricsLine>((line) {
      ChordLyricsLine _chordLyricsLine = ChordLyricsLine([], '');
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

          double leadingSpace = 0;
          leadingSpace = (sizeOfLeadingLyrics - lastChordWidth);

          leadingSpace = max(0, leadingSpace);

          final transposedChord = transposeChord(
            _chordsSoFar,
            transposeIncrement,
          );

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
    }).toList();

    return ChordLyricsDocument(_chordLyricsLines);
  }

  /// Return the textwidth of the text in the given style
  double textWidth(String text, TextStyle textStyle) {
    return (TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout())
        .size
        .width;
  }

  /// Transpose the chord text by the given increment
  String transposeChord(String chord, int increment) {
    final cycle = [
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
    String el = chord[0];
    if (chord.length > 1 && chord[1] == '#') {
      el += "#";
    }
    final ind = cycle.indexOf(el);
    if (ind == -1) return chord;

    final newInd = (ind + increment + cycle.length) % cycle.length;
    final newChord = cycle[newInd];
    return newChord + chord.substring(el.length);
  }
}

import 'package:flutter/widgets.dart';

import 'song_layout.dart';

/// Paints one [LaidOutRow]: chords at their laid-out x above one line of
/// lyrics. Its size matches [LaidOutRow.width] × [LaidOutRow.height]
/// exactly, so layouts that paginate by measured height stay in step.
class ChordLyricRow extends StatelessWidget {
  final LaidOutRow row;
  final LyricsStyle style;
  final void Function(String chord)? onTapChord;

  const ChordLyricRow({
    super.key,
    required this.row,
    required this.style,
    this.onTapChord,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: row.width,
      height: row.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final chord in row.chords)
            Positioned(
              left: chord.x,
              top: 0,
              child: GestureDetector(
                onTap:
                    onTapChord == null ? null : () => onTapChord!(chord.name),
                child: RichText(
                  text: TextSpan(text: chord.name, style: style.chords),
                  textScaler: style.textScaler,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          Positioned(
            left: 0,
            top: row.chordRowHeight,
            child: RichText(
              text: TextSpan(text: row.lyrics, style: row.lyricStyle),
              textScaler: style.textScaler,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}

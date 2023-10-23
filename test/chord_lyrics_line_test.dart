import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('isStartOfChorus', (WidgetTester tester) async {
    final ChordLyricsLine line = ChordLyricsLine();
    line.lyrics = "{start_of_chorus} I Am the Start of the Chorus {soc}";
    final isStart = line.isStartOfChorus();
    expect(isStart, true);
    expect(line.lyrics, "I Am the Start of the Chorus");
    line.lyrics = "I Am Not the Start of the Chorus";
    final isNotStart = line.isStartOfChorus();
    expect(isNotStart, false);
  });

  testWidgets('isEndOfChorus', (WidgetTester tester) async {
    final ChordLyricsLine line = ChordLyricsLine();
    line.lyrics = "{end_of_chorus} I Am the End of the Chorus {eoc}";
    final isEnd = line.isEndOfChorus();
    expect(isEnd, true);
    line.lyrics = "I Am Not the End of the Chorus";
    final isNotEnd = line.isEndOfChorus();
    expect(isNotEnd, false);
  });

  testWidgets('isComment', (WidgetTester tester) async {
    final ChordLyricsLine line = ChordLyricsLine();
    line.lyrics = "{comment: I Am a comment}";
    final isComment = line.isComment();
    expect(isComment, true);
    line.lyrics = "I Am a comment";
    final isNotEnd = line.isComment();
    expect(isNotEnd, false);
  });
}

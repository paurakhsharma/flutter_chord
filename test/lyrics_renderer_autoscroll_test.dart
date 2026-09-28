import 'package:flutter/material.dart';
import 'package:flutter_chord/flutter_chord.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/real_songs.dart';

const _speed = 40; // logical pixels per second

void main() {
  final longest =
      loadRealSongs().firstWhere((s) => s.category == 'longest').nepaliLyrics;

  late ScrollController controller;

  Widget renderer({double fontSize = 20, int transpose = 0}) {
    return MaterialApp(
      home: Scaffold(
        body: LyricsRenderer(
          lyrics: longest,
          textStyle: lyricStyle.copyWith(fontSize: fontSize),
          chordStyle: chordStyle,
          onTapChord: (_) {},
          transposeIncrement: transpose,
          scrollSpeed: _speed,
          scrollController: controller,
        ),
      ),
    );
  }

  /// Starts autoscroll and lets it run for [seconds].
  Future<void> autoscrollFor(WidgetTester tester, int seconds) async {
    await tester.pump();
    await tester.pump(Duration(seconds: seconds));
  }

  setUp(() => controller = ScrollController());

  testWidgets('keeps scrolling from where it is after a font change',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(renderer());
    await autoscrollFor(tester, 10);
    final before = controller.offset;
    expect(before, greaterThan(0));

    await tester.pumpWidget(renderer(fontSize: 22));
    await tester.pump();
    await tester.pump();
    final afterReflow = controller.offset;
    await tester.pump(const Duration(seconds: 3));

    // Not sent back to the top, and still moving.
    expect(afterReflow, greaterThan(before * 0.8));
    expect(controller.offset, greaterThan(afterReflow));
  });

  testWidgets('keeps scrolling after a transpose', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(renderer());
    await autoscrollFor(tester, 10);
    await tester.pumpWidget(renderer(transpose: 2));
    await tester.pump();
    await tester.pump();
    final afterTranspose = controller.offset;
    await tester.pump(const Duration(seconds: 3));

    expect(controller.offset, greaterThan(afterTranspose));
  });

  testWidgets('resumes from where the user scrolled back to',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(renderer());
    await autoscrollFor(tester, 20);
    final before = controller.offset;

    // User drags the page back down (scrolls back up the song).
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 300));
    // Let the fling settle; pumpAndSettle would also run the resumed
    // autoscroll to the end.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final afterDrag = controller.offset;
    expect(afterDrag, lessThan(before));

    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    // Continues from the dragged position at the set speed.
    final moved = controller.offset - afterDrag;
    expect(moved, closeTo(_speed * 5, _speed * 1.5));
  });
}

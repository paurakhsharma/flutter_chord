import 'package:flutter/material.dart';
import 'package:flutter_chord/flutter_chord.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Chord',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final chordStyle = TextStyle(fontSize: 20, color: Colors.green);
  final textStyle = TextStyle(fontSize: 18, color: Colors.white);
  String _lyrics = '';
  int transposeIncrement = 0;
  int scrollSpeed = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Chord Example'),
      ),
      body: Column(
        children: [
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            transposeIncrement--;
                          });
                        },
                        child: Text('-'),
                      ),
                      SizedBox(width: 5),
                      Text('$transposeIncrement'),
                      SizedBox(width: 5),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            transposeIncrement++;
                          });
                        },
                        child: Text('+'),
                      ),
                    ],
                  ),
                  Text('Transpose')
                ],
              ),
              Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: scrollSpeed <= 0
                            ? null
                            : () {
                                setState(() {
                                  scrollSpeed--;
                                });
                              },
                        child: Text('-'),
                      ),
                      SizedBox(width: 5),
                      Text('$scrollSpeed'),
                      SizedBox(width: 5),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            scrollSpeed++;
                          });
                        },
                        child: Text('+'),
                      ),
                    ],
                  ),
                  Text('Auto Scroll')
                ],
              ),
            ],
          ),
          Divider(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              color: Colors.black,
              child: LyricsRenderer(
                lyrics: _lyrics,
                textStyle: Theme.of(context).textTheme.bodyMedium!,
                chordStyle: Theme.of(context).textTheme.labelMedium!,
                onTapChord: (String chord) {
                  print('pressed chord: $chord');
                },
                transposeIncrement: transposeIncrement,
                scrollSpeed: scrollSpeed,
                widgetPadding: 24,
                lineHeight: 4,
                horizontalAlignment: CrossAxisAlignment.start,
                leadingWidget: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  child: Text(
                    'Leading Widget',
                    style: chordStyle,
                  ),
                ),
                trailingWidget: Text(
                  'Trailing Widget',
                  style: chordStyle,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _lyrics = '''


1
L[D]et me stand be[G]hind You, [D]Lord.
Let me wash Your [G]feet with my [D]tears.
Let me [A]wipe them with my [D]hair.
Let me [Em]kiss them and an[A]oint them with the [D]ointment.
{soc}
    I [G]love You!
    Jesus, I [D]love You!
    May I waste my all and life on [A]You.
    Let me [D]pour the ointment [Bm]pure
    On Your [G]head and on Your feet,
    On You, most [D]precious One,
    Bec[A]ause I love [D]You.
{eoc}
2
[D]Let me take a [G]pound of ointment [D]pure
Of great value [G]to anoint Your [D]feet
And [A]wipe them with my [D]hair
That the [Em]house be filled with the [A]fragrance of the [D]ointment.
{soc}
    I [G]love You!
    Jesus, I [D]love You!
    May I waste my all and life on [A]You.
  Let me [D]pour the ointment [Bm]pure
  On Your [G]head and on Your feet,
  On You, most [D]precious One,
  Be[A]cause I love [D]You.
{eoc}
3
[D]Lord, they said if [G]You were a [D]prophet,
You should know who and [G]what I [D]am.
I'm a [A]sinner that toucheth [D]You,
A [Em]woman not [A]worthy to a[D]noint You. 
{soc}
 But I [G]love You!
 Jesus, I [D]love You!
 You forgave me the most; now I love You, Lord, the [A]most.
 Let me [D]pour the ointment [Bm]pure
 On Your [G]head and on Your feet,
 On You, most [D]precious One,
 Be[A]cause You love [D]me.
{eoc}
4
[D]Let my love from my [G]being wash Your [D]feet
And my glory with[G]out wipe them [D]too.
Let me [A]kiss them where the nails would [D]pierce.
All my [Em]love, Lord, and [A]glory I'll waste on [D]You.
{soc}  
    I [G]love You!
   Jesus, I [D]love You!
   All my glory and love I pour and waste on [A]You.
   Re[D]ceive my ointment, [Bm]Lord.
   It's [G]all I have, dear Lord.
   For You, most [D]precious One,
   Be[A]cause I love [D]You.
{eoc}


''';
  }
}

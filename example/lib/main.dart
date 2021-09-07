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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Chord Example'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              color: Colors.teal,
              child: TextFormField(
                initialValue: _lyrics,
                style: textStyle,
                maxLines: 50,
                onChanged: (value) {
                  setState(() {
                    _lyrics = value;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              color: Colors.black,
              child: LyricsRenderer(
                lyrics: _lyrics,
                textStyle: textStyle,
                chordStyle: chordStyle,
                onTapChord: (String chord) {
                  print('pressed chord: $chord');
                },
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
[C]Give me Freedom , [F]Give me fire
[Am] Give me reason , [G]Take me higher
[C] See the champions [F], Take the field now
[Am] Unify us , [G]make us feel proud
 
[C] In the streets our , [F]hands are lifting
[Am] As we lose our , [G]inhibition
[C] Celebration , [F]its around us
[Am] Every nation , [G]all around us
''';
  }
}

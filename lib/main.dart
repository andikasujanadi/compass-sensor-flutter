import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock/wakelock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the system UI overlay style to fullscreen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: null,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  double userHeadingRaw = 0;
  int userHeading = 0;
  int userHeadingBefore = 0;
  bool isSwitched = false;
  bool isDimmed = false;
  int calibrate = 0;
  String link = "";

  Future<void> sendData() async {
    http.get(
      Uri.parse('http://$link/$userHeading'),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Wakelock.enable();
    FlutterCompass.events!.listen((event) {
      userHeadingRaw = event.heading!;
      userHeading = userHeadingRaw.round() + 180;
      userHeading -= calibrate;
      if (userHeading < 0) {
        userHeading += 360;
      } else if (userHeading > 360) {
        userHeading -= 360;
      }
      if ((userHeading != userHeadingBefore) && isSwitched) {
        if (Uri.tryParse('http://$link')?.hasAbsolutePath ?? false) {
          sendData();
        } else {
          isSwitched = false;
        }
      }
      setState(() {});
      userHeadingBefore = userHeading;
    });
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Builder(builder: (context) {
          return SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          '$userHeading',
                          style: const TextStyle(fontSize: 50),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                FloatingActionButton(
                                  onPressed: () {
                                    setState(() {
                                      calibrate = userHeadingRaw.round() + 180;
                                    });
                                  },
                                  child: const Icon(Icons.north),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Calibrate'),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                FloatingActionButton(
                                  backgroundColor: isSwitched
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .background,
                                  onPressed: () {
                                    setState(() {
                                      setState(() {
                                        isSwitched = !isSwitched;
                                      });
                                    });
                                  },
                                  child: const Icon(Icons.wifi_rounded),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Emit signal'),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                FloatingActionButton(
                                  onPressed: () {
                                    isDimmed = true;
                                  },
                                  child: const Icon(
                                      Icons.lightbulb_outline_rounded),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Dim screen'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '192.168.0.100:5000/robot1',
                              label: Text('Link')),
                          onChanged: (value) {
                            setState(() {
                              link = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (isDimmed)
                  Align(
                    child: GestureDetector(
                      onDoubleTap: () {
                        isDimmed = false;
                      },
                      child: Container(
                        color: Colors.black,
                      ),
                    ),
                  )
              ],
            ),
          );
        }),
      ),
    );
  }
}

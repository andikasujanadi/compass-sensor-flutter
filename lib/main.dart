import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock/wakelock.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String ipAddress = "";
  String port = "";
  String robotId = "";
  var ipAddressCon = TextEditingController();
  var portCon = TextEditingController();
  var robotIdCon = TextEditingController();

  Future<String> sendData() async {
    http
        .get(
          Uri.parse('http://$ipAddress:$port/robot$robotId/$userHeading'),
        )
        .timeout(const Duration(milliseconds: 1));
    return 'oke';
  }

  Future<void> resetPos() async {
    http
        .get(
          Uri.parse('http://$ipAddress:$port/resetpos$robotId'),
        )
        .timeout(const Duration(milliseconds: 20));
  }

  getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    ipAddress = prefs.getString('ipAddress') ?? '192.168.';
    port = prefs.getString('port') ?? '5000';
    robotId = prefs.getString('robotId') ?? '1';
    setState(() {
      ipAddressCon.text = ipAddress;
      portCon.text = port;
      robotIdCon.text = robotId;
    });
  }

  setIpAddress(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ipAddress', value);
  }

  setPort(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('port', value);
  }

  setRobotId(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('robotId', value);
  }

  @override
  void initState() {
    getData();
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
        sendData();
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
            child: SingleChildScrollView(
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
                          Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      FloatingActionButton(
                                        onPressed: () {
                                          setState(() {
                                            calibrate =
                                                userHeadingRaw.round() + 180;
                                          });
                                        },
                                        child: const Icon(Icons.north),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8),
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
                                        padding: EdgeInsets.all(8),
                                        child: Text('Emit signal'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
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
                                        padding: EdgeInsets.all(8),
                                        child: Text('Dim screen'),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      FloatingActionButton(
                                        onPressed: () {
                                          resetPos();
                                        },
                                        child:
                                            const Icon(Icons.replay_outlined),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Text('Reset Position'),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Sensor Server',
                              style: TextStyle(fontSize: 20)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: ipAddressCon,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '192.168.100.100',
                                label: Text('IP Address')),
                            onChanged: (value) {
                              ipAddress = value;
                              setIpAddress(value);
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: portCon,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '5000',
                                label: Text('Port')),
                            onChanged: (value) {
                              port = value;
                              setPort(value);
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: robotIdCon,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                label: Text('Robot ID')),
                            onChanged: (value) {
                              robotId = value;
                              setRobotId(value);
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
            ),
          );
        }),
      ),
    );
  }
}

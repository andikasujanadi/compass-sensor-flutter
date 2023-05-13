import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  CompassEvent? _lastRead;
  DateTime? _lastReadAt;

  Future<void> sendData() async {
    final CompassEvent tmp2 = await FlutterCompass.events!.first;
    double? userHeading;

    await FlutterCompass.events!.listen((event) {
      userHeading = event.heading;
    });
    final CompassEvent tmp = await FlutterCompass.events!.first;
    setState(() {
      _lastRead = tmp2;
    });
    final response = await http.get(
      Uri.parse('http://192.168.0.195:5000/robot1/${userHeading?.round()}'),
    );

    if (response.statusCode == 200) {
      // print('oke');
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      sendData();
      // timer.cancel();
    });
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Flutter Compass'),
        ),
        body: Builder(builder: (context) {
          return Column(
            children: <Widget>[
              _buildManualReader(),
              Expanded(child: _buildCompass()),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildManualReader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          ElevatedButton(
            child: const Text('Read Value'),
            onPressed: () async {
              final CompassEvent tmp = await FlutterCompass.events!.first;
              setState(() {
                _lastRead = tmp;
                _lastReadAt = DateTime.now();
              });
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$_lastRead',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '$_lastReadAt',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error reading heading: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        double? direction = snapshot.data!.heading;
        if (direction == null) {
          return const Center(
            child: Text("Device does not have sensors !"),
          );
        }

        return Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Transform.rotate(
              angle: (direction * (math.pi / 180) * -1),
              child: Image.asset('assets/compass.jpg'),
            ),
          ),
        );
      },
    );
  }
}

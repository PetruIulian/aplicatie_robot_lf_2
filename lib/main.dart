import 'dart:async';

import 'package:aplicatie_robot_lf_2/bluetooth/bluetooth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Line Follower App',
      theme: ThemeData.dark(),
      home: const MyHomePage(title: 'Robot Line Follower App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _currentKpValue = 0;
  double _currentKdValue = 0;
  Timer? _timer;
  //int _time = 0;
  String _timeString = "00:00:00";

  List<ScanResult> devices = [];
  String deviceName = "";
  BluetoothDevice? connectedDevice;
  DeviceIdentifier? deviceIdentifier;

  double screenWidth = 0;

  void _startTimer() {
    final DateTime startTime =
        DateTime.now(); // Timpul când începe cronometrarea
    const oneMs = Duration(milliseconds: 1);
    _timer = Timer.periodic(oneMs, (Timer timer) {
      setState(() {
        final Duration elapsed = DateTime.now().difference(
            startTime); // Diferența dintre timpul curent și cel de start

        int minutes = elapsed.inMinutes;
        int seconds = elapsed.inSeconds % 60;
        int milliseconds = elapsed.inMilliseconds % 1000;

        _timeString =
            "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${milliseconds.toString().padLeft(3, '0')}";
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Center(child: Text(widget.title)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("Conectat la: $deviceName"),
                Text("Timp: $_timeString m",
                    style: const TextStyle(fontSize: 60)),
                Row(children: <Widget>[
                  Column(
                    children: <Widget>[
                      Row(
                        children: [
                          const Text("KP:"),
                          Slider(
                            value: _currentKpValue,
                            onChanged: (double value) {
                              setState(() {
                                _currentKpValue = value;
                              });
                            },
                            min: 0.0,
                            max: 100.0,
                            divisions: 100,
                            label: _currentKpValue.round().toString(),
                          ),
                        ],
                      ),
                      Row(children: [
                        const Text("KD:"),
                        Slider(
                          value: _currentKdValue,
                          onChanged: (double value) {
                            setState(() {
                              _currentKdValue = value;
                            });
                          },
                          min: 0.0,
                          max: 100.0,
                          divisions: 100,
                          label: _currentKdValue.round().toString(),
                        )
                      ]),
                    ],
                  ),
                  ElevatedButton(
                      onPressed: () => {},
                      style: const ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(Colors.indigoAccent),
                          minimumSize: WidgetStatePropertyAll(Size(180, 70))),
                      child: const Text("Calibrare")),
                ]),
                ElevatedButton(
                  onPressed: () {
                    _startTimer();
                    sendMessage(connectedDevice!, "start");
                  },
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.green),
                    minimumSize:
                        WidgetStatePropertyAll(Size(double.infinity, 70)),
                  ),
                  child: const Text("Start"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: () {
                      _stopTimer();
                      sendMessage(connectedDevice!, "stop");
                    },
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.red),
                      minimumSize:
                          WidgetStatePropertyAll(Size(double.infinity, 70)),
                    ),
                    child: const Text("Stop")),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: () {
                      sendMessage(connectedDevice!, "turbina");
                    },
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.blue),
                      minimumSize:
                          WidgetStatePropertyAll(Size(double.infinity, 70)),
                    ),
                    child: const Text("Start Turbina")),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          checkBluetoothPerms();
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Bluetooth"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // Asigură dimensiunea minimă
                      children: <Widget>[
                        const Text("Conectează-te la robot"),
                        const TextField(
                          decoration: InputDecoration(hintText: "Adresă MAC"),
                        ),
                        Column(
                          children: devices
                              .where(
                                  (device) => device.device.advName.isNotEmpty)
                              .map((device) => ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        deviceName = device.device.advName;
                                      });
                                      await device.device.connect();
                                      connectedDevice = device.device;
                                      List<BluetoothService> services =
                                          await device.device
                                              .discoverServices();
                                      BluetoothCharacteristic? writableChar;
                                      for (BluetoothService service
                                          in services) {
                                        for (BluetoothCharacteristic char
                                            in service.characteristics) {
                                          if (char.properties.write) {
                                            writableChar = char;
                                            break;
                                          }
                                        }
                                      }
                                      if (writableChar != null) {
                                        await writableChar
                                            .write("text".codeUnits);
                                      }

                                      print(
                                          "Device selected: ${device.device}");
                                    },
                                    child: Text(device.device.advName),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Anulează"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Conectează"),
                    ),
                    TextButton(
                      onPressed: () async {
                        List<ScanResult> newDevices = await startScan();
                        setState(() {
                          devices = newDevices;
                        });
                      },
                      child: const Text("Scanare"),
                    ),
                  ],
                );
              });
        },
        tooltip: 'Connect to robot',
        child: const Icon(Icons.bluetooth),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

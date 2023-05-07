import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';

const int BUFFER_SIZE = 40;

void main() => runApp(AccelerometerApp());

class AccelerometerApp extends StatefulWidget {
  @override
  _AccelerometerAppState createState() => _AccelerometerAppState();
}

class _AccelerometerAppState extends State<AccelerometerApp> {
  List<List<double>> _buffer = List.filled(BUFFER_SIZE, [0.0, 0.0, 0.0]);
  int _bufferIndex = 0;
  Interpreter? _interpreter;
  bool _interpreterLoaded = false;
  bool _showingWarning = false;
  bool sms_status=false;
  AccelerometerEvent? get _lastEvent {
    if (_bufferIndex == 0) {
      return null;
    } else {
      var event = AccelerometerEvent(_buffer[_bufferIndex - 1][0],
          _buffer[_bufferIndex - 1][1], _buffer[_bufferIndex - 1][2]);
      return event;
    }
  }

  String? _prediction;
  AccelerometerEvent _accelerometerEvent = AccelerometerEvent(1, 1, 1);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<PermissionStatus> _getSmsPermissionStatus() async {
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      return await Permission.sms.request();
    } else {
      return status;
    }
  }



  Future<void> _init() async {
    sms_status = (await _getSmsPermissionStatus()).isGranted;
    await _loadInterpreter();

    accelerometerEvents.listen((AccelerometerEvent event) async {
      if (!_showingWarning) {
        _updateBuffer(event);

        if (_interpreterLoaded) {
          List<List<List<double>>> input = [_buffer];
          List<List<double>> output = List.filled(1, List.filled(1, 0.0));

          _interpreter!.run(input, output);

          double prediction = output[0][0];

          if (prediction > 0.6) {
            _showWarning();
          }
          setState(() {
            _prediction = prediction.toStringAsFixed(2);
            _accelerometerEvent = event;
          });
        } else {
          setState(() {
            _prediction = null;
            _accelerometerEvent = event;
          });
        }
      }
    });
  }

  Future<void> _loadInterpreter() async {
    try {
      debugPrint('ok1123123123123');
      debugPrint('cacat');
      _interpreter = await Interpreter.fromAsset('modelDense.tflite');
      debugPrint('o11k1123123123123');
      setState(() {
        _interpreterLoaded = true;
        debugPrint('Loaded Model');
      });
    } on PlatformException {
      debugPrint('Failed to load model');
    }
  }

  void _updateBuffer(AccelerometerEvent event) {
    _buffer[_bufferIndex] = [event.x, event.y, event.z];
    _bufferIndex = (_bufferIndex + 1) % BUFFER_SIZE;
  }

  void sendSms(String message, List<String> recipients) async {
    try {
      await sendSMS(
          message: message, recipients: recipients);
    } catch (e) {
      print('Error sending SMS: $e');
    }
  }

  void _showWarning() {
    _showingWarning = true;
    _buffer = List.filled(BUFFER_SIZE, [0.0, 0.0, 0.0]);
    if(sms_status){
      sendSms('I fell!!', ['0721604363']);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accelerometer App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Accelerometer App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _accelerometerEvent != null
                    ? 'Accelerometer Values:\n\nX: ${_accelerometerEvent!.x.toStringAsFixed(2)}\nY: ${_accelerometerEvent!.y.toStringAsFixed(2)}\nZ: ${_accelerometerEvent!.z.toStringAsFixed(2)}'
                    : 'Waiting for accelerometer values...',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Text(
                _prediction ?? '',
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              _showingWarning
                  ? Column(children: [
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Fall!',
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.green,
                      ),
                    )),
                ElevatedButton(
                  onPressed: () {
                    _showingWarning = false;
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueGrey,
                    padding: EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              ])
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}

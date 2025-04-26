import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ManuelKontrol extends StatefulWidget {
  const ManuelKontrol({super.key});

  @override
  State<ManuelKontrol> createState() => _ManuelKontrolState();
}

class _ManuelKontrolState extends State<ManuelKontrol> {
  RawDatagramSocket? _udpSocket;
  final String _targetIP = '192.168.1.130'; // Jetson IP
  final int _targetPort = 8888; // UDP Listener port

  Map<int, Offset> _touchStartPoints = {};
  Map<int, Offset> _touchCurrentPoints = {};

  double _speed = 50;

  Timer? _sendTimer;

  @override
  void initState() {
    super.initState();
    _initUdp();
    _sendTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _sendData());
  }

  void _initUdp() async {
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  }

  void _sendData() {
    if (_udpSocket == null) return;

    double forwardBackward = 0;
    double leftRight = 0;

    final screenWidth = MediaQuery.of(context).size.width;
    final deadZoneWidth = screenWidth * 0.2;

    if (_touchCurrentPoints.isEmpty) {
      Map<String, int> messageMap = {
        "joystick_forward": 0,
        "joystick_turn": 0,
      };
      String message = jsonEncode(messageMap);
      print('Gönderilen mesaj: $message');
      _udpSocket!.send(utf8.encode(message), InternetAddress(_targetIP), _targetPort);
      return;
    }

    _touchCurrentPoints.forEach((pointer, currentPosition) {
      final start = _touchStartPoints[pointer];
      if (start != null) {
        if (start.dx < screenWidth / 2 - deadZoneWidth / 2) {
          forwardBackward = (start.dy - currentPosition.dy) / 100;
        } else if (start.dx > screenWidth / 2 + deadZoneWidth / 2) {
          leftRight = (currentPosition.dx - start.dx) / 100;
        }
      }
    });

    forwardBackward = forwardBackward.clamp(-1.0, 1.0);
    leftRight = leftRight.clamp(-1.0, 1.0);

    int scaledForwardBackward = (forwardBackward * _speed).toInt();
    int scaledLeftRight = (leftRight * _speed).toInt();

    Map<String, int> messageMap = {
      "joystick_forward": scaledForwardBackward,
      "joystick_turn": scaledLeftRight,
    };
    String message = jsonEncode(messageMap);
    print('Gönderilen mesaj: $message');
    _udpSocket!.send(utf8.encode(message), InternetAddress(_targetIP), _targetPort);
  }

  @override
  void dispose() {
    _udpSocket?.close();
    _sendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final joystickRadius = 60.0;
    final deadZoneWidth = screenWidth * 0.2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manuel Kontrol'),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: SizedBox(
              width: 150,
              child: Slider(
                value: _speed,
                min: 0,
                max: 100,
                divisions: 20,
                label: _speed.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _speed = value;
                  });
                },
              ),
            ),
          ),
          Listener(
            onPointerDown: (details) {
              setState(() {
                _touchStartPoints[details.pointer] = details.localPosition;
                _touchCurrentPoints[details.pointer] = details.localPosition;
              });
            },
            onPointerMove: (details) {
              setState(() {
                _touchCurrentPoints[details.pointer] = _limitMovement(
                  _touchStartPoints[details.pointer]!,
                  details.localPosition,
                  100,
                );
              });
            },
            onPointerUp: (details) {
              setState(() {
                _touchStartPoints.remove(details.pointer);
                _touchCurrentPoints.remove(details.pointer);
              });
            },
            onPointerCancel: (details) {
              setState(() {
                _touchStartPoints.remove(details.pointer);
                _touchCurrentPoints.remove(details.pointer);
              });
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: JoystickPainter(
                startPoints: _touchStartPoints,
                currentPoints: _touchCurrentPoints,
                joystickRadius: joystickRadius,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Offset _limitMovement(Offset center, Offset current, double maxDistance) {
    final dx = current.dx - center.dx;
    final dy = current.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance > maxDistance) {
      final angle = atan2(dy, dx);
      return Offset(
        center.dx + maxDistance * cos(angle),
        center.dy + maxDistance * sin(angle),
      );
    } else {
      return current;
    }
  }
}

class JoystickPainter extends CustomPainter {
  final Map<int, Offset> startPoints;
  final Map<int, Offset> currentPoints;
  final double joystickRadius;

  JoystickPainter({
    required this.startPoints,
    required this.currentPoints,
    required this.joystickRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.yellow.withOpacity(0.5);

    startPoints.forEach((pointer, start) {
      final current = currentPoints[pointer];
      if (current != null) {
        canvas.drawCircle(start, joystickRadius, paint);
        canvas.drawCircle(current, joystickRadius / 2, Paint()..color = Colors.orange);
      }
    });
  }

  @override
  bool shouldRepaint(covariant JoystickPainter oldDelegate) => true;
}

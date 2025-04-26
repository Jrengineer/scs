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
  final String _targetIP = '192.168.1.130';
  final int _targetPort = 8888;

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

  bool _isJoystickArea(Offset position, Size size) {
    final width = size.width;
    final height = size.height;

    final colWidth = width / 3;
    final rowHeight = height / 3;

    int col = (position.dx / colWidth).floor();
    int row = (position.dy / rowHeight).floor();

    if (row == 1) { // Ortadaki satır
      if (col == 0 || col == 2) {
        return true; // Sol ve sağ alan joystick aktif
      }
    }
    return false; // Diğer tüm bölgelerde joystick yok
  }

  void _sendData() {
    if (_udpSocket == null) return;

    double forwardBackward = 0;
    double leftRight = 0;

    final screenSize = MediaQuery.of(context).size;

    if (_touchCurrentPoints.isEmpty) {
      Map<String, int> messageMap = {
        "joystick_forward": 0,
        "joystick_turn": 0,
      };
      String message = jsonEncode(messageMap);
      _udpSocket!.send(utf8.encode(message), InternetAddress(_targetIP), _targetPort);
      return;
    }

    _touchCurrentPoints.forEach((pointer, currentPosition) {
      final start = _touchStartPoints[pointer];
      if (start != null && _isJoystickArea(start, screenSize)) {
        if (start.dx < screenSize.width / 2) {
          forwardBackward = (start.dy - currentPosition.dy) / 100;
        } else {
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
    final screenSize = MediaQuery.of(context).size;
    final joystickRadius = 60.0;

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
              if (_isJoystickArea(details.localPosition, screenSize)) {
                setState(() {
                  _touchStartPoints[details.pointer] = details.localPosition;
                  _touchCurrentPoints[details.pointer] = details.localPosition;
                });
              }
            },
            onPointerMove: (details) {
              if (_touchStartPoints.containsKey(details.pointer)) {
                setState(() {
                  _touchCurrentPoints[details.pointer] = _limitMovement(
                    _touchStartPoints[details.pointer]!,
                    details.localPosition,
                    100,
                  );
                });
              }
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
                screenSize: screenSize,
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
  final Size screenSize;

  JoystickPainter({
    required this.startPoints,
    required this.currentPoints,
    required this.joystickRadius,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final colWidth = width / 3;
    final rowHeight = height / 3;

    final activePaint = Paint()..color = Colors.green.withOpacity(0.3);
    final inactivePaint = Paint()..color = Colors.transparent;

    // Boya joystick aktif bölgeleri
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        bool isActive = false;
        if (row == 1 && (col == 0 || col == 2)) {
          isActive = true;
        }
        final rect = Rect.fromLTWH(col * colWidth, row * rowHeight, colWidth, rowHeight);
        canvas.drawRect(rect, isActive ? activePaint : inactivePaint);
      }
    }

    // Joystick çemberlerini boya
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

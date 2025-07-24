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

  Socket? _tcpSocket;
  Uint8List? _cameraImageBytes;
  List<int> _cameraBuffer = [];
  int _fps = 0;
  int _frameCounter = 0;
  int _latencyMs = 0;
  Timer? _fpsTimer;
  int _lastFrameTime = 0;

  Rect? _leftJoystickArea;
  Rect? _rightJoystickArea;
  Rect? _cameraArea;

  bool _isBrush1On = false;
  bool _isBrush2On = false;

  @override
  void initState() {
    super.initState();
    _initUdp();
    _initTcp();
    _sendTimer = Timer.periodic(const Duration(milliseconds: 10), (_) => _sendData());
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _fps = _frameCounter;
        _frameCounter = 0;
      });
    });
  }

  void _initUdp() async {
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  }

  void _initTcp() async {
    try {
      _tcpSocket = await Socket.connect('192.168.1.130', 5000);
      _tcpSocket!.listen(_onCameraData, onDone: _onCameraDone, onError: _onCameraError);
    } catch (e) {
      print('TCP bağlantı hatası: $e');
    }
  }

  void _onCameraData(Uint8List data) {
    _cameraBuffer.addAll(data);

    while (_cameraBuffer.length >= 4) {
      final byteData = ByteData.sublistView(Uint8List.fromList(_cameraBuffer));
      final frameLength = byteData.getUint32(0, Endian.big);

      if (_cameraBuffer.length < 4 + frameLength) {
        break;
      }

      final frameData = _cameraBuffer.sublist(4, 4 + frameLength);
      _cameraBuffer = _cameraBuffer.sublist(4 + frameLength);

      final now = DateTime.now().millisecondsSinceEpoch;
      final latency = _lastFrameTime == 0 ? 0 : now - _lastFrameTime;
      _lastFrameTime = now;

      setState(() {
        _cameraImageBytes = Uint8List.fromList(frameData);
        _latencyMs = latency;
        _frameCounter++;
      });
    }
  }

  void _onCameraDone() {
    print('Kamera bağlantısı kapandı.');
    _tcpSocket?.destroy();
  }

  void _onCameraError(error) {
    print('Kamera bağlantı hatası: $error');
    _tcpSocket?.destroy();
  }

  void _calculateAreas(Size size) {
    double cameraWidth = size.width * 0.6;
    double cameraHeight = size.height * 0.4;
    double cameraX = (size.width - cameraWidth) / 2;
    double cameraY = (size.height - cameraHeight) / 2 - 100;

    _cameraArea = Rect.fromLTWH(cameraX, cameraY, cameraWidth, cameraHeight);

    _leftJoystickArea = Rect.fromLTWH(0, cameraY, cameraX, cameraHeight);
    _rightJoystickArea = Rect.fromLTWH(cameraX + cameraWidth, cameraY, cameraX, cameraHeight);
  }

  bool _isInJoystickArea(Offset position) {
    if (_cameraArea != null && _cameraArea!.contains(position)) {
      return false;
    }
    return (_leftJoystickArea?.contains(position) ?? false) || (_rightJoystickArea?.contains(position) ?? false);
  }

  void _sendData() {
    if (_udpSocket == null) return;

    double forwardBackward = 0;
    double leftRight = 0;

    // Joystick kullanılmıyorsa yine de brush komutlarını DAİMA gönder!
    bool validTouchExists = false;
    _touchCurrentPoints.forEach((pointer, currentPosition) {
      final start = _touchStartPoints[pointer];
      if (start != null && _isInJoystickArea(start)) {
        validTouchExists = true;
        if (_leftJoystickArea!.contains(start)) {
          forwardBackward = (start.dy - currentPosition.dy) / 100;
        } else if (_rightJoystickArea!.contains(start)) {
          leftRight = (currentPosition.dx - start.dx) / 100;
        }
      }
    });

    forwardBackward = forwardBackward.clamp(-1.0, 1.0);
    leftRight = leftRight.clamp(-1.0, 1.0);

    int scaledForwardBackward = (forwardBackward * _speed).toInt();
    int scaledLeftRight = (leftRight * _speed).toInt();

    Map<String, dynamic> messageMap = {
      "joystick_forward": validTouchExists ? scaledForwardBackward : 0,
      "joystick_turn": validTouchExists ? scaledLeftRight : 0,
      "brush1": _isBrush1On ? 1 : 0,
      "brush2": _isBrush2On ? 1 : 0,
      "ts": DateTime.now().millisecondsSinceEpoch,
    };
    String message = jsonEncode(messageMap);
    _udpSocket!.send(utf8.encode(message), InternetAddress(_targetIP), _targetPort);
  }

  @override
  void dispose() {
    _udpSocket?.close();
    _tcpSocket?.destroy();
    _sendTimer?.cancel();
    _fpsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _calculateAreas(size);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manuel Kontrol'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_cameraImageBytes != null)
                  Positioned(
                    left: _cameraArea!.left,
                    top: _cameraArea!.top,
                    width: _cameraArea!.width,
                    height: _cameraArea!.height,
                    child: Image.memory(
                      _cameraImageBytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                _buildJoystickLayer(size),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('FPS: $_fps', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      Text('Gecikme: $_latencyMs ms', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Ön Fırça", style: TextStyle(fontWeight: FontWeight.bold)),
                    Switch(
                      value: _isBrush1On,
                      onChanged: (value) {
                        setState(() {
                          _isBrush1On = value;
                        });
                      },
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Hız Limiti', style: TextStyle(color: Colors.white, fontSize: 16)),
                    SizedBox(
                      width: 160,
                      child: Slider(
                        value: _speed,
                        min: 10,
                        max: 100,
                        divisions: 9,
                        label: '${_speed.round()}%',
                        onChanged: (value) {
                          setState(() {
                            _speed = value;
                          });
                        },
                      ),
                    ),
                    Text('Seçili: ${_speed.round()}%', style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Arka Fırça", style: TextStyle(fontWeight: FontWeight.bold)),
                    Switch(
                      value: _isBrush2On,
                      onChanged: (value) {
                        setState(() {
                          _isBrush2On = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoystickLayer(Size size) {
    return Positioned.fill(
      child: Listener(
        onPointerDown: (details) {
          if (_isInJoystickArea(details.localPosition)) {
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
            leftJoystickArea: _leftJoystickArea!,
            rightJoystickArea: _rightJoystickArea!,
          ),
        ),
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
  final Rect leftJoystickArea;
  final Rect rightJoystickArea;

  JoystickPainter({
    required this.startPoints,
    required this.currentPoints,
    required this.leftJoystickArea,
    required this.rightJoystickArea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final greenPaint = Paint()..color = Colors.green.withOpacity(0.3);
    final yellowPaint = Paint()..color = Colors.yellow.withOpacity(0.5);
    final orangePaint = Paint()..color = Colors.orange;

    canvas.drawRect(leftJoystickArea, greenPaint);
    canvas.drawRect(rightJoystickArea, greenPaint);

    startPoints.forEach((pointer, start) {
      final current = currentPoints[pointer];
      if (current != null) {
        canvas.drawCircle(start, 60, yellowPaint);
        canvas.drawCircle(current, 30, orangePaint);
      }
    });
  }

  @override
  bool shouldRepaint(covariant JoystickPainter oldDelegate) => true;
}

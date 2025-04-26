import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class KameraSayfasi extends StatefulWidget {
  const KameraSayfasi({super.key});

  @override
  State<KameraSayfasi> createState() => _KameraSayfasiState();
}

class _KameraSayfasiState extends State<KameraSayfasi> {
  Socket? _socket;
  Uint8List? _imageBytes;
  bool _connected = false;

  int _frameCounter = 0;
  int _fps = 0;
  Timer? _fpsTimer;

  int _lastFrameTime = 0;
  int _latencyMs = 0;

  final List<int> _buffer = [];

  @override
  void initState() {
    super.initState();
    _connectToServer();
    _startFpsTimer();
  }

  void _startFpsTimer() {
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _fps = _frameCounter;
        _frameCounter = 0;
      });
    });
  }

  void _connectToServer() async {
    try {
      _socket = await Socket.connect('192.168.1.130', 5000);
      setState(() {
        _connected = true;
      });
      _socket!.listen(_onData, onDone: _onDone, onError: _onError);
    } catch (e) {
      setState(() {
        _connected = false;
      });
      print('Bağlantı hatası: $e');
      Future.delayed(const Duration(seconds: 2), _connectToServer);
    }
  }

  void _onData(Uint8List data) {
    _buffer.addAll(data);

    while (_buffer.length >= 4) {
      final lengthBytes = Uint8List.fromList(_buffer.sublist(0, 4));
      final frameLength = ByteData.sublistView(lengthBytes).getUint32(0, Endian.big);

      if (_buffer.length < 4 + frameLength) {
        break; // Tüm frame gelmemiş, bekle
      }

      final frameData = _buffer.sublist(4, 4 + frameLength);
      _buffer.removeRange(0, 4 + frameLength); // Kullanılan veriyi buffer'dan sil

      final now = DateTime.now().millisecondsSinceEpoch;
      final latency = _lastFrameTime == 0 ? 0 : now - _lastFrameTime;
      _lastFrameTime = now;

      setState(() {
        _imageBytes = Uint8List.fromList(frameData);
        _frameCounter++;
        _latencyMs = latency;
      });
    }
  }

  void _onDone() {
    print('Bağlantı kapandı.');
    setState(() {
      _connected = false;
    });
    Future.delayed(const Duration(seconds: 2), _connectToServer);
  }

  void _onError(error) {
    print('Bağlantı hatası: $error');
    setState(() {
      _connected = false;
    });
    Future.delayed(const Duration(seconds: 2), _connectToServer);
  }

  @override
  void dispose() {
    _socket?.destroy();
    _fpsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamera Görüntüsü'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: _connected
                  ? _imageBytes != null
                  ? Image.memory(
                _imageBytes!,
                gaplessPlayback: true,
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.6,
              )
                  : const CircularProgressIndicator()
                  : const Text('Kamera bağlantısı kurulamadı'),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'FPS: $_fps',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  'Gecikme: $_latencyMs ms',
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'status_bar.dart'; // Doğru import

class Ayarlar extends StatelessWidget {
  const Ayarlar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        actions: const [
          StatusBar(),
        ],
      ),
      body: const Center(
        child: Text(
          'Ayarlar Sayfası',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

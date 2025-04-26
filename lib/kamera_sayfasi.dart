import 'package:flutter/material.dart';
import 'status_bar.dart'; // Doğru import

class KameraSayfasi extends StatelessWidget {
  const KameraSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamera Görüntüsü'),
        actions: const [
          StatusBar(),
        ],
      ),
      body: const Center(
        child: Text(
          'Kamera Görüntüsü Sayfası',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

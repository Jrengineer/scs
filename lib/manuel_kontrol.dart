import 'package:flutter/material.dart';
import 'status_bar.dart'; // Doğru import

class ManuelKontrol extends StatelessWidget {
  const ManuelKontrol({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manuel Kontrol'),
        actions: const [
          StatusBar(),
        ],
      ),
      body: const Center(
        child: Text(
          'Manuel Kontrol Sayfası',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

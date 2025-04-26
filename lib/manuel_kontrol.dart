import 'package:flutter/material.dart';

class ManuelKontrol extends StatelessWidget {
  const ManuelKontrol({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manuel Kontrol'),
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

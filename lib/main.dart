import 'package:flutter/material.dart';
import 'ana_sayfa.dart'; // Çok sayfalı AnaSayfa açılacak

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Panel Temizlik Robotu',
      theme: ThemeData.dark(),
      home: const AnaSayfa(),
      debugShowCheckedModeBanner: false,
    );
  }
}

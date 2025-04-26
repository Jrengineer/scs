import 'package:flutter/material.dart';
import 'ana_sayfa.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Panel Temizlik Robotu',
      theme: ThemeData.dark(),  // 🖤 Burayı koyu tema yaptım!
      home: const AnaSayfa(),
      debugShowCheckedModeBanner: false,
    );
  }
}

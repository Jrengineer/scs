import 'package:flutter/material.dart';
import 'ana_sayfa_icerik.dart'; // Değişiklik burada

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
      home: const AnaSayfaIcerik(), // <<< BURASI DEĞİŞTİ
      debugShowCheckedModeBanner: false,
    );
  }
}

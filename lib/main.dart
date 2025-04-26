import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'camera_service.dart';
import 'ana_sayfa.dart'; // senin ana menü sayfanın dosyası

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SCS App',
      theme: ThemeData.dark(), // İstersen light yapabilirsin
      home: const AnaSayfa(), // Senin ana ekranın
    );
  }
}

import 'package:flutter/material.dart';
import 'manuel_kontrol.dart';
import 'ayarlar.dart';
import 'kamera_sayfasi.dart';
import 'ana_sayfa_icerik.dart';
import 'status_bar.dart'; // Doğru tek import

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AnaSayfaIcerik(),
    const ManuelKontrol(),
    const Ayarlar(),
    const KameraSayfasi(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Panel Temizlik Robotu'),
        actions: const [
          StatusBar(),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Menü', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Ana Sayfa'),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.gamepad),
              title: const Text('Manuel Kontrol'),
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),

            // --- YENİ EKLENDİ: Tek Joystick (Spawn) sayfasına geçiş ---
            ListTile(
              leading: const Icon(Icons.sports_esports),
              title: const Text('Tek Joystick'),
              onTap: () {
                // Önce çekmeceyi kapat
                Navigator.pop(context);
                // Ardından yeni sayfayı route üzerinden aç
                Navigator.of(context).pushNamed('/tek-joystick-spawn');
              },
            ),
            // --- YENİ BÖLÜM SONU ---

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera Görüntüsü'),
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

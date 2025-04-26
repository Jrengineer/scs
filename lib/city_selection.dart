import 'package:flutter/material.dart';

class CitySelectionPage extends StatelessWidget {
  const CitySelectionPage({super.key});

  final List<String> cities = const [
    'İstanbul',
    'Ankara',
    'İzmir',
    'Bursa',
    'Antalya',
    'Adana',
    'Konya',
    'Gaziantep',
    'Kayseri',
    'Mersin',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şehir Seçimi'),
      ),
      body: ListView.builder(
        itemCount: cities.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(cities[index]),
            onTap: () {
              Navigator.pop(context, cities[index]);
            },
          );
        },
      ),
    );
  }
}

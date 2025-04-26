import 'package:flutter/material.dart';
import 'weather_service.dart';
import 'city_selection.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  String _city = 'İstanbul'; // Başlangıç şehri
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _forecastWeather;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
    });

    final current = await WeatherService.fetchCurrentWeather(_city);
    final forecast = await WeatherService.fetchForecastWeather(_city);

    setState(() {
      _currentWeather = current;
      _forecastWeather = forecast;
      _isLoading = false;
    });
  }

  void _selectCity() async {
    final selectedCity = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CitySelectionPage()),
    );

    if (selectedCity != null) {
      setState(() {
        _city = selectedCity;
      });
      _fetchWeather();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Panel Temizlik Robotu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_city),
            onPressed: _selectCity,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildWeatherContent(),
    );
  }

  Widget _buildWeatherContent() {
    if (_currentWeather == null || _forecastWeather == null) {
      return const Center(child: Text('Veri alınamadı'));
    }

    final todayWeather = _currentWeather!;
    final tomorrowWeather = _forecastWeather!['list'][7]; // Yaklaşık yarın

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            '📍 $_city',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Image.network(
                  'https://openweathermap.org/img/wn/${todayWeather['weather'][0]['icon']}@2x.png'),
              title: Text('Bugün: ${todayWeather['weather'][0]['description']}'),
              subtitle: Text('${todayWeather['main']['temp'].toStringAsFixed(0)}°C'),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Image.network(
                  'https://openweathermap.org/img/wn/${tomorrowWeather['weather'][0]['icon']}@2x.png'),
              title: Text('Yarın: ${tomorrowWeather['weather'][0]['description']}'),
              subtitle: Text('${tomorrowWeather['main']['temp'].toStringAsFixed(0)}°C'),
            ),
          ),
        ],
      ),
    );
  }
}

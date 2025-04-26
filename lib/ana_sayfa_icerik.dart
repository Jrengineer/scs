import 'package:flutter/material.dart';
import 'weather_service.dart';
import 'city_selection.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class AnaSayfaIcerik extends StatefulWidget {
  const AnaSayfaIcerik({super.key});

  @override
  State<AnaSayfaIcerik> createState() => _AnaSayfaIcerikState();
}

class _AnaSayfaIcerikState extends State<AnaSayfaIcerik> {
  String _city = 'İstanbul';
  Map<String, dynamic>? _forecastWeather;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null).then((_) {
      _fetchWeather();
    });
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
    });

    final forecast = await WeatherService.fetchForecastWeather(_city);

    setState(() {
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildWeatherContent();
  }

  Widget _buildWeatherContent() {
    if (_forecastWeather == null) {
      return const Center(child: Text('Veri alınamadı'));
    }

    List<dynamic> forecastList = _forecastWeather!['list'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '📍 $_city',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.location_city),
                onPressed: _selectCity,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                final weatherData = forecastList[index * 8];
                DateTime date = DateTime.now().add(Duration(days: index));
                String formattedDate = DateFormat('EEEE, dd MMMM', 'tr_TR').format(date);

                return Card(
                  child: ListTile(
                    leading: Image.network(
                      'https://openweathermap.org/img/wn/${weatherData['weather'][0]['icon']}@2x.png',
                    ),
                    title: Text(formattedDate),
                    subtitle: Text(
                      '${weatherData['weather'][0]['description']} - '
                          '${weatherData['main']['temp'].toStringAsFixed(0)}°C',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

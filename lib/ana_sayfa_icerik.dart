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
  String _city = 'Eskişehir';
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '📍 $_city',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.location_city),
                onPressed: _selectCity,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                final weatherData = forecastList[index * 8];
                DateTime date = DateTime.now().add(Duration(days: index));
                String formattedDate = DateFormat('EEEE, dd MMMM', 'tr_TR').format(date);

                return Container(
                  width: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formattedDate,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Image.network(
                        'https://openweathermap.org/img/wn/${weatherData['weather'][0]['icon']}@2x.png',
                        width: 70,
                        height: 70,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${weatherData['main']['temp'].toStringAsFixed(0)}°C',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        weatherData['weather'][0]['description'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
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

import 'package:flutter/material.dart';
import 'weather_service.dart';
import 'city_selection.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // <<< EKLENDİ

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
    initializeDateFormatting('tr_TR', null).then((_) {  // <<< EKLENDİ
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

  ...
}

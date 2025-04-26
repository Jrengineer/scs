import 'package:flutter/material.dart';

class StatusBar extends StatelessWidget {
  final bool isConnected;
  final int batteryLevel;

  const StatusBar({
    Key? key,
    this.isConnected = true,
    this.batteryLevel = 75,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          isConnected ? Icons.wifi : Icons.wifi_off,
          color: isConnected ? Colors.green : Colors.red,
          size: 28,
        ),
        const SizedBox(width: 8),
        Icon(
          batteryLevel >= 75
              ? Icons.battery_full
              : batteryLevel >= 50
              ? Icons.battery_3_bar
              : batteryLevel >= 25
              ? Icons.battery_2_bar
              : Icons.battery_alert,
          color: batteryLevel >= 25 ? Colors.green : Colors.red,
          size: 28,
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

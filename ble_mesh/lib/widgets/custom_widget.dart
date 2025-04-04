import 'package:flutter/material.dart';

import '../themes/mycolors.dart';

Text getText(
  double temperature,
  double smoke, {
  required bool customize,
  double fontSize = 0,
  FontWeight? fontWeight,
}) {
  var text = const Text(
    'Safety',
    style: TextStyle(color: Colors.green, fontSize: 18),
  );
  if (temperature < 35 || smoke < 35) {
    text = const Text(
      'Safety',
      style: TextStyle(color: Colors.green, fontSize: 18),
    );
  }
  if ((temperature >= 35 && temperature < 40) || (smoke >= 35 && smoke < 100)) {
    text = const Text(
      'Warning',
      style: TextStyle(color: Colors.orange, fontSize: 18),
    );
  }
  if (temperature >= 40 || smoke >= 100) {
    text = const Text(
      'Fire',
      style: TextStyle(color: Colors.red, fontSize: 18),
    );
  }
  if (customize) {
    text = Text(
      text.data ?? '',
      style: text.style?.copyWith(fontSize: fontSize, fontWeight: fontWeight),
    );
  }
  return text;
}

Color getColor(double temperature, double smoke) {
  var color = Colors.green;

  if (temperature < 35 || smoke < 35) {
    color = Colors.green;
  }
  if ((temperature >= 35 && temperature < 40) || (smoke >= 35 && smoke < 100)) {
    color = Colors.orange;
  }
  if (temperature >= 40 || smoke >= 100) {
    color = Colors.red;
  }
  return color;
}

Icon getIcon(double temperature, double smoke) {
  if (temperature >= 40 || smoke >= 100) {
    return const Icon(
      Icons.local_fire_department_rounded,
      color: Colors.red,
    );
  } else if ((temperature >= 35 && temperature < 40) || (smoke >= 35 && smoke < 100)) {
    return const Icon(
      Icons.warning_amber_rounded,
      color: Colors.orange,
    );
  } else {
    return const Icon(
      Icons.check_circle_outline,
      color: Colors.green,
    );
  }
}

Widget getBLESignal(int rssi) {
  const double width = 34;
  const double height = 34;

  if (rssi <= -90) {
    return Image.asset('assets/icons/no connection.png', width: width, height: height);
  } else if (rssi > -90 && rssi <= -80) {
    return Image.asset('assets/icons/low.png', width: width, height: height);
  } else if (rssi > -80 && rssi <= -72) {
    return Image.asset('assets/icons/lightly medium.png', width: width, height: height);
  } else if (rssi > -72 && rssi <= -67) {
    return Image.asset('assets/icons/medium.png', width: width, height: height);
  } else if (rssi > -67 && rssi <= -55) {
    return Image.asset('assets/icons/lightly high.png', width: width, height: height);
  } else if (rssi > -55 && rssi <= -30) {
    return Image.asset('assets/icons/high.png', width: width, height: height);
  } else {
    return Image.asset('assets/icons/error.png', width: width, height: height);
  }
}

Widget buildWeatherInfo({IconData? icon, String image = "", required String value, required String label}) {
  return Column(
    children: [
      (icon != null)
          ? Icon(
              icon,
              color: Colors.white,
              size: 34,
            )
          : Image.asset(
              image,
              width: 34,
              height: 34,
              color: Colors.white,
            ),
      const SizedBox(height: 5),
      Text(value, style: const TextStyle(color: TextColor, fontSize: 18)),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(color: TextColor, fontSize: 14)),
    ],
  );
}

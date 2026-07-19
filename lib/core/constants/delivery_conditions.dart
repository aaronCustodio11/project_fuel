class DeliveryConditions {
  DeliveryConditions._();

  static const double fuelExpansionRate = 0.00095;
  static const double highTempThreshold = 35.0;
  static const double mockAmbientTemp = 38.0;

  static double getAmbientTemp({DateTime? date, int? hour}) {
    if (date == null || hour == null) return mockAmbientTemp;
    final double baseTemp;
    if (hour >= 14 && hour < 18) {
      baseTemp = 34.0;
    } else if (hour >= 10) {
      baseTemp = 30.0;
    } else if (hour >= 6) {
      baseTemp = 24.0;
    } else if (hour >= 18) {
      baseTemp = 23.0;
    } else {
      baseTemp = 19.0;
    }
    final daySeed = date.year * 10000 + date.month * 100 + date.day;
    final r = ((daySeed * 1103515245 + 12345) & 0x7fffffff) % 121;
    return double.parse((baseTemp + (r - 60) / 10.0).toStringAsFixed(1));
  }

  static String? getWarning(double tempCelsius, String fuelType,
      {DateTime? date, int? hour}) {
    if (tempCelsius <= highTempThreshold) return null;
    final expansionPer1000L =
        fuelExpansionRate * (tempCelsius - 25) * 1000;
    if (date != null && hour != null) {
      final timeStr = '${hour.toString().padLeft(2, '0')}:00';
      return 'Weather forecast for ${date.month}/${date.day} at $timeStr — '
          '${tempCelsius.toStringAsFixed(1)}°C expected. '
          'At this temperature, $fuelType fuel expands by ~'
          '${expansionPer1000L.toStringAsFixed(1)}L per 1000L. '
          'Consider rescheduling to cooler hours or reducing fill level to 95% of tank capacity.';
    }
    return 'High temperature ($tempCelsius°C) causing fuel expansion risk '
        '(+${expansionPer1000L.toStringAsFixed(1)}L per 1000L of $fuelType). '
        'Consider reducing fill level to 95% of tank capacity.';
  }

  static bool hasActiveWarning(double tempCelsius) =>
      tempCelsius > highTempThreshold;
}

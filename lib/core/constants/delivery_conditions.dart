class DeliveryConditions {
  DeliveryConditions._();

  static const double fuelExpansionRate = 0.00095;
  static const double highTempThreshold = 35.0;
  static const double mockAmbientTemp = 38.0;

  static String? getWarning(double tempCelsius, String fuelType) {
    if (tempCelsius <= highTempThreshold) return null;
    final expansionPer1000L =
        fuelExpansionRate * (tempCelsius - 25) * 1000;
    return 'High temperature ($tempCelsius°C) causing fuel expansion risk '
        '(+${expansionPer1000L.toStringAsFixed(1)}L per 1000L of $fuelType). '
        'Consider reducing fill level to 95% of tank capacity.';
  }

  static bool hasActiveWarning(double tempCelsius) =>
      tempCelsius > highTempThreshold;
}

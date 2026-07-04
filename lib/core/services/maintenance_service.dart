import 'package:project_fuel/core/models/maintenance.dart';
import 'package:project_fuel/core/services/json_reader.dart';

class MaintenanceService {
  static const _assetPath = 'assets/mock_data/maintenance.json';

  Future<List<MaintenanceRecord>> getRecords() async {
    final data = await JsonReaderService.readListStatic(_assetPath);
    return data
        .map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

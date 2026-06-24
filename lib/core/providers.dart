import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';
import 'services/app_info_service.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return Database.getInstance();
});

final appInfoProvider = FutureProvider<AppInfoService>((ref) async {
  return AppInfoService.create();
});

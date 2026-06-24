import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/platform_service.dart';

final platformServiceProvider = Provider<PlatformService>((ref) {
  return PlatformService();
});

final bubbleServiceRunningProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(platformServiceProvider);
  return service.isServiceRunning();
});

final overlayPermissionProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(platformServiceProvider);
  return service.checkOverlayPermission();
});

final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(platformServiceProvider);
  return service.checkNotificationPermission();
});

final batteryOptimizationProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(platformServiceProvider);
  return service.checkBatteryOptimization();
});

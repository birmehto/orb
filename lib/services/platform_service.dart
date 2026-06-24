import 'package:flutter/services.dart';
import '../core/constants.dart';

class PlatformService {
  static final PlatformService _instance = PlatformService._();
  factory PlatformService() => _instance;
  PlatformService._();

  final MethodChannel _channel = const MethodChannel(AppConstants.channelName);

  Future<bool> startService() async {
    try {
      return await _channel.invokeMethod('startService') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stopService() async {
    try {
      return await _channel.invokeMethod('stopService') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isServiceRunning() async {
    try {
      return await _channel.invokeMethod('isServiceRunning') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkOverlayPermission() async {
    try {
      return await _channel.invokeMethod('checkOverlayPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  Future<bool> checkNotificationPermission() async {
    try {
      return await _channel.invokeMethod('checkNotificationPermission') ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> requestNotificationPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } catch (_) {}
  }

  Future<bool> checkBatteryOptimization() async {
    try {
      return await _channel.invokeMethod('checkBatteryOptimization') ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimization');
    } catch (_) {}
  }

  Future<void> openAutoStartSettings() async {
    try {
      await _channel.invokeMethod('openAutoStartSettings');
    } catch (_) {}
  }

  Future<Map<String, double>> getBubblePosition() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getBubblePosition');
      if (result != null) {
        return {
          'x': (result['x'] as num).toDouble(),
          'y': (result['y'] as num).toDouble(),
        };
      }
    } catch (_) {}
    return {'x': -1.0, 'y': -1.0};
  }

  Future<void> updateBubbleStyle(int color, int size, double opacity) async {
    try {
      await _channel.invokeMethod('updateBubbleStyle', {
        'color': color,
        'size': size,
        'opacity': opacity,
      });
    } catch (_) {}
  }

  Future<void> setAutoHideEnabled(bool enabled, int timeoutSeconds) async {
    try {
      await _channel.invokeMethod('setAutoHide', {
        'enabled': enabled,
        'timeoutSeconds': timeoutSeconds,
      });
    } catch (_) {}
  }

  Future<bool> isDeviceLocked() async {
    try {
      return await _channel.invokeMethod('isDeviceLocked') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getNativeClips() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getNativeClips');
      if (result != null) {
        return result.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }
}

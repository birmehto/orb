import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final methodChannel = const MethodChannel(AppConstants.channelName);
  methodChannel.setMethodCallHandler((call) async {
    if (call.method == 'onAppResumed' || call.method == 'onOverlayPermissionResult') {
      // These are handled by providers re-invalidating on resume
    }
    return null;
  });

  runApp(
    const ProviderScope(
      child: LayApp(),
    ),
  );
}

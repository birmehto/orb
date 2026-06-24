import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bubble_settings.dart';
import '../../../core/providers.dart';

final bubbleSettingsProvider = FutureProvider<BubbleSettings>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.getSettings();
});

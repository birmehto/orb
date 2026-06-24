import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/clip_item.dart';
import '../../../core/providers.dart';

final clipsProvider = FutureProvider<List<ClipItem>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.getClips();
});

final filteredClipsProvider = Provider.family<List<ClipItem>, String>((ref, query) {
  final clipsAsync = ref.watch(clipsProvider);
  return clipsAsync.when(
    data: (clips) {
      if (query.isEmpty) return clips;
      return clips.where((c) =>
        c.text.toLowerCase().contains(query.toLowerCase())
      ).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

final favoritesProvider = Provider<List<ClipItem>>((ref) {
  final clipsAsync = ref.watch(clipsProvider);
  return clipsAsync.when(
    data: (clips) => clips.where((c) => c.isFavorite).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

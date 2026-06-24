import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/clips_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_outline,
              message: 'No favorites yet',
            )
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (_, i) {
                final item = favorites[i];
                return ListTile(
                  title: Text(
                    item.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () async {
                      final db = await Database.getInstance();
                      await db.toggleFavorite(item.text);
                      ref.invalidate(clipsProvider);
                    },
                  ),
                );
              },
            ),
    );
  }
}

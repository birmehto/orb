import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/swipe_to_delete.dart';
import '../providers/clips_providers.dart';

class ClipsScreen extends ConsumerStatefulWidget {
  const ClipsScreen({super.key});

  @override
  ConsumerState<ClipsScreen> createState() => _ClipsScreenState();
}

class _ClipsScreenState extends ConsumerState<ClipsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clipsAsync = ref.watch(clipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clip History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            onPressed: () => context.push('/favorites'),
            tooltip: 'Favorites',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Search clips...',
              leading: const Icon(Icons.search, size: 20),
              onChanged: (v) => setState(() => _query = v),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: clipsAsync.when(
              data: (clips) {
                final filtered = ref.watch(filteredClipsProvider(_query));
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.content_paste_off_outlined,
                    message: 'No clips yet',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final clip = filtered[index];
                    return SwipeToDelete(
                      itemKey: ValueKey(
                        'clip_${clip.timestamp.millisecondsSinceEpoch}',
                      ),
                      onDelete: () async {
                        final db = await Database.getInstance();
                        await db.deleteClip(clip.text);
                        ref.invalidate(clipsProvider);
                      },
                      child: ListTile(
                        title: Text(
                          clip.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          formatTime(clip.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            clip.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: clip.isFavorite ? Colors.red : null,
                          ),
                          onPressed: () async {
                            final db = await Database.getInstance();
                            await db.toggleFavorite(clip.text);
                            ref.invalidate(clipsProvider);
                          },
                        ),
                        onTap: () => _copyToClipboard(context, clip.text),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text('Failed to load clips')),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    showAppSnackBar(
      context,
      text.length > 40 ? '${text.substring(0, 40)}...' : text,
      seconds: 1,
    );
  }
}

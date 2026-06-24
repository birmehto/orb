import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PermissionCard extends ConsumerWidget {
  final String title;
  final String description;
  final IconData icon;
  final FutureProvider<bool> permissionProvider;
  final VoidCallback onRequest;
  final Color? iconColor;

  const PermissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.permissionProvider,
    required this.onRequest,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(permissionProvider);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildTrailing(context, permissionAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, AsyncValue<bool> asyncValue) {
    final theme = Theme.of(context);

    return asyncValue.when(
      data: (granted) {
        if (granted) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  'Granted',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          );
        }
        return FilledButton.tonalIcon(
          onPressed: onRequest,
          icon: const Icon(Icons.settings, size: 16),
          label: const Text('Allow'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(fontSize: 13),
          ),
        );
      },
      loading: () => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
      error: (_, _) => Text(
        'Error',
        style: TextStyle(color: theme.colorScheme.error),
      ),
    );
  }
}

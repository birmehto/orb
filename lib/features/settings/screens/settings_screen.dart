import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database.dart';
import '../../../core/models/bubble_settings.dart';
import '../../../services/platform_service.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _presetColors = [
    0xFF6366F1,
    0xFF8B5CF6,
    0xFFEC4899,
    0xFFEF4444,
    0xFFF59E0B,
    0xFF10B981,
    0xFF06B6D4,
    0xFF1E293B,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(bubbleSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _sectionHeader(theme, 'Bubble Style'),
            _colorPicker(theme, settings),
            _sizeSlider(theme, settings),
            _opacitySlider(theme, settings),
            const SizedBox(height: 8),
            _sectionHeader(theme, 'Behavior'),
            _autoHideTile(theme, settings),
            const SizedBox(height: 8),
            _sectionHeader(theme, 'Security'),
            _pinTile(theme, ref.watch(isPinEnabledProvider).asData?.value ?? false),
            _lockScreenTile(theme),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('Failed to load settings')),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _colorPicker(ThemeData theme, BubbleSettings settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Color',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presetColors
                    .map(
                      (c) => GestureDetector(
                        onTap: () =>
                            _updateSettings(settings.copyWith(color: c)),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: settings.color == c
                                ? Border.all(
                                    color: theme.colorScheme.onSurface,
                                    width: 3,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Color(c).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: settings.color == c
                              ? Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sizeSlider(ThemeData theme, BubbleSettings settings) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Size: ${settings.size.round()}px',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              value: settings.size,
              min: 40,
              max: 80,
              divisions: 8,
              label: '${settings.size.round()}px',
              onChanged: (v) => _updateSettings(settings.copyWith(size: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opacitySlider(ThemeData theme, BubbleSettings settings) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opacity: ${(settings.opacity * 100).round()}%',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              value: settings.opacity,
              min: 0.3,
              max: 1.0,
              divisions: 7,
              label: '${(settings.opacity * 100).round()}%',
              onChanged: (v) => _updateSettings(settings.copyWith(opacity: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _autoHideTile(ThemeData theme, BubbleSettings settings) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Auto-hide',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Fade bubble after inactivity',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            value: settings.autoHideEnabled,
            onChanged: (v) =>
                _updateSettings(settings.copyWith(autoHideEnabled: v)),
          ),
          if (settings.autoHideEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Timeout: ${settings.autoHideTimeoutSeconds}s',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: settings.autoHideTimeoutSeconds.toDouble(),
                      min: 10,
                      max: 120,
                      divisions: 11,
                      label: '${settings.autoHideTimeoutSeconds}s',
                      onChanged: (v) => _updateSettings(
                        settings.copyWith(autoHideTimeoutSeconds: v.round()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _pinTile(ThemeData theme, bool pinEnabled) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
            ),
            title: const Text(
              'PIN Lock',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              pinEnabled ? 'PIN is set' : 'Require PIN to use bubble',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: pinEnabled
                ? TextButton(
                    onPressed: () => _removePin(),
                    child: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : FilledButton.tonal(
                    onPressed: () => _setupPin(),
                    child: const Text('Set PIN'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _lockScreenTile(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.screen_lock_portrait_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        title: const Text(
          'Lock Screen Protection',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Restrict bubble actions when device is locked',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _updateSettings(BubbleSettings s) async {
    final db = await Database.getInstance();
    await db.saveSettings(s);
    ref.invalidate(bubbleSettingsProvider);
    try {
      await PlatformService().updateBubbleStyle(
        s.color,
        s.size.round(),
        s.opacity,
      );
      await PlatformService().setAutoHideEnabled(
        s.autoHideEnabled,
        s.autoHideTimeoutSeconds,
      );
    } catch (_) {}
  }

  Future<void> _setupPin() async {
    final ctrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter PIN (4-6 digits)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final pin = ctrl.text.trim();
              final confirm = confirmCtrl.text.trim();
              if (pin.length < 4) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PIN must be 4-6 digits')),
                );
                return;
              }
              if (pin != confirm) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PINs do not match')),
                );
                return;
              }
              Navigator.pop(ctx, pin);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final db = await Database.getInstance();
      await db.setPin(result);
      ref.invalidate(isPinEnabledProvider);
    }
  }

  Future<void> _removePin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove PIN?'),
        content: const Text(
          'Anyone can use the bubble without entering a PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await Database.getInstance();
      await db.removePin();
      ref.invalidate(isPinEnabledProvider);
    }
  }
}

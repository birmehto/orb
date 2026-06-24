import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/colors.dart';
import '../../../core/database.dart';
import '../../../core/models/bubble_settings.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../services/platform_service.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
            const SectionHeader(title: 'Bubble Style'),
            _colorPicker(theme, settings),
            _sizeSlider(theme, settings),
            _opacitySlider(theme, settings),
            const SizedBox(height: 8),
            const SectionHeader(title: 'Behavior'),
            _autoHideTile(theme, settings),
            const SizedBox(height: 8),
            const SectionHeader(title: 'About'),
            _aboutSection(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('Failed to load settings')),
      ),
    );
  }

  Widget _aboutSection() {
    final theme = Theme.of(context);
    final appInfoAsync = ref.watch(appInfoProvider);
    return Column(
      children: [
        SettingsTile(
          icon: Icons.code,
          iconColor: AppColors.primary,
          title: 'GitHub',
          subtitle: 'View source code and contribute',
          trailing: Icon(
            Icons.open_in_new,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onTap: () async {
            final uri = Uri.parse('https://github.com/anomalyco/opencode');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
        ),
        const SizedBox(height: 16),
        appInfoAsync.when(
          data: (info) => Center(
            child: Text(
              '${info.appName} ${info.versionLabel}',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
                fontSize: 12,
              ),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
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
                children: AppColors.presetColorInts
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
}

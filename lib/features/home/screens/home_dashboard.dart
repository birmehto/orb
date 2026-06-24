import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/colors.dart';
import '../../../core/providers.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/settings_tile.dart';
import '../providers/home_providers.dart';
import '../widgets/permission_card.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard>
    with WidgetsBindingObserver {
  bool _serviceEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(overlayPermissionProvider);
      ref.invalidate(notificationPermissionProvider);
      ref.invalidate(batteryOptimizationProvider);
      ref.invalidate(bubbleServiceRunningProvider);
      _syncState();
    }
  }

  Future<void> _syncState() async {
    final service = ref.read(platformServiceProvider);
    final running = await service.isServiceRunning();
    if (mounted) setState(() => _serviceEnabled = running);
  }

  Future<void> _toggleService(bool enable) async {
    final service = ref.read(platformServiceProvider);
    if (enable) {
      final hasOverlay = await service.checkOverlayPermission();
      if (!hasOverlay) {
        showAppSnackBar(context, 'Please grant overlay permission first');
        ref.invalidate(overlayPermissionProvider);
        return;
      }
      if (mounted) setState(() => _serviceEnabled = true);
      await service.startService();
      showAppSnackBar(context, 'Bubble activated');
    } else {
      await service.stopService();
      if (mounted) setState(() => _serviceEnabled = false);
      showAppSnackBar(context, 'Bubble deactivated');
    }
    ref.invalidate(bubbleServiceRunningProvider);
  }

  Future<void> _requestOverlay() async {
    final service = ref.read(platformServiceProvider);
    await service.requestOverlayPermission();
    await Future.delayed(const Duration(seconds: 1));
    ref.invalidate(overlayPermissionProvider);
    await _syncState();
  }

  Future<void> _requestNotification() async {
    final service = ref.read(platformServiceProvider);
    await service.requestNotificationPermission();
    await Future.delayed(const Duration(milliseconds: 500));
    ref.invalidate(notificationPermissionProvider);
  }

  Future<void> _requestBatteryOptimization() async {
    final service = ref.read(platformServiceProvider);
    await service.requestBatteryOptimization();
    await Future.delayed(const Duration(seconds: 1));
    ref.invalidate(batteryOptimizationProvider);
  }

  Future<void> _openAutoStart() async {
    final service = ref.read(platformServiceProvider);
    await service.openAutoStartSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orb'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(bubbleServiceRunningProvider);
              ref.invalidate(overlayPermissionProvider);
              ref.invalidate(notificationPermissionProvider);
              ref.invalidate(batteryOptimizationProvider);
              _syncState();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 8),
          _buildHeader(theme),
          const SizedBox(height: 24),
          _buildServiceToggle(theme),
          const SizedBox(height: 24),
          _buildPermissionsSection(),
          const SizedBox(height: 24),
          _buildBatterySection(),
          const SizedBox(height: 24),
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20, offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 12),
        Text('Floating Bubble',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Quick access to clipboard search and copy',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
      ],
    );
  }

  Widget _buildServiceToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: SwitchListTile(
          value: _serviceEnabled,
          onChanged: _toggleService,
          title: const Text('Enable Bubble', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            _serviceEnabled ? 'Bubble is active and visible' : 'Tap to show the floating bubble',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          secondary: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _serviceEnabled
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _serviceEnabled ? Icons.visibility : Icons.visibility_off,
              color: _serviceEnabled ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    final overlayGranted = ref.watch(overlayPermissionProvider).asData?.value ?? false;
    final notificationGranted = ref.watch(notificationPermissionProvider).asData?.value ?? true;

    final cards = <Widget>[];
    if (!overlayGranted) {
      cards.add(PermissionCard(
        title: 'Display Overlay',
        description: 'Required to show bubble above other apps',
        icon: Icons.layers_outlined,
        permissionProvider: overlayPermissionProvider,
        onRequest: _requestOverlay,
        iconColor: AppColors.primary,
      ));
    }
    if (!notificationGranted) {
      cards.add(PermissionCard(
        title: 'Notifications',
        description: 'Required for foreground service on Android 13+',
        icon: Icons.notifications_outlined,
        permissionProvider: notificationPermissionProvider,
        onRequest: _requestNotification,
        iconColor: AppColors.pink,
      ));
    }
    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Permissions'),
        const SizedBox(height: 8),
        ...cards,
      ],
    );
  }

  Widget _buildBatterySection() {
    final batteryGranted = ref.watch(batteryOptimizationProvider).asData?.value ?? true;

    final cards = <Widget>[];
    if (!batteryGranted) {
      cards.add(PermissionCard(
        title: 'Battery Optimization',
        description: 'Exclude from battery optimization for reliable operation',
        icon: Icons.battery_charging_full_outlined,
        permissionProvider: batteryOptimizationProvider,
        onRequest: _requestBatteryOptimization,
        iconColor: AppColors.green,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Battery & Optimization'),
        const SizedBox(height: 8),
        ...cards,
        SettingsTile(
          icon: Icons.power_settings_new_rounded,
          iconColor: AppColors.amber,
          title: 'Auto Start',
          subtitle: 'Enable auto-start for persistent background operation',
          trailing: FilledButton.tonalIcon(
            onPressed: _openAutoStart,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final theme = Theme.of(context);
    final appInfoAsync = ref.watch(appInfoProvider);
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(child: Text('Tap the bubble to show Search & Copy options',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12))),
        const SizedBox(height: 4),
        appInfoAsync.when(
          data: (info) => Center(
            child: Text(info.versionLabel,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 12)),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

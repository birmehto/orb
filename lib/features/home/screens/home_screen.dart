import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';
import '../widgets/permission_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
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
    if (mounted) {
      setState(() => _serviceEnabled = running);
    }
  }

  Future<void> _toggleService(bool enable) async {
    final service = ref.read(platformServiceProvider);

    if (enable) {
      final hasOverlay = await service.checkOverlayPermission();
      if (!hasOverlay) {
        _showSnackBar('Please grant overlay permission first');
        ref.invalidate(overlayPermissionProvider);
        return;
      }

      if (mounted) {
        setState(() => _serviceEnabled = true);
      }
      await service.startService();
      _showSnackBar('Bubble activated');
    } else {
      await service.stopService();
      if (mounted) {
        setState(() => _serviceEnabled = false);
      }
      _showSnackBar('Bubble deactivated');
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
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
          _buildPermissionsSection(theme),
          const SizedBox(height: 24),
          _buildBatterySection(theme),
          const SizedBox(height: 24),
          _buildInfoSection(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Floating Bubble',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quick access to clipboard search and copy',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
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
          title: const Text(
            'Enable Bubble',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            _serviceEnabled
                ? 'Bubble is active and visible'
                : 'Tap to show the floating bubble',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _serviceEnabled
                  ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _serviceEnabled ? Icons.visibility : Icons.visibility_off,
              color: _serviceEnabled
                  ? const Color(0xFF6366F1)
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Permissions',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        PermissionCard(
          title: 'Display Overlay',
          description: 'Required to show bubble above other apps',
          icon: Icons.layers_outlined,
          permissionProvider: overlayPermissionProvider,
          onRequest: _requestOverlay,
          iconColor: const Color(0xFF6366F1),
        ),
        PermissionCard(
          title: 'Notifications',
          description: 'Required for foreground service on Android 13+',
          icon: Icons.notifications_outlined,
          permissionProvider: notificationPermissionProvider,
          onRequest: _requestNotification,
          iconColor: const Color(0xFFEC4899),
        ),
      ],
    );
  }

  Widget _buildBatterySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Battery & Optimization',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        PermissionCard(
          title: 'Battery Optimization',
          description: 'Exclude from battery optimization for reliable operation',
          icon: Icons.battery_charging_full_outlined,
          permissionProvider: batteryOptimizationProvider,
          onRequest: _requestBatteryOptimization,
          iconColor: const Color(0xFF10B981),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.power_settings_new_rounded,
                color: Color(0xFFF59E0B),
                size: 24,
              ),
            ),
            title: const Text(
              'Auto Start',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Enable auto-start for persistent background operation',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
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
        ),
      ],
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap the bubble to show Search & Copy options',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'v0.1.0',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as custom_auth;
import '../../providers/device_provider.dart';
import '../settings_screen.dart';
import '../energy_monitoring_screen.dart';
import '../automation_screen.dart';
import '../device_control_screen.dart';
import '../../models/device_model.dart';
import '../../services/voice_service.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  StreamSubscription? _voiceStatusSubscription;

  @override
  void initState() {
    super.initState();
    _voiceStatusSubscription = VoiceService.statusStream.listen((status) {
      if (status.startsWith('Error:') || status == 'notListening') {
         // Optionally filter specific statuses if 'notListening' is too spammy
         if(status.startsWith('Error:')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(status), backgroundColor: Colors.red),
            );
         }
      }
    });
  }

  @override
  void dispose() {
    _voiceStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: StreamBuilder<String>(
              stream: VoiceService.statusStream,
              builder: (context, snapshot) {
                final isListening = VoiceService.isListening;
                return Icon(
                   isListening ? Icons.mic : Icons.mic_none,
                  color: isListening ? Colors.red : null,
                );
              }
            ),
            onPressed: () async {
              if (VoiceService.isListening) {
                await VoiceService.stopListening();
              } else {
                await VoiceService.startListening();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider =
                  Provider.of<custom_auth.AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // The provider is listening to real-time updates, so no need to fetch manually.
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section with enhanced design
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),

                    // Quick stats with animations
                    _buildQuickStats(),

                    const SizedBox(height: 20),

                    // Quick access cards in a more compact layout
                    _buildQuickAccessCards(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Alerts section (if any alerts exist)
            SliverToBoxAdapter(
              child: _buildAlertsSection(),
            ),

            // Device sections with better organization
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Devices section
                    _buildDevicesSection(),
                    const SizedBox(height: 24),

                    // Sensors section
                    _buildSensorsSection(),

                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'emergency_fab',
        onPressed: _handleEmergencyAction,
        icon: const Icon(Icons.emergency),
        label: const Text('Emergency'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Home',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Control your smart devices with ease',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.home,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCards() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAccessCard(
            icon: Icons.electric_bolt,
            title: 'Energy',
            subtitle: 'Usage & Costs',
            color: Colors.green,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EnergyMonitoringScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAccessCard(
            icon: Icons.auto_mode,
            title: 'Automation',
            subtitle: 'Scenes & Schedules',
            color: Colors.blue,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AutomationScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        final onlineDevices =
            deviceProvider.devices.where((d) => d.isOnline).length;
        final activeDevices =
            deviceProvider.devices.where((d) => d.isActive).length;
        final totalSensors =
            deviceProvider.devices.where((d) => d.type == 'sensor').length;

        return Row(
          children: [
            Expanded(
              child: AnimatedStatCard(
                title: 'Online',
                value: onlineDevices,
                icon: Icons.device_hub,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedStatCard(
                title: 'Active',
                value: activeDevices,
                icon: Icons.power_settings_new,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedStatCard(
                title: 'Sensors',
                value: totalSensors,
                icon: Icons.sensors,
                color: Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDevicesSection() {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        if (deviceProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final relays =
            deviceProvider.devices.where((d) => d.type == 'relay').toList();

        if (relays.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.device_unknown,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No devices found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first smart device to get started',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Devices',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    '${relays.length} ${relays.length == 1 ? 'device' : 'devices'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2, // 3 cols for Tablet (Bigger)
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: MediaQuery.of(context).size.width > 600 ? 0.9 : 0.65, // Taller ratios
              ),
              itemCount: relays.length,
              itemBuilder: (context, index) {
                final device = relays[index];
                return _buildDeviceCard(device);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceCard(Device device, {Key? key}) {
    final bool isActive = device.isActive;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DeviceControlScreen(device: device),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.max, // Expand to fill IntrinsicHeight
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Push content apart
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Icon + Status Dot
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                                    : Theme.of(context).disabledColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getDeviceIcon(device.type),
                                color: isActive
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).disabledColor,
                                size: 28,
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: device.isOnline ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        // Middle: Text Info
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                device.room,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        // Bottom: Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isActive ? 'ON' : 'OFF',
                              style: TextStyle(
                                color: isActive ? Theme.of(context).primaryColor : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Transform.scale(
                              scale: 0.9,
                              child: Switch(
                                value: isActive,
                                onChanged: device.isOnline
                                    ? (value) async {
                                        final deviceProvider = Provider.of<DeviceProvider>(
                                            context,
                                            listen: false);
                                        await deviceProvider.controlRelay(
                                            device.id, value);
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSensorsSection() {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        if (deviceProvider.isLoading) {
          return const SizedBox.shrink();
        }

        final sensors =
            deviceProvider.devices.where((d) => d.type == 'sensor').toList();

        if (sensors.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sensor Data',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    '${sensors.length} ${sensors.length == 1 ? 'sensor' : 'sensors'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sensors.length,
              itemBuilder: (context, index) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildSensorCard(sensors[index],
                      key: ValueKey(sensors[index].id)),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSensorCard(Device sensor, {Key? key}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getSensorIcon(sensor.name),
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          sensor.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${sensor.properties['value']}'),
            const SizedBox(height: 2),
            Text(
              _formatTimestamp(sensor.lastUpdated),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.6),
                  ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
        ),
        onTap: () {
          // Navigate to detailed sensor view
        },
      ),
      key: key,
    );
  }

  Widget _buildAlertsSection() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: NotificationService().alertStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final alert = snapshot.data!;

        // Check if this is a dismissed alert notification
        if (alert['dismissed'] == true) {
          return const SizedBox.shrink();
        }

        final color = alert['color'] as Color? ?? Colors.orange;
        final alertId = alert['id'] as String? ?? '';

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: color, width: 4)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getAlertIcon(alert['type'] as String?),
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert['title'] ?? 'Alert',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert['message'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(
                                alert['timestamp'] ?? DateTime.now()),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (alertId.isNotEmpty) {
                          NotificationService().dismissAlert(alertId);
                        }
                      },
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getAlertIcon(String? type) {
    switch (type) {
      case 'gas_leak':
        return Icons.warning;
      case 'security':
        return Icons.security;
      case 'fire':
        return Icons.local_fire_department;
      case 'temperature_high':
        return Icons.thermostat;
      case 'temperature_low':
        return Icons.ac_unit;
      case 'humidity_high':
        return Icons.water_drop;
      case 'device_offline':
        return Icons.cloud_off;
      case 'energy_high':
        return Icons.bolt;
      case 'door_open':
        return Icons.door_front_door;
      case 'window_open':
        return Icons.window;
      default:
        return Icons.notifications;
    }
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'light':
        return Icons.lightbulb;
      case 'thermostat':
        return Icons.thermostat;
      case 'camera':
        return Icons.videocam;
      case 'lock':
        return Icons.lock;
      case 'fan':
        return Icons.ac_unit;
      case 'relay':
        return Icons.power_settings_new;
      default:
        return Icons.device_unknown;
    }
  }

  IconData _getSensorIcon(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'motiondetected':
        return Icons.directions_run;
      case 'gaslevel':
        return Icons.gas_meter;
      default:
        return Icons.sensors;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime parsedTimestamp;

    if (timestamp is String) {
      try {
        parsedTimestamp = DateTime.parse(timestamp);
      } catch (e) {
        // If parsing fails, use current time
        parsedTimestamp = DateTime.now();
      }
    } else if (timestamp is DateTime) {
      parsedTimestamp = timestamp;
    } else {
      // Fallback to current time
      parsedTimestamp = DateTime.now();
    }

    final now = DateTime.now();
    final difference = now.difference(parsedTimestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleEmergencyAction() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Emergency Action'),
          content: const Text('Choose emergency action:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performEmergencyShutdown();
              },
              child: const Text('Turn All Off'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _callEmergencyServices();
              },
              child: const Text('Call Emergency'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _performEmergencyShutdown() {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    // Turn off all active relays
    for (final device in deviceProvider.devices) {
      if (device.type == 'relay' && device.isActive) {
        deviceProvider.controlRelay(device.name, false);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency shutdown initiated - All devices turned off'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _callEmergencyServices() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling emergency services...'),
        backgroundColor: Colors.red,
      ),
    );
    // Implement actual emergency call functionality
  }


}

class AnimatedStatCard extends StatefulWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const AnimatedStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: widget.value),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Text(
                    value.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

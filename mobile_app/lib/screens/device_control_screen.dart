import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/device_model.dart';

class DeviceControlScreen extends StatefulWidget {
  final Device device;

  const DeviceControlScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late Device _device;
  double _brightness = 0.5;
  double _temperature = 22.0;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
    _loadDeviceSettings();
  }

  void _loadDeviceSettings() {
    final properties = _device.properties;
    if (properties.containsKey('brightness')) {
      _brightness = properties['brightness'] / 100.0;
    }
    if (properties.containsKey('temperature')) {
      _temperature = properties['temperature'].toDouble();
    }
  }

  Future<void> _controlDevice(String action, [Map<String, dynamic>? params]) async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

    if (_device.type == 'relay') {
      await deviceProvider.controlRelay(_device.name, action == 'turn_on');
    } else {
      // Handle other device types here
    }

    if (mounted) {
      setState(() {
        _device = deviceProvider.devices.firstWhere((d) => d.id == _device.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_device.name),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _device.isOnline ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device status card
            _buildDeviceStatusCard(),

            const SizedBox(height: 24),

            // Device-specific controls
            _buildDeviceControls(),

            const SizedBox(height: 24),

            // Device information
            _buildDeviceInfo(),

            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _device.isActive
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getDeviceIcon(_device.type),
                size: 40,
                color: _device.isActive
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _device.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_device.type} • ${_device.room}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _device.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _device.isActive ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: _device.isActive ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _device.isActive,
              onChanged: _device.isOnline ? (value) {
                _controlDevice(value ? 'turn_on' : 'turn_off');
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceControls() {
    switch (_device.type.toLowerCase()) {
      case 'light':
        return _buildLightControls();
      case 'thermostat':
        return _buildThermostatControls();
      case 'camera':
        return _buildCameraControls();
      case 'lock':
        return _buildLockControls();
      case 'relay':
        return _buildGenericControls();
      case 'sensor':
        return _buildSensorControls();
      default:
        return _buildGenericControls();
    }
  }

  Widget _buildLightControls() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Light Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Brightness: ${(_brightness * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _brightness,
              onChanged: (value) {
                setState(() {
                  _brightness = value;
                });
              },
              onChangeEnd: (value) {
                _controlDevice('set_brightness', {'brightness': (value * 100).round()});
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _controlDevice('set_color', {'color': 'warm_white'}),
                    icon: const Icon(Icons.wb_incandescent),
                    label: const Text('Warm White'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _controlDevice('set_color', {'color': 'cool_white'}),
                    icon: const Icon(Icons.wb_sunny),
                    label: const Text('Cool White'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThermostatControls() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temperature Control',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '${_temperature.round()}°C',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Slider(
              value: _temperature,
              min: 16,
              max: 30,
              divisions: 14,
              onChanged: (value) {
                setState(() {
                  _temperature = value;
                });
              },
              onChangeEnd: (value) {
                _controlDevice('set_temperature', {'temperature': value.round()});
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _controlDevice('set_mode', {'mode': 'heat'}),
                    icon: const Icon(Icons.local_fire_department),
                    label: const Text('Heat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _controlDevice('set_mode', {'mode': 'cool'}),
                    icon: const Icon(Icons.ac_unit),
                    label: const Text('Cool'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _controlDevice('set_mode', {'mode': 'auto'}),
                    icon: const Icon(Icons.autorenew),
                    label: const Text('Auto'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Camera Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.videocam_off,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isRecording = !_isRecording;
                      });
                      _controlDevice(_isRecording ? 'start_recording' : 'stop_recording');
                    },
                    icon: Icon(_isRecording ? Icons.stop : Icons.videocam),
                    label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _controlDevice('take_snapshot'),
                    icon: const Icon(Icons.camera),
                    label: const Text('Snapshot'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockControls() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lock Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Icon(
                _device.isActive ? Icons.lock_open : Icons.lock,
                size: 80,
                color: _device.isActive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _controlDevice(_device.isActive ? 'lock' : 'unlock'),
                icon: Icon(_device.isActive ? Icons.lock : Icons.lock_open),
                label: Text(_device.isActive ? 'Lock Door' : 'Unlock Door'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _device.isActive ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericControls() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('No specific controls available for this device type.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorControls() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sensor Value',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '${_device.properties['value']}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Device ID', _device.id),
            _buildInfoRow('Type', _device.type),
            _buildInfoRow('Room', _device.room),
            _buildInfoRow('Status', _device.isOnline ? 'Online' : 'Offline'),
            _buildInfoRow('Last Updated', _formatDateTime(_device.lastUpdated)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _controlDevice('restart'),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Restart'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _controlDevice('update_firmware'),
                    icon: const Icon(Icons.system_update),
                    label: const Text('Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      case 'sensor':
        return Icons.sensors;
      default:
        return Icons.device_unknown;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
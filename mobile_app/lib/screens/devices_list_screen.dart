import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/device_model.dart';
import 'device_control_screen.dart';

class DevicesListScreen extends StatefulWidget {
  const DevicesListScreen({Key? key}) : super(key: key);

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  String _selectedRoom = 'All';
  String _selectedType = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new device
            },
          ),
        ],
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, child) {
          if (deviceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredDevices = _filterDevices(deviceProvider.devices);

          return Column(
            children: [
              // Filters
              _buildFilters(),

              // Device list
              Expanded(
                child: filteredDevices.isEmpty
                    ? _buildEmptyState()
                    : _buildDeviceList(filteredDevices),
              ),
            ],
          );
        },
      ),
floatingActionButton: FloatingActionButton(
        heroTag: 'devices_list_fab',
        onPressed: () {
          print('Add new device');
          // Implement logic to add a new device
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Room filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedRoom,
              decoration: const InputDecoration(
                labelText: 'Room',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Rooms')),
                DropdownMenuItem(value: 'Living Room', child: Text('Living Room')),
                DropdownMenuItem(value: 'Kitchen', child: Text('Kitchen')),
                DropdownMenuItem(value: 'Bedroom', child: Text('Bedroom')),
                DropdownMenuItem(value: 'Bathroom', child: Text('Bathroom')),
                DropdownMenuItem(value: 'Entrance', child: Text('Entrance')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRoom = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          // Type filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Types')),
                DropdownMenuItem(value: 'light', child: Text('Lights')),
                DropdownMenuItem(value: 'thermostat', child: Text('Thermostats')),
                DropdownMenuItem(value: 'camera', child: Text('Cameras')),
                DropdownMenuItem(value: 'lock', child: Text('Locks')),
                DropdownMenuItem(value: 'fan', child: Text('Fans')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices,
            size: 80,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No devices found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first smart device to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Add new device
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(List<Device> devices) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        return _buildDeviceCard(devices[index]);
      },
    );
  }

  Widget _buildDeviceCard(Device device) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DeviceControlScreen(device: device),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: device.isActive
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getDeviceIcon(device.type),
                  size: 30,
                  color: device.isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${device.type} • ${device.room}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: device.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            device.isActive ? 'ON' : 'OFF',
                            style: TextStyle(
                              color: device.isActive ? Colors.green : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: device.isOnline ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: device.isOnline ? Colors.green : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Device> _filterDevices(List<Device> devices) {
    return devices.where((device) {
      final roomMatch = _selectedRoom == 'All' || device.room == _selectedRoom;
      final typeMatch = _selectedType == 'All' || device.type == _selectedType;
      return roomMatch && typeMatch;
    }).toList();
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
}
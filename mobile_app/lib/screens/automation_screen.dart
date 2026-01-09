import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/auth_provider.dart' as custom_auth;
import '../models/device_model.dart';
import '../models/scene_model.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({Key? key}) : super(key: key);

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  final DatabaseService _databaseService = DatabaseService();
  var uuid = Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation'),
        elevation: 0,
      ),
      body: _buildScenesTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateSceneDialog();
        },
        heroTag: 'automation_fab',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScenesTab() {
    return StreamBuilder<List<Scene>>(
      stream: _databaseService.getScenes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allScenes = snapshot.data ?? [];
        // Filter out notification-only scenes. Safe check for actions.
        final scenes = allScenes.where((s) {
            if (s.actions == null) return true; // Keep it if we can't determine (or maybe hide? let's keep to be safe)
            return !s.actions.containsKey('notify');
        }).toList();
        
        if (scenes.isEmpty) {
          return const Center(child: Text('No scenes created yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scenes.length,
          itemBuilder: (context, index) {
            final scene = scenes[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(int.parse(scene.color)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    IconData(int.parse(scene.icon), fontFamily: 'MaterialIcons'),
                    color: Color(int.parse(scene.color)),
                  ),
                ),
                title: Text(
                  scene.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scene.description),
                    const SizedBox(height: 4),
                    Text(
                      'Devices: ${scene.devices.join(', ')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _activateScene(scene),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(int.parse(scene.color)),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Activate'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _databaseService.deleteScene(scene.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _activateScene(Scene scene) async {
    final authProvider = Provider.of<custom_auth.AuthProvider>(context, listen: false);
    final token = authProvider.user?.uid;

    if (token == null) return;

    try {
      // Control devices based on scene
      for (final deviceName in scene.devices) {
        await _controlDeviceForScene(deviceName, scene.actions, token);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activated ${scene.name} scene'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to activate scene: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _controlDeviceForScene(String deviceId, Map<String, dynamic> actions, String token) async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

    final device = deviceProvider.devices.firstWhere((d) => d.id == deviceId);

    if (device.id.isEmpty || !device.isOnline) return;

    final relayId = device.id.split('-').last;

    // Apply actions
    if (actions['turn_on'] == true) {
      await deviceProvider.controlRelay(relayId, true);
    } else if (actions['turn_off'] == true) {
      await deviceProvider.controlRelay(relayId, false);
    }
  }

  void _showCreateSceneDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    List<String> selectedDevices = [];
    String selectedIcon = 'lightbulb'; // Default icon
    Color selectedColor = Colors.blue;
    String _selectedAction = 'Turn On';
    String? _selectedTrigger = 'time';
    TimeOfDay _selectedTime = TimeOfDay.now();
    String? _selectedSensor;
    String _selectedCondition = '>';
    final valueController = TextEditingController();
    final messageController = TextEditingController();

    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final availableDevices = deviceProvider.devices.where((d) => d.type == 'relay').toList();
    final availableSensors = deviceProvider.devices.where((d) => d.type == 'sensor').toList();

    final iconOptions = {
      'lightbulb': Icons.lightbulb,
      'thermostat': Icons.thermostat,
      'lock': Icons.lock,
      'videocam': Icons.videocam,
      'tv': Icons.tv,
      'ac_unit': Icons.ac_unit,
    };

    final colorOptions = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.indigo,
      Colors.teal,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Scene'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scene Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Scene Name',
                    hintText: 'e.g., Party Mode',
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What does this scene do?',
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Icon Selection
                const Text('Icon:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: iconOptions.entries.map((entry) {
                    return InkWell(
                      onTap: () => setState(() => selectedIcon = entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selectedIcon == entry.key
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedIcon == entry.key
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(entry.value, size: 24),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Color Selection
                const Text('Color:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colorOptions.map((color) {
                    return InkWell(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Device Selection
                const Text('Select Devices:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                if (availableDevices.isEmpty)
                  const Text('No devices available. Add devices first.')
                else
                  Column(
                    children: availableDevices.map((device) {
                      final isSelected = selectedDevices.contains(device.id);
                      return CheckboxListTile(
                        title: Text(device.name),
                        subtitle: Text('${device.type} - ${device.room}'),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedDevices.add(device.id);
                            } else {
                              selectedDevices.remove(device.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 16),

                // Action Selection
                const Text('Action:', style: TextStyle(fontWeight: FontWeight.w500)),
                DropdownButton<String>(
                  value: _selectedAction,
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedAction = newValue!;
                    });
                  },
                  items: <String>['Turn On', 'Turn Off']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Trigger Selection
                const Text('Trigger:', style: TextStyle(fontWeight: FontWeight.w500)),
                DropdownButton<String>(
                  value: _selectedTrigger,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedTrigger = newValue;
                    });
                  },
                  items: <String>['time', 'sensor']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                if (_selectedTrigger == 'time')
                  ListTile(
                    title: const Text('Time'),
                    subtitle: Text(_selectedTime.format(context)),
                    leading: const Icon(Icons.schedule),
                    onTap: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time);
                      }
                    },
                  ),
                if (_selectedTrigger == 'sensor')
                  Column(
                    children: [
                      DropdownButton<String>(
                        value: _selectedSensor,
                        hint: const Text('Select Sensor'),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSensor = newValue;
                          });
                        },
                         items: availableSensors.isNotEmpty 
                            ? availableSensors.map<DropdownMenuItem<String>>((Device value) {
                                return DropdownMenuItem<String>(
                                  value: value.id,
                                  child: Text(value.name),
                                );
                              }).toList()
                            : [],
                      ),
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: _selectedCondition,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCondition = newValue!;
                              });
                            },
                            items: <String>['>', '<', '=', '>=', '<=']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: valueController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Value',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validation Logic
                bool isValid = true;
                if (nameController.text.isEmpty || descriptionController.text.isEmpty) {
                   isValid = false;
                }
                
                // If action is Device Control (On/Off), we NEED devices.
                if ((_selectedAction == 'Turn On' || _selectedAction == 'Turn Off') && selectedDevices.isEmpty) {
                   isValid = false;
                }
                
                // If action is Notification, we NEED a message.
                if (_selectedAction == 'Send Notification' && messageController.text.isEmpty) {
                   isValid = false;
                }

                if (isValid) {
                  Map<String, dynamic>? trigger;
                  if (_selectedTrigger == 'time') {
                    trigger = {'type': 'time', 'time': '${_selectedTime.hour}:${_selectedTime.minute}'};
                  } else if (_selectedTrigger == 'sensor') {
                    if (_selectedSensor == null || valueController.text.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a sensor and enter a value')),
                      );
                      return;
                    }
                    trigger = {
                      'type': 'sensor',
                      'sensorId': _selectedSensor,
                      'condition': _selectedCondition,
                      'value': double.parse(valueController.text),
                    };
                  }

                  final Map<String, dynamic> actions = {};
                  if (_selectedAction == 'Turn On') {
                    actions['turn_on'] = true;
                  } else if (_selectedAction == 'Turn Off') {
                    actions['turn_off'] = true;
                  }

                  _saveScene(
                    name: nameController.text,
                    description: descriptionController.text,
                    devices: selectedDevices,
                    icon: iconOptions.entries.firstWhere((element) => element.key == selectedIcon).value.codePoint.toString(),
                    color: selectedColor.value.toString(),
                    trigger: trigger,
                    actions: actions,
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Create Scene'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveScene({
    required String name,
    required String description,
    required List<String> devices,
    required String icon,
    required String color,
    required Map<String, dynamic> actions,
    Map<String, dynamic>? trigger,
  }) {
    final scene = Scene(
      id: uuid.v4(),
      name: name,
      description: description,
      devices: devices,
      icon: icon,
      color: color,
      actions: actions,
      trigger: trigger,
    );
    _databaseService.saveScene(scene);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scene "$name" created successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }}
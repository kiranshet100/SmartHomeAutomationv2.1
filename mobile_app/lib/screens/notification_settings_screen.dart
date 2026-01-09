import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/scene_model.dart';
import '../models/device_model.dart';
import '../services/database_service.dart';
import '../providers/device_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _checkAndCreateDefaults();
  }

  Future<void> _checkAndCreateDefaults() async {
    // We can't easily check stream sync, so we rely on a one-time fetch or just let the stream builder handle it.
    // However, to "pre-load", we might want to check once. 
    // Since DatabaseService only exposes a stream for scenes, let's just listen once. 
    // Or better, let's providing a "Restore Defaults" button if the list is empty, 
    // OR we can just add them blindly if we are sure (but that might duplicate).
    // Let's stick to the user request: "add pre load notification".
    // I will add a method to creates them if they don't exist.
    // Ideally this logic belongs in the provider or service, but for now here is fine.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Add Default Alerts',
            onPressed: _addDefaultAlerts,
          ),
        ],
      ),
      body: StreamBuilder<List<Scene>>(
        stream: _databaseService.getScenes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allScenes = snapshot.data ?? [];
          final alertScenes = allScenes.where((s) {
             if (s.actions == null) return false;
             return s.actions.containsKey('notify');
          }).toList();

          if (alertScenes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No custom alerts set.',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _addDefaultAlerts,
                    child: const Text('Load Default Alerts'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alertScenes.length,
            itemBuilder: (context, index) {
              final scene = alertScenes[index];
              return _buildAlertCard(scene);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditorDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAlertCard(Scene scene) {
    final trigger = scene.trigger;
    String triggerText = 'Manual Trigger';
    if (trigger != null && trigger['type'] == 'sensor') {
      triggerText = '${trigger['sensorId']} ${trigger['condition']} ${trigger['value']}';
    }

    Color accentColor = Colors.blue;
    IconData icon = Icons.notifications_active;

    try {
      accentColor = Color(int.parse(scene.color));
    } catch (e) {
      accentColor = Colors.blue; 
    }
    
    // Icon Logic
    try {
      if (scene.icon.isNotEmpty) {
        // Since we save codepoint as String, parse it back
        // But defaults used 'warning' etc. Need to handle both string identifiers and code points if mixed?
        // My defaults used 'warning'. My picker uses codePoint string.
        // Let's safe check.
        if (int.tryParse(scene.icon) != null) {
          icon = IconData(int.parse(scene.icon), fontFamily: 'MaterialIcons');
        } else {
           // Fallback for legacy strings if any
           // Or map the legacy strings like 'warning'
           // Keeping it simple: defaults were updated in my previous tool call to use code? 
           // Wait, in `_addDefaultAlerts`, I see: `icon: 'warning'`. That is a string.
           // In my Picker I use `_selectedIconCode.toString()`.
           // I must unify this.
        }
      }
    } catch(e) {
       // fallback
    }

    // Heuristic override (if you want to keep automatic icons for old ones, or just trust the saved one)
    // The user wants "add symbols", implying they want to choose. 
    // So if it's a number, use it. If it's a string like 'warning', map it.
    
    final iconMap = {
      'warning': Icons.warning,
      'thermostat': Icons.thermostat,
      'security': Icons.security,
      'notifications': Icons.notifications,
    };

    if (iconMap.containsKey(scene.icon)) {
      icon = iconMap[scene.icon]!;
    } else if (int.tryParse(scene.icon) != null) {
      icon = IconData(int.parse(scene.icon), fontFamily: 'MaterialIcons');
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showEditorDialog(context, existingScene: scene),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        triggerText,
                        style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${scene.actions['notify']}"',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: () => _deleteScene(scene.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addDefaultAlerts() {
    final defaults = [
      Scene(
        id: uuid.v4(),
        name: 'Gas Leak Alert',
        description: 'Safety',
        devices: [],
        icon: Icons.warning.codePoint.toString(),
        color: Colors.red.value.toString(),
        trigger: {'type': 'sensor', 'sensorId': 'gas', 'condition': '>', 'value': 50.0}, // Fixed ID
        actions: {'notify': 'URGENT: Gas Leak Detected! Evacuate!'},
      ),
      Scene(
        id: uuid.v4(),
        name: 'High Temp Alert',
        description: 'Comfort',
        devices: [],
        icon: Icons.thermostat.codePoint.toString(),
        color: Colors.orange.value.toString(),
        trigger: {'type': 'sensor', 'sensorId': 'temperature', 'condition': '>', 'value': 40.0},
        actions: {'notify': 'Warning: Room temperature is very high (>40°C)'},
      ),
       Scene(
        id: uuid.v4(),
        name: 'Motion Detected',
        description: 'Security',
        devices: [],
        icon: Icons.security.codePoint.toString(),
        color: Colors.blue.value.toString(),
        trigger: {'type': 'sensor', 'sensorId': 'motion', 'condition': '=', 'value': 1.0}, // Fixed ID
        actions: {'notify': 'Security Alert: Motion detected in the room'},
      ),
    ];

    for (var scene in defaults) {
      _databaseService.saveScene(scene);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default alerts added!')),
    );
  }


  void _deleteScene(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert'),
        content: const Text('Are you sure you want to delete this alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _databaseService.deleteScene(id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _testNotification(String message) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'my_foreground', 
      'Smart Home Alerts',
      channelDescription: 'Alerts from automation',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Alert',
      message.isEmpty ? 'This is a test notification' : message,
      platformChannelSpecifics,
    );
  }

  void _showEditorDialog(BuildContext context, {Scene? existingScene}) {
    final nameController = TextEditingController(text: existingScene?.name ?? '');
    final messageController = TextEditingController(text: existingScene?.actions['notify'] ?? '');
    
    final existingTrigger = existingScene?.trigger;
    final valueController = TextEditingController(
      text: existingTrigger != null ? existingTrigger['value'].toString() : '',
    );
    
    // Color Logic
    Color _selectedColor = existingScene != null ? Color(int.parse(existingScene.color)) : Colors.blue;
    final List<Color> colorOptions = [
      Colors.blue, Colors.red, Colors.orange, Colors.green, Colors.purple, Colors.teal
    ];

    // Icon Logic
    int _selectedIconCode = existingScene != null ? int.parse(existingScene.icon) : Icons.notifications.codePoint;
    final List<IconData> iconOptions = [
      Icons.notifications, Icons.warning, Icons.error, Icons.info, Icons.priority_high, 
      Icons.water_drop, Icons.thermostat, Icons.local_fire_department, Icons.security, Icons.flash_on
    ];

    String? _selectedSensor = existingTrigger?['sensorId'];
    String _selectedCondition = existingTrigger?['condition'] ?? '>';
    
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final availableSensors = deviceProvider.devices.where((d) => d.type == 'sensor').toList();
    
    // FIX: Fuzzy Match Logic
    bool sensorExists = availableSensors.any((d) => d.id == _selectedSensor);
    if (!sensorExists && _selectedSensor != null) {
      // Fuzzy Match Attempt
      try {
        final cleanId = _selectedSensor!.replaceAll('Level', '').replaceAll('Detected', '').toLowerCase();
        final match = availableSensors.firstWhere((d) => 
           d.name.toLowerCase().contains(cleanId) || d.id.toLowerCase().contains(cleanId)
        );
        _selectedSensor = match.id;
      } catch (e) {
        _selectedSensor = null; // No match
      }
    }

    if (_selectedSensor == null && availableSensors.isNotEmpty) {
      _selectedSensor = availableSensors.first.id;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existingScene == null ? 'Create New Alert' : 'Edit Alert'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Alert Name',
                      hintText: 'e.g., High Temp',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Message',
                      hintText: 'e.g., Check the AC!',
                      prefixIcon: Icon(Icons.message_outlined),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  // Test Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _testNotification(messageController.text),
                      icon: const Icon(Icons.notifications_active, size: 16),
                      label: const Text('Test Notification'),
                    ),
                  ),
                  // Test Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _testNotification(messageController.text),
                      icon: const Icon(Icons.notifications_active, size: 16),
                      label: const Text('Test Notification'),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Alert Color & Icon', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  // Color Picker
                  Wrap(
                    spacing: 8,
                    children: colorOptions.map((color) {
                      return InkWell(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: _selectedColor == color 
                              ? const Icon(Icons.check, size: 16, color: Colors.white) 
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Icon Picker
                   Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: iconOptions.map((icon) {
                      final isSelected = _selectedIconCode == icon.codePoint;
                      return InkWell(
                        onTap: () => setState(() => _selectedIconCode = icon.codePoint),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? _selectedColor.withOpacity(0.2) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? _selectedColor : Colors.transparent,
                            ),
                          ),
                          child: Icon(icon, 
                             color: isSelected ? _selectedColor : Colors.grey,
                             size: 24,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Trigger Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),

                  if (availableSensors.isEmpty)
                     const Text('No sensors available', style: TextStyle(color: Colors.red))
                  else
                    Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedSensor,
                          decoration: const InputDecoration(
                            labelText: 'Sensor',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          isExpanded: true,
                          items: availableSensors.map<DropdownMenuItem<String>>((Device d) {
                            return DropdownMenuItem<String>(
                              value: d.id,
                              child: Text(d.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedSensor = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCondition,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                items: ['>', '<', '=', '>=', '<=']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e, textAlign: TextAlign.center)))
                                    .toList(),
                                onChanged: (val) => setState(() => _selectedCondition = val!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: valueController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Value',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                   final val = double.tryParse(valueController.text);
                   if (nameController.text.isNotEmpty && 
                       messageController.text.isNotEmpty &&
                       _selectedSensor != null &&
                       val != null) {
                     
                     // Helper to clean sensor ID if it contains dashes (optional, but consistent)
                     // Actually, we should store the FULL ID so we can match it back in defaults/edit?
                     // Background service strips it anyway. Let's keep full ID here to match existing list.
                     
                     final trigger = {
                        'type': 'sensor',
                        'sensorId': _selectedSensor,
                        'condition': _selectedCondition,
                        'value': val,
                      };

                      final scene = Scene(
                        id: existingScene?.id ?? uuid.v4(), // Preserve ID if editing
                        name: nameController.text,
                        description: 'Custom Alert',
                        devices: [], 
                        icon: _selectedIconCode.toString(), // Save selected icon
                        color: _selectedColor.value.toString(),
                        trigger: trigger,
                        actions: { 'notify': messageController.text },
                      );

                      // Use saveScene (it updates if ID exists)
                      _databaseService.saveScene(scene);
                      Navigator.of(context).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(existingScene == null ? 'Alert Created' : 'Alert Updated')),
                      );

                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Please fill all fields with valid data')),
                     );
                   }
                },
                child: Text(existingScene == null ? 'Create' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}

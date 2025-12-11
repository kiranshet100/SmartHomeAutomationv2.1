import 'energy_usage_model.dart';

class Device {
  final String id;
  final String name;
  final String type; // e.g., 'light', 'thermostat', 'camera', 'lock'
  final String room;
  final bool isOnline;
  final bool isActive;
  final Map<String, dynamic> properties; // e.g., brightness, temperature
  final double? wattage;
  final DateTime lastUpdated;
  final DateTime? lastOnTime; // When device was last turned on
  final DateTime? lastOffTime; // When device was last turned off
  final List<DeviceUsageSession> usageSessions; // Historical usage sessions

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.room,
    required this.isOnline,
    required this.isActive,
    required this.properties,
    this.wattage,
    required this.lastUpdated,
    this.lastOnTime,
    this.lastOffTime,
    this.usageSessions = const [],
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      room: json['room'],
      isOnline: json['isOnline'] ?? false,
      isActive: json['isActive'] ?? false,
      properties: json['properties'] ?? {},
      wattage: (json['wattage'] as num?)?.toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      lastOnTime: json['lastOnTime'] != null
          ? DateTime.parse(json['lastOnTime'])
          : null,
      lastOffTime: json['lastOffTime'] != null
          ? DateTime.parse(json['lastOffTime'])
          : null,
      usageSessions: (json['usageSessions'] as List<dynamic>?)
              ?.map((session) => DeviceUsageSession.fromJson(session))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'room': room,
      'isOnline': isOnline,
      'isActive': isActive,
      'properties': properties,
      'wattage': wattage,
      'lastUpdated': lastUpdated.toIso8601String(),
      'lastOnTime': lastOnTime?.toIso8601String(),
      'lastOffTime': lastOffTime?.toIso8601String(),
      'usageSessions':
          usageSessions.map((session) => session.toJson()).toList(),
    };
  }

  Device copyWith({
    String? id,
    String? name,
    String? type,
    String? room,
    bool? isOnline,
    bool? isActive,
    Map<String, dynamic>? properties,
    double? wattage,
    DateTime? lastUpdated,
    DateTime? lastOnTime,
    DateTime? lastOffTime,
    List<DeviceUsageSession>? usageSessions,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      room: room ?? this.room,
      isOnline: isOnline ?? this.isOnline,
      isActive: isActive ?? this.isActive,
      properties: properties ?? this.properties,
      wattage: wattage ?? this.wattage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastOnTime: lastOnTime ?? this.lastOnTime,
      lastOffTime: lastOffTime ?? this.lastOffTime,
      usageSessions: usageSessions ?? this.usageSessions,
    );
  }
}

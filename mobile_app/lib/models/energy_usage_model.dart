/// Unified energy tracking model for both daily summaries and detailed session records
/// Use this for all energy consumption tracking - replaces EnergyHistory and EnergyUsageRecord
class EnergyRecord {
  final String deviceId;
  final String? deviceName; // Optional for daily history records
  final DateTime recordDate; // For daily totals or session start
  final DateTime? endTime; // Optional - only for session records
  final double? wattage; // Optional - only for active sessions
  final double energyConsumed; // in kWh - main tracking field
  final bool isActive; // Whether device/session is still ongoing
  final String recordType; // 'daily_total' or 'session' for clarity

  EnergyRecord({
    required this.deviceId,
    this.deviceName,
    required this.recordDate,
    this.endTime,
    this.wattage,
    required this.energyConsumed,
    required this.isActive,
    this.recordType = 'session',
  });

  /// Duration for session records
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(recordDate);
  }

  factory EnergyRecord.fromJson(Map<String, dynamic> json) {
    return EnergyRecord(
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      recordDate: DateTime.parse(
          json['recordDate'] ?? json['date'] ?? json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      wattage:
          json['wattage'] != null ? (json['wattage'] as num).toDouble() : null,
      energyConsumed:
          (json['energyConsumed'] ?? json['energy'] as num).toDouble(),
      isActive: json['isActive'] ?? false,
      recordType: json['recordType'] ?? 'session',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'recordDate': recordDate.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'wattage': wattage,
      'energyConsumed': energyConsumed,
      'isActive': isActive,
      'recordType': recordType,
    };
  }

  EnergyRecord copyWith({
    String? deviceId,
    String? deviceName,
    DateTime? recordDate,
    DateTime? endTime,
    double? wattage,
    double? energyConsumed,
    bool? isActive,
    String? recordType,
  }) {
    return EnergyRecord(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      recordDate: recordDate ?? this.recordDate,
      endTime: endTime ?? this.endTime,
      wattage: wattage ?? this.wattage,
      energyConsumed: energyConsumed ?? this.energyConsumed,
      isActive: isActive ?? this.isActive,
      recordType: recordType ?? this.recordType,
    );
  }

  /// Factory for creating daily summary records (replaces EnergyHistory)
  factory EnergyRecord.dailySummary({
    required String deviceId,
    required DateTime date,
    required double totalEnergyKwh,
  }) {
    return EnergyRecord(
      deviceId: deviceId,
      recordDate: date,
      energyConsumed: totalEnergyKwh,
      isActive: false,
      recordType: 'daily_total',
    );
  }

  /// Factory for creating session records (replaces EnergyUsageRecord)
  factory EnergyRecord.session({
    required String deviceId,
    required String deviceName,
    required DateTime startTime,
    required DateTime endTime,
    required double wattage,
    required double energyConsumedKwh,
  }) {
    return EnergyRecord(
      deviceId: deviceId,
      deviceName: deviceName,
      recordDate: startTime,
      endTime: endTime,
      wattage: wattage,
      energyConsumed: energyConsumedKwh,
      isActive: false,
      recordType: 'session',
    );
  }
}

// Deprecated: Use EnergyRecord instead
@Deprecated('Use EnergyRecord instead')
typedef EnergyUsageRecord = EnergyRecord;

class DeviceUsageSession {
  final String deviceId;
  final DateTime onTime;
  final DateTime? offTime;
  final double wattage;
  bool get isActive => offTime == null;

  DeviceUsageSession({
    required this.deviceId,
    required this.onTime,
    this.offTime,
    required this.wattage,
  });

  Duration get activeDuration => (offTime ?? DateTime.now()).difference(onTime);
  double get energyConsumed => wattage * activeDuration.inHours / 1000; // kWh

  factory DeviceUsageSession.fromJson(Map<String, dynamic> json) {
    return DeviceUsageSession(
      deviceId: json['deviceId'],
      onTime: DateTime.parse(json['onTime']),
      offTime: json['offTime'] != null ? DateTime.parse(json['offTime']) : null,
      wattage: json['wattage'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'onTime': onTime.toIso8601String(),
      'offTime': offTime?.toIso8601String(),
      'wattage': wattage,
    };
  }

  DeviceUsageSession copyWith({
    String? deviceId,
    DateTime? onTime,
    DateTime? offTime,
    double? wattage,
  }) {
    return DeviceUsageSession(
      deviceId: deviceId ?? this.deviceId,
      onTime: onTime ?? this.onTime,
      offTime: offTime ?? this.offTime,
      wattage: wattage ?? this.wattage,
    );
  }

  /// Convert to unified EnergyRecord
  EnergyRecord toEnergyRecord({String deviceName = ''}) {
    return EnergyRecord(
      deviceId: deviceId,
      deviceName: deviceName.isNotEmpty ? deviceName : null,
      recordDate: onTime,
      endTime: offTime ?? DateTime.now(),
      wattage: wattage,
      energyConsumed: energyConsumed,
      isActive: isActive,
      recordType: 'session',
    );
  }
}

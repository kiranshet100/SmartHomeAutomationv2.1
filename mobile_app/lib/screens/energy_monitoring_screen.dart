import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import '../providers/device_provider.dart';
import '../models/device_model.dart';
import '../services/database_service.dart';
import '../services/energy_service.dart';
import '../models/energy_usage_model.dart';

class EnergyMonitoringScreen extends StatefulWidget {
  const EnergyMonitoringScreen({Key? key}) : super(key: key);

  @override
  State<EnergyMonitoringScreen> createState() => _EnergyMonitoringScreenState();
}

class _EnergyMonitoringScreenState extends State<EnergyMonitoringScreen> {
  String _selectedTimeRange = '24h';
  Timer? _timer;
  final List<double> _costDataPoints = [];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Monitoring'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '1h', child: Text('Last Hour')),
              const PopupMenuItem(value: '24h', child: Text('Last 24 Hours')),
              const PopupMenuItem(value: '7d', child: Text('Last 7 Days')),
              const PopupMenuItem(value: '30d', child: Text('Last 30 Days')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_selectedTimeRange),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, child) {
          if (deviceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final relays =
              deviceProvider.devices.where((d) => d.type == 'relay').toList();

          return FutureBuilder<EnergyService>(
            future: EnergyService.create(devices: deviceProvider.devices),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final energyService = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Energy Summary Cards
                    _buildEnergySummaryCards(energyService),

                    const SizedBox(height: 24),

                    // Energy Consumption Chart
                    _buildEnergyHistoryChart(),

                    const SizedBox(height: 24),

                    // Device-wise Energy Usage
                    _buildDeviceEnergyList(relays, energyService),

                    const SizedBox(height: 24),

                    // Log Data Button
                    ElevatedButton(
                      onPressed: () async {
                        final energyService = await EnergyService.create(
                            devices: deviceProvider.devices);
                        final consumption =
                            energyService.deviceEnergyConsumption;
                        final dbService = DatabaseService();
                        consumption.forEach((deviceId, energy) {
                          dbService.saveEnergyHistory(EnergyRecord.dailySummary(
                            deviceId: deviceId,
                            date: DateTime.now(),
                            totalEnergyKwh: energy,
                          ));
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Energy data logged!')),
                        );
                      },
                      child: const Text('Log Today\'s Energy Data'),
                    ),

                    const SizedBox(height: 24),

                    // Energy Saving Tips
                    _buildEnergyTips(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEnergySummaryCards(EnergyService energyService) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref('devices/esp32_device_01/energy')
          .onValue,
      builder: (context, snapshot) {
        double totalKwh = 0;
        double estimatedCost = 0;
        double costPerKwh = 8;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final energyData =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          totalKwh = (energyData['total_kWh'] ?? 0).toDouble();
          estimatedCost = (energyData['estimatedCost'] ?? 0).toDouble();
          costPerKwh = (energyData['cost_per_kWh'] ?? 8).toDouble();
        }

        return Row(
          children: [
            _buildSummaryCard(
              'Total Energy',
              '${totalKwh.toStringAsFixed(4)} kWh',
              Icons.electric_bolt,
              Colors.orange,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Estimated Cost',
              '₹${estimatedCost.toStringAsFixed(3)}',
              Icons.money,
              Colors.green,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Rate',
              '₹${costPerKwh.toStringAsFixed(1)}/kWh',
              Icons.trending_down,
              Colors.blue,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyHistoryChart() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref('devices/esp32_device_01/energy')
          .onValue,
      builder: (context, snapshot) {
        List<FlSpot> costSpots = [];

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final energyData =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          // Add data point every time we receive an update
          final estimatedCost = (energyData['estimatedCost'] ?? 0).toDouble();
          _costDataPoints.add(estimatedCost);

          // Keep only last 50 data points for display
          if (_costDataPoints.length > 50) {
            _costDataPoints.removeAt(0);
          }

          // Create FlSpot points for the line chart
          for (int i = 0; i < _costDataPoints.length; i++) {
            costSpots.add(FlSpot(i.toDouble(), _costDataPoints[i]));
          }
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-time Cost Monitoring',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: costSpots.isEmpty
                      ? const Center(child: Text('Waiting for data...'))
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '₹${value.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                ),
                              ),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: costSpots,
                                isCurved: true,
                                color: Colors.green,
                                barWidth: 3,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.green.withOpacity(0.2),
                                ),
                              ),
                            ],
                            minX: 0,
                            maxX: costSpots.isNotEmpty
                                ? (costSpots.length - 1).toDouble()
                                : 10,
                            minY: 0,
                            maxY: _costDataPoints.isEmpty
                                ? 1
                                : _costDataPoints
                                        .reduce((a, b) => a > b ? a : b) *
                                    1.2,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estimated Cost in ₹ (Real-time Updates)',
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
        );
      },
    );
  }

  Widget _buildDeviceEnergyList(
      List<Device> relays, EnergyService energyService) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref('devices/esp32_device_01/energy')
          .onValue,
      builder: (context, snapshot) {
        Map<String, double> relayEnergy = {
          'relay1_Wh': 0,
          'relay2_Wh': 0,
          'relay3_Wh': 0,
          'relay4_Wh': 0,
        };

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final energyData =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          relayEnergy = {
            'relay1_Wh': (energyData['relay1_Wh'] ?? 0).toDouble(),
            'relay2_Wh': (energyData['relay2_Wh'] ?? 0).toDouble(),
            'relay3_Wh': (energyData['relay3_Wh'] ?? 0).toDouble(),
            'relay4_Wh': (energyData['relay4_Wh'] ?? 0).toDouble(),
          };
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Energy Usage (Real-time)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildRelayEnergyItem('Relay 1',
                    '${relayEnergy['relay1_Wh']?.toStringAsFixed(4) ?? '0'} Wh'),
                _buildRelayEnergyItem('Relay 2',
                    '${relayEnergy['relay2_Wh']?.toStringAsFixed(4) ?? '0'} Wh'),
                _buildRelayEnergyItem('Relay 3',
                    '${relayEnergy['relay3_Wh']?.toStringAsFixed(4) ?? '0'} Wh'),
                _buildRelayEnergyItem('Relay 4',
                    '${relayEnergy['relay4_Wh']?.toStringAsFixed(4) ?? '0'} Wh'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRelayEnergyItem(String deviceName, String consumption) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  consumption,
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
        ],
      ),
    );
  }

  Widget _buildEnergyTips() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Energy Saving Tips',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              'Turn off lights when not in use',
              'Save up to 10% on your electricity bill',
            ),
            _buildTipItem(
              'Set thermostat to 78°F (26°C)',
              'Optimal temperature for energy efficiency',
            ),
            _buildTipItem(
              'Use energy-efficient appliances',
              'Replace old devices with ENERGY STAR rated ones',
            ),
            _buildTipItem(
              'Schedule device automation',
              'Automatically turn off devices when not needed',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
        ],
      ),
    );
  }
}

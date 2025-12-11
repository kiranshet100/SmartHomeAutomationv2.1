import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as custom_auth;
import '../providers/device_provider.dart';
import '../services/voice_service.dart';
import '../services/voice_command_handler.dart';
import '../services/realtime_service.dart';
import '../services/notification_service.dart'; // Added import
import 'home/home_screen.dart';
import 'energy_monitoring_screen.dart';
import 'devices_list_screen.dart';
import 'settings_screen.dart';
import 'automation_screen.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({Key? key}) : super(key: key);

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {

  int _selectedIndex = 0;



  static final List<Widget> _screens = [

    const HomeScreen(),

    const EnergyMonitoringScreen(),

    const DevicesListScreen(),

    const AutomationScreen(),

    const SettingsScreen(),

  ];



  void _onItemTapped(int index) {

    setState(() {

      _selectedIndex = index;

    });

  }



  @override

  void initState() {

    super.initState();

    _initializeServices();

  }



  Future<void> _initializeServices() async {

    // Initialize voice command handler with providers

    WidgetsBinding.instance.addPostFrameCallback((_) {

      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

      final authProvider = Provider.of<custom_auth.AuthProvider>(context, listen: false);



      VoiceCommandHandler.initialize(context, deviceProvider, authProvider);

      RealtimeService.initialize();

      NotificationService().initialize(deviceProvider); // Initialized with DeviceProvider



      // Load initial data

      _loadInitialData();

    });

  }



  Future<void> _loadInitialData() async {

    final authProvider = Provider.of<custom_auth.AuthProvider>(context, listen: false);

    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);



    final token = authProvider.user?.uid;

    if (token != null) {

      await deviceProvider.fetchDevices(token);

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      body: _screens[_selectedIndex],

      bottomNavigationBar: Container(

        decoration: BoxDecoration(

          boxShadow: [

            BoxShadow(

              color: Colors.black.withOpacity(0.1),

              blurRadius: 10,

              offset: const Offset(0, -2),

            ),

          ],

        ),

        child: BottomNavigationBar(

          items: const <BottomNavigationBarItem>[

            BottomNavigationBarItem(

              icon: Icon(Icons.home),

              label: 'Home',

            ),

            BottomNavigationBarItem(

              icon: Icon(Icons.electric_bolt),

              label: 'Energy',

            ),

            BottomNavigationBarItem(

              icon: Icon(Icons.devices),

              label: 'Devices',

            ),

            BottomNavigationBarItem(

              icon: Icon(Icons.blur_on),

              label: 'Automation',

            ),

            BottomNavigationBarItem(

              icon: Icon(Icons.settings),

              label: 'Settings',

            ),

          ],

          currentIndex: _selectedIndex,

          selectedItemColor: Theme.of(context).primaryColor,

          unselectedItemColor: Colors.grey,

          backgroundColor: Theme.of(context).scaffoldBackgroundColor,

          type: BottomNavigationBarType.fixed,

          elevation: 8,

          onTap: _onItemTapped,

        ),

      ),

      floatingActionButton: StreamBuilder<String>(

        stream: VoiceService.statusStream,

        builder: (context, snapshot) {

          final isListening = VoiceService.isListening;

          return FloatingActionButton(

            heroTag: 'navigation_fab',

            onPressed: () {

              if (isListening) {

                VoiceService.stopListening();

              } else {

                VoiceService.startListening();

              }

            },

            backgroundColor: isListening ? Colors.red : Theme.of(context).primaryColor,

            child: Icon(

              isListening ? Icons.mic_off : Icons.mic,

              color: Colors.white,

            ),

          );

        },

      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

    );

  }

}

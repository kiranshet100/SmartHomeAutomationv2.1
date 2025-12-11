# Hardware Setup Guide

## Required Components

### Core Components
- **ESP32 Development Board** (1x) - Main microcontroller
- **DHT22 Temperature & Humidity Sensor** (1x) - Environmental monitoring
- **PIR Motion Sensor** (1x) - Security detection
- **LDR Light Sensor** (1x) - Light level detection
- **MQ2 Gas/Smoke Sensor** (1x) - Safety monitoring
- **Water Level Sensor** (1x) - Tank monitoring
- **4-Channel Relay Module** (1x) - Appliance control
- **DC Water Pump** (1x) - Automatic water pumping
- **Power Supply** (5V/3.3V) - Device power
- **Breadboard** (1x) - Prototyping
- **Jumper Wires** (assorted) - Connections

### Additional Components
- **LEDs** (3x) - Status indicators
- **Resistors** (10kΩ, 1kΩ) - Pull-up/down resistors
- **Capacitors** (10µF) - Noise filtering

## Wiring Diagrams

### ESP32 Pin Assignments
```
ESP32 GPIO Pins:
- GPIO 4: DHT22 Data
- GPIO 5: PIR Signal
- GPIO 6: LDR Analog
- GPIO 7: MQ2 Analog
- GPIO 8: Water Level Analog
- GPIO 9: Relay 1 (Light)
- GPIO 10: Relay 2 (Fan)
- GPIO 11: Relay 3 (Appliance)
- GPIO 12: Relay 4 (Pump)
- GPIO 13: Status LED
- GPIO 14: WiFi LED
```

### Sensor Connections

#### DHT22 Temperature/Humidity Sensor
```
ESP32 GPIO 4 ------> DHT22 DATA
ESP32 3.3V --------> DHT22 VCC
ESP32 GND ---------> DHT22 GND
10kΩ Resistor: DHT22 DATA to 3.3V (pull-up)
```

#### PIR Motion Sensor
```
ESP32 GPIO 5 ------> PIR SIGNAL
ESP32 5V ----------> PIR VCC
ESP32 GND ---------> PIR GND
```

#### LDR Light Sensor
```
ESP32 GPIO 6 ------> LDR (with voltage divider)
ESP32 3.3V --------> 10kΩ Resistor ------> LDR ------> GND
ESP32 GPIO 6 connected to junction of resistor and LDR
```

#### MQ2 Gas Sensor
```
ESP32 GPIO 7 ------> MQ2 AO (Analog Output)
ESP32 5V ----------> MQ2 VCC
ESP32 GND ---------> MQ2 GND
```

#### Water Level Sensor
```
ESP32 GPIO 8 ------> Water Sensor SIGNAL
ESP32 5V ----------> Water Sensor VCC
ESP32 GND ---------> Water Sensor GND
```

### Relay Module Connections
```
ESP32 GPIO 9 ------> Relay IN1
ESP32 GPIO 10 -----> Relay IN2
ESP32 GPIO 11 -----> Relay IN3
ESP32 GPIO 12 -----> Relay IN4
ESP32 5V ----------> Relay VCC
ESP32 GND ---------> Relay GND

Relay Outputs:
- Relay 1 NO/COM: Light circuit
- Relay 2 NO/COM: Fan circuit
- Relay 3 NO/COM: Appliance circuit
- Relay 4 NO/COM: Pump circuit
```

### Status LEDs
```
ESP32 GPIO 13 -----> LED1 (System Status) -----> 220Ω -----> GND
ESP32 GPIO 14 -----> LED2 (WiFi Status) -----> 220Ω -----> GND
ESP32 GPIO 15 -----> LED3 (Alert Status) -----> 220Ω -----> GND
```

## Power Supply Setup

### Main Power Supply
- Use 5V/2A power adapter for ESP32 and sensors
- Separate 12V/1A supply for relay module
- Ensure common ground between all components

### Battery Backup (Optional)
- 18650 Li-ion battery with TP4056 charger module
- Boost converter for 5V output
- Automatic switching circuit for power failure

## Assembly Instructions

1. **Mount ESP32 on Breadboard**
   - Place ESP32 in the center of the breadboard
   - Ensure proper alignment of pins

2. **Connect Sensors**
   - Wire each sensor according to the diagrams above
   - Use appropriate pull-up resistors for digital sensors

3. **Connect Relay Module**
   - Connect control pins to ESP32 GPIOs
   - Connect relay outputs to appliance circuits
   - **WARNING**: High voltage connections require proper insulation

4. **Power Connections**
   - Connect 5V to ESP32 VIN
   - Connect 3.3V to sensors requiring 3.3V
   - Ensure all grounds are connected

5. **Testing**
   - Power on the system
   - Check LED indicators
   - Verify sensor readings via serial monitor

## Safety Precautions

- **Electrical Safety**: Work with low voltage circuits only
- **Insulation**: Use proper insulation for high voltage relay connections
- **Heat Dissipation**: Ensure adequate ventilation for ESP32
- **Water Protection**: Keep electronics away from water sources
- **Fuse Protection**: Add fuses to power lines for protection

## Troubleshooting

- **ESP32 Not Booting**: Check power supply voltage
- **Sensor Not Reading**: Verify wiring and pin assignments
- **Relay Not Switching**: Check relay module power and control signals
- **WiFi Connection Issues**: Verify credentials and network compatibility
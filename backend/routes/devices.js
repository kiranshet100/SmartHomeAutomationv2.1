const express = require('express');
const mqtt = require('mqtt');
const Device = require('../models/Device');
const { authenticateToken } = require('./auth');

const router = express.Router();

// MQTT client for publishing control commands
const mqttClient = mqtt.connect(process.env.MQTT_BROKER || 'mqtt://localhost:1883');

// Get all devices for user
router.get('/', authenticateToken, async (req, res) => {
  try {
    const devices = await Device.find({ owner: req.user.userId });
    res.json({ devices });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get device by ID
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const device = await Device.findOne({
      _id: req.params.id,
      owner: req.user.userId
    });

    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    res.json({ device });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Add new device
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { deviceId, name, type, location, configuration } = req.body;

    // Check if device already exists
    const existingDevice = await Device.findOne({ deviceId });
    if (existingDevice) {
      return res.status(400).json({ message: 'Device already exists' });
    }

    const device = new Device({
      deviceId,
      name,
      type,
      location,
      configuration,
      owner: req.user.userId
    });

    await device.save();
    res.status(201).json({ message: 'Device added successfully', device });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Update device
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const device = await Device.findOneAndUpdate(
      { _id: req.params.id, owner: req.user.userId },
      req.body,
      { new: true }
    );

    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    res.json({ message: 'Device updated successfully', device });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Delete device
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const device = await Device.findOneAndDelete({
      _id: req.params.id,
      owner: req.user.userId
    });

    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    res.json({ message: 'Device deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Control device relays
router.post('/:id/control', authenticateToken, async (req, res) => {
  try {
    const { relay1, relay2, relay3, relay4 } = req.body;

    const device = await Device.findOne({
      _id: req.params.id,
      owner: req.user.userId
    });

    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    // Publish control command to MQTT
    const controlCommand = {
      device_id: device.deviceId,
      relay1: relay1 !== undefined ? relay1 : device.configuration.relays[0]?.state || false,
      relay2: relay2 !== undefined ? relay2 : device.configuration.relays[1]?.state || false,
      relay3: relay3 !== undefined ? relay3 : device.configuration.relays[2]?.state || false,
      relay4: relay4 !== undefined ? relay4 : device.configuration.relays[3]?.state || false
    };

    mqttClient.publish('home/control', JSON.stringify(controlCommand));

    // Update device configuration
    if (device.configuration.relays) {
      if (relay1 !== undefined) device.configuration.relays[0].state = relay1;
      if (relay2 !== undefined) device.configuration.relays[1].state = relay2;
      if (relay3 !== undefined) device.configuration.relays[2].state = relay3;
      if (relay4 !== undefined) device.configuration.relays[3].state = relay4;
    }

    await device.save();

    res.json({ message: 'Control command sent successfully', controlCommand });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get device status
router.get('/:id/status', authenticateToken, async (req, res) => {
  try {
    const device = await Device.findOne({
      _id: req.params.id,
      owner: req.user.userId
    });

    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    // Check if device is online (last seen within 30 seconds)
    const isOnline = (new Date() - device.lastSeen) < 30000;

    res.json({
      deviceId: device.deviceId,
      status: isOnline ? 'online' : 'offline',
      lastSeen: device.lastSeen,
      relays: device.configuration.relays
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;
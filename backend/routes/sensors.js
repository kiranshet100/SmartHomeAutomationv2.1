const express = require('express');
const SensorData = require('../models/SensorData');
const Device = require('../models/Device');
const { authenticateToken } = require('./auth');

const router = express.Router();

// Get latest sensor data for all user's devices
router.get('/latest', authenticateToken, async (req, res) => {
  try {
    // Get user's devices
    const devices = await Device.find({ owner: req.user.userId });
    const deviceIds = devices.map(device => device.deviceId);

    // Get latest data for each device
    const latestData = await SensorData.aggregate([
      { $match: { device_id: { $in: deviceIds } } },
      { $sort: { timestamp: -1 } },
      {
        $group: {
          _id: '$device_id',
          temperature: { $first: '$temperature' },
          humidity: { $first: '$humidity' },
          motion: { $first: '$motion' },
          light_level: { $first: '$light_level' },
          gas_level: { $first: '$gas_level' },
          water_level: { $first: '$water_level' },
          relay1: { $first: '$relay1' },
          relay2: { $first: '$relay2' },
          relay3: { $first: '$relay3' },
          relay4: { $first: '$relay4' },
          timestamp: { $first: '$timestamp' }
        }
      }
    ]);

    res.json({ sensorData: latestData });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get sensor data for specific device
router.get('/device/:deviceId', authenticateToken, async (req, res) => {
  try {
    // Check if user owns the device
    const device = await Device.findOne({
      deviceId: req.params.deviceId,
      owner: req.user.userId
    });

    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    const { limit = 50, startDate, endDate } = req.query;

    let query = { device_id: req.params.deviceId };

    // Add date range filter if provided
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const sensorData = await SensorData.find(query)
      .sort({ timestamp: -1 })
      .limit(parseInt(limit));

    res.json({ sensorData });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get sensor data with time range
router.get('/history', authenticateToken, async (req, res) => {
  try {
    const { deviceId, hours = 24, sensor } = req.query;

    // Check if user owns the device
    const device = await Device.findOne({
      deviceId,
      owner: req.user.userId
    });

    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    const startTime = new Date(Date.now() - (parseInt(hours) * 60 * 60 * 1000));

    let query = {
      device_id: deviceId,
      timestamp: { $gte: startTime }
    };

    // Filter by specific sensor if provided
    if (sensor) {
      query = { ...query, [sensor]: { $exists: true } };
    }

    const sensorData = await SensorData.find(query)
      .sort({ timestamp: 1 }); // Ascending for time series

    res.json({ sensorData });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get sensor statistics
router.get('/stats/:deviceId', authenticateToken, async (req, res) => {
  try {
    // Check if user owns the device
    const device = await Device.findOne({
      deviceId: req.params.deviceId,
      owner: req.user.userId
    });

    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    const { hours = 24 } = req.query;
    const startTime = new Date(Date.now() - (parseInt(hours) * 60 * 60 * 1000));

    const stats = await SensorData.aggregate([
      {
        $match: {
          device_id: req.params.deviceId,
          timestamp: { $gte: startTime }
        }
      },
      {
        $group: {
          _id: null,
          avgTemperature: { $avg: '$temperature' },
          maxTemperature: { $max: '$temperature' },
          minTemperature: { $min: '$temperature' },
          avgHumidity: { $avg: '$humidity' },
          maxHumidity: { $max: '$humidity' },
          minHumidity: { $min: '$humidity' },
          motionCount: { $sum: { $cond: ['$motion', 1, 0] } },
          avgLightLevel: { $avg: '$light_level' },
          maxGasLevel: { $max: '$gas_level' },
          avgWaterLevel: { $avg: '$water_level' },
          minWaterLevel: { $min: '$water_level' },
          dataPoints: { $sum: 1 }
        }
      }
    ]);

    res.json({ stats: stats[0] || {} });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Delete old sensor data (cleanup)
router.delete('/cleanup', authenticateToken, async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const cutoffDate = new Date(Date.now() - (parseInt(days) * 24 * 60 * 60 * 1000));

    // Only allow owner role to perform cleanup
    if (req.user.role !== 'owner') {
      return res.status(403).json({ message: 'Access denied. Owner role required.' });
    }

    const result = await SensorData.deleteMany({
      timestamp: { $lt: cutoffDate }
    });

    res.json({
      message: `Deleted ${result.deletedCount} old sensor data records`
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;
const mongoose = require('mongoose');

const sensorDataSchema = new mongoose.Schema({
  device_id: {
    type: String,
    required: true
  },
  temperature: {
    type: Number,
    required: true
  },
  humidity: {
    type: Number,
    required: true
  },
  motion: {
    type: Number,
    required: true
  },
  light_level: {
    type: Number,
    required: true
  },
  gas_level: {
    type: Number,
    required: true
  },
  water_level: {
    type: Number,
    required: true
  },
  relay1: {
    type: Boolean,
    default: false
  },
  relay2: {
    type: Boolean,
    default: false
  },
  relay3: {
    type: Boolean,
    default: false
  },
  relay4: {
    type: Boolean,
    default: false
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
});

// Index for efficient queries
sensorDataSchema.index({ device_id: 1, timestamp: -1 });

module.exports = mongoose.model('SensorData', sensorDataSchema);
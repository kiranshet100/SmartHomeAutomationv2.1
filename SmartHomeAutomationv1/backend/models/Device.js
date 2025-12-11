const mongoose = require('mongoose');

const deviceSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['esp32', 'sensor', 'relay'],
    required: true
  },
  location: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['online', 'offline'],
    default: 'offline'
  },
  lastSeen: {
    type: Date,
    default: Date.now
  },
  configuration: {
    sensors: [{
      type: {
        type: String,
        enum: ['dht22', 'pir', 'ldr', 'mq2', 'water_level']
      },
      pin: Number,
      enabled: {
        type: Boolean,
        default: true
      }
    }],
    relays: [{
      name: String,
      pin: Number,
      state: {
        type: Boolean,
        default: false
      }
    }]
  },
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Update lastSeen when device sends data
deviceSchema.methods.updateLastSeen = function() {
  this.lastSeen = new Date();
  return this.save();
};

module.exports = mongoose.model('Device', deviceSchema);
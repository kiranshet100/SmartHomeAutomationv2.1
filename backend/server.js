const express = require('express');
const mongoose = require('mongoose');
const mqtt = require('mqtt');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/smart_home', {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('MongoDB connected'))
.catch(err => console.log(err));

// MQTT client
const mqttClient = mqtt.connect(process.env.MQTT_BROKER || 'mqtt://localhost:1883');

// MQTT event handlers
mqttClient.on('connect', () => {
  console.log('Connected to MQTT broker');
  mqttClient.subscribe('home/sensors');
  mqttClient.subscribe('home/alert');
});

mqttClient.on('message', (topic, message) => {
  const data = JSON.parse(message.toString());
  console.log(`MQTT message received on ${topic}:`, data);

  // Handle sensor data
  if (topic === 'home/sensors') {
    handleSensorData(data);
  }

  // Handle alerts
  if (topic === 'home/alert') {
    handleAlert(data);
  }

  // Emit to connected clients
  io.emit('sensorData', data);
});

// Routes
app.use('/api/auth', require('./routes/auth').router);
app.use('/api/devices', require('./routes/devices'));
app.use('/api/sensors', require('./routes/sensors'));

// Socket.io connection
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send('Something broke!');
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Helper functions
async function handleSensorData(data) {
  try {
    const SensorData = require('./models/SensorData');
    const sensorData = new SensorData(data);
    await sensorData.save();
    console.log('Sensor data saved to database');
  } catch (error) {
    console.error('Error saving sensor data:', error);
  }
}

async function handleAlert(data) {
  try {
    // Send push notification logic here
    console.log('Alert received:', data);
    io.emit('alert', data);
  } catch (error) {
    console.error('Error handling alert:', error);
  }
}

module.exports = app;
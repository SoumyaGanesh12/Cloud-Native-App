// server.js

import express from 'express';
import dotenv from 'dotenv';
import { initModels } from './models/index.js';
import healthRoutes from './routes/healthRoutes.js';
import fileRoutes from './routes/fileRoutes.js';

dotenv.config();

// Create an Express application
const app = express();
const PORT = process.env.PORT;

// Middleware to parse JSON
app.use(express.json());

// Define routes
app.use('/', healthRoutes);
app.use('/', fileRoutes);

// Start the server
export const startServer = async () => {
  try {
    // Initialize models and database
    await initModels();

    // Start the Express server
    app.listen(PORT, () => {
      console.log(`Server is running at http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
  }
};

export default app;

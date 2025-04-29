import dotenv from 'dotenv';
import { startServer } from './server.js';

// Load environment variables from .env file
dotenv.config();

// Start the application
startServer();
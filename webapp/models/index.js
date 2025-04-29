import sequelize from '../utils/sequelize.js';
import HealthCheck from '../models/healthModel.js';
import File from '../models/fileModel.js';

// Initialize and synchronize the models
const initModels = async () => {
  try {
    // Authenticate the database connection
    await sequelize.authenticate();

    // Synchronize the models/tables
    await sequelize.sync({});

    console.log('Database connected and tables are synchronized.');
  } catch (error) {
    console.error('Failed to initialize database:', error);
    throw error;
  }
};

// Export the Sequelize instance and HealthCheck model
export { sequelize, HealthCheck, File, initModels };

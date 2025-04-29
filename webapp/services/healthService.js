import logger from '../lib/logger.js';
import statsdClient from '../lib/statsdClient.js';
import HealthCheck from '../models/healthModel.js';
import sequelize from '../utils/sequelize.js';

// Create a new health check entry
export const createHealthCheck = async () => {
  const startTime = Date.now();
  try {
    const healthCheck = await HealthCheck.create({});
    logger.info('Successfully created health check record');
    return healthCheck;
  } catch (error) {
    logger.error('Error creating health check record', { error: error.message, stack: error.stack });
    throw new Error('Failed to create health check record');
  } finally {
    // Time how long the DB create call took
    const durationMs = Date.now() - startTime;
    statsdClient.timing('db.healthCheck.create.duration', durationMs);
    logger.info(`createHealthCheck completed in ${durationMs}ms`);
  }
};

// Check database connection health
export const checkDatabaseConnection = async () => {
  const startTime = Date.now();
  try {
    await sequelize.authenticate();
    logger.info('Database connection authenticated successfully');
    return true;
  } catch (error) {
    logger.error('Database connection failed', { error: error.message, stack: error.stack });
    return false;
  } finally {
    // Time how long it took to authenticate
    const durationMs = Date.now() - startTime;
    statsdClient.timing('db.healthCheck.authenticate.duration', durationMs);
    logger.info(`checkDatabaseConnection completed in ${durationMs}ms`);
  }
};

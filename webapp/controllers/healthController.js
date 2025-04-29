import logger from '../lib/logger.js';
import statsdClient from '../lib/statsdClient.js';
import * as healthService from '../services/healthService.js';

// Handle the /healthz GET request
export const handleHealthCheck = async (req, res) => {
  // Start a timer for the total request duration
  const startTime = Date.now();

  // Increment a counter for this endpoint
  statsdClient.increment('api.healthz.count');
  logger.info('Received GET /healthz request');

  try {
    // Check if the request has any payload (including empty JSON `{}`)
    const contentLength = req.headers['content-length'] 
      ? parseInt(req.headers['content-length'], 10) 
      : 0;
    
    if (contentLength > 0) {
      logger.error('Bad Request - Request body is not allowed for /healthz');
      return res
        .set('Cache-Control', 'no-cache, no-store, must-revalidate')
        .set('Pragma', 'no-cache')
        .set('X-Content-Type-Options', 'nosniff')
        .status(400)
        .send();
    }

    // Reject requests with query parameters
    if (Object.keys(req.query).length > 0) {
      logger.error('Bad Request - Query parameters are not allowed for /healthz');
      return res
        .set('Cache-Control', 'no-cache, no-store, must-revalidate')
        .set('Pragma', 'no-cache')
        .set('X-Content-Type-Options', 'nosniff')
        .status(400)
        .send();
    }

    // Perform database health check
    const isDbCnctGood = await healthService.checkDatabaseConnection();
    if (!isDbCnctGood) {
      logger.error('Service Unavailable - Database connection failed');
      return res
        .set('Cache-Control', 'no-cache, no-store, must-revalidate')
        .set('Pragma', 'no-cache')
        .set('X-Content-Type-Options', 'nosniff')
        .status(503)
        .send();
    }

    // Create a health check record
    await healthService.createHealthCheck();

    // Return success if everything works
    logger.info('GET /healthz - Responding with 200 OK');
    res
      .set('Cache-Control', 'no-cache, no-store, must-revalidate')
      .set('Pragma', 'no-cache')
      .set('X-Content-Type-Options', 'nosniff')
      .status(200)
      .send();

  } catch (error) {
    logger.error('Health check failed', { error: error.message, stack: error.stack });
    res
      .set('Cache-Control', 'no-cache, no-store, must-revalidate')
      .set('Pragma', 'no-cache')
      .set('X-Content-Type-Options', 'nosniff')
      .status(503)
      .send();
  } finally {
    // Always measure total API call duration
    const totalDuration = Date.now() - startTime;
    statsdClient.timing('api.healthz.duration', totalDuration);
    logger.info(`GET /healthz completed in ${totalDuration}ms`);
  }
};

// Handle unsupported HTTP methods
export const handleUnsupportedMethods = (req, res) => {
  logger.error(`Method ${req.method} not allowed on /healthz`);
  statsdClient.increment('api.healthz.unsupportedMethod.count');

  res
    .set('Cache-Control', 'no-cache, no-store, must-revalidate')
    .set('Pragma', 'no-cache')
    .set('X-Content-Type-Options', 'nosniff')
    .status(405)
    .send();
};

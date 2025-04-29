import logger from '../lib/logger.js';            // Winston logger
import statsdClient from '../lib/statsdClient.js';// StatsD client
import { createFile, getFile, removeFile } from '../services/fileService.js';

// Upload a file and store metadata in the database
export const uploadFile = async (req, res) => {
  // Start timing this API call
  const startTime = Date.now();
  // Increment counter for the upload API
  statsdClient.increment('api.file.upload.count');
  logger.debug('POST /file - uploadFile request received');

  try {
    // Ensure no query parameters
    if (Object.keys(req.query).length > 0) {
      logger.warn('Bad Request - query parameters not allowed for uploadFile');
      return res.status(400).send();
    }

    // Ensure the request contains a file
    if (!req.file) {
      logger.warn('Bad Request - no file provided in uploadFile');
      return res.status(400).send();
    }

    // Validate file type (allow only images)
    // if (!req.file.mimetype.startsWith('image/')) {
    //   return res.status(400).json({ message: 'Only image files are allowed.' });
    // }

    const fileRecord = await createFile(req.file);

    // If file creation fails, return a 422 error - Unprocessable entity
    if (!fileRecord) {
      logger.error('File creation returned falsy object');
      return res.status(422).send();
    }

    logger.info(`File uploaded successfully with ID=${fileRecord.id}`);

    return res.status(201).json({
      file_name: fileRecord.file_name,
      id: fileRecord.id,
      url: fileRecord.url,
      upload_date: fileRecord.upload_date,
    });
  } catch (error) {
    logger.error('Error uploading file', {
      error: error.message,
      stack: error.stack
    });

    // Return 503 if the service layer indicated a DB connectivity or similar failure
    if (error.status === 503) {
      return res.status(503).send();
    }

    // Otherwise return a 400 Bad Request
    return res.status(400).send();
  } finally {
    // Measure total request duration
    const durationMs = Date.now() - startTime;
    statsdClient.timing('api.file.upload.duration', durationMs);
    logger.info(`POST /file uploadFile completed in ${durationMs}ms`);
  }
};

// Retrieve file metadata by ID
export const getFileById = async (req, res) => {
  const startTime = Date.now();
  statsdClient.increment('api.file.get.count');
  logger.debug('GET /file/:id - getFileById request received');

  try {
    // console.log(req.params);
    // console.log(Object.keys(req.params)[0]);
    // Ensure only the expected 'id' parameter is present
    if (!req.params.id || Object.keys(req.params).length !== 1) {
      logger.warn('Bad Request - invalid or missing "id" param in getFileById');
      return res.status(400).send();
    }

    // Ensure no query parameters
    if (Object.keys(req.query).length > 0) {
      logger.warn('Bad Request - query params not allowed in getFileById');
      return res.status(400).send();
    }

    // Block request body
    const contentLength = req.get('content-length') 
      ? parseInt(req.get('content-length'), 10)
      : 0;
    if (contentLength > 0) {
      logger.warn('Bad Request - request body not allowed in getFileById');
      return res.status(400).send();
    }

    const fileRecord = await getFile(req.params.id);
    if (!fileRecord) {
      logger.warn(`File with ID=${req.params.id} not found`);
      return res.status(404).send();
    }

    logger.info(`File with ID=${fileRecord.id} retrieved successfully`);
    logger.debug(`File details: ${JSON.stringify(fileRecord)}`);

    return res.status(200).json({
      file_name: fileRecord.file_name,
      id: fileRecord.id,
      url: fileRecord.url,
      upload_date: fileRecord.upload_date,
    });
  } catch (error) {
    logger.error('Error fetching file', {
      error: error.message,
      stack: error.stack
    });

    // Return 503 if set in the service layer
    if (error.status === 503) {
      return res.status(503).send();
    }
    return res.status(400).send();
  } finally {
    const durationMs = Date.now() - startTime;
    statsdClient.timing('api.file.get.duration', durationMs);
    logger.info(`GET /file/:id getFileById completed in ${durationMs}ms`);
  }
};

// Delete a file by ID
export const deleteFileById = async (req, res) => {
  const startTime = Date.now();
  statsdClient.increment('api.file.delete.count');
  logger.debug('DELETE /file/:id - deleteFileById request received');

  try {
    // Ensure only the expected 'id' parameter is present
    if (!req.params.id || Object.keys(req.params).length !== 1) {
      logger.warn('Bad Request - invalid or missing "id" param in deleteFileById');
      return res.status(400).send();
    }

    // Ensure no query parameters
    if (Object.keys(req.query).length > 0) {
      logger.warn('Bad Request - query params not allowed in deleteFileById');
      return res.status(400).send();
    }

    // Block request body of any type (JSON, text, form-data, etc.)
    const contentLength = req.get('content-length') 
      ? parseInt(req.get('content-length'), 10)
      : 0;
    if (contentLength > 0) {
      logger.warn('Bad Request - request body not allowed in deleteFileById');
      return res.status(400).send();
    }

    const fileRecord = await removeFile(req.params.id);
    if (!fileRecord) {
      logger.warn(`File with ID=${req.params.id} not found for deletion`);
      return res.status(404).send();
    }

    logger.info(`File with ID=${fileRecord.id} deleted successfully`);

    // Successful deletion: return 204 No Content
    return res.status(204).send();
  } catch (error) {
    logger.error('Error deleting file', {
      error: error.message,
      stack: error.stack
    });

    if (error.status === 503) {
      return res.status(503).send();
    }
    return res.status(400).send();
  } finally {
    const durationMs = Date.now() - startTime;
    statsdClient.timing('api.file.delete.duration', durationMs);
    logger.info(`DELETE /file/:id deleteFileById completed in ${durationMs}ms`);
  }
};

// Handle unsupported HTTP methods
export const handleUnsupportedMethods = (req, res) => {
  logger.warn(`Method ${req.method} not allowed on /file`);
  statsdClient.increment('api.file.unsupportedMethod.count');

  res
    .set('Cache-Control', 'no-cache, no-store, must-revalidate')
    .set('Pragma', 'no-cache')
    .set('X-Content-Type-Options', 'nosniff')
    .status(405)
    .send();
};

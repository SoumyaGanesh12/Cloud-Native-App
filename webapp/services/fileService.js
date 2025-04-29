import File from '../models/fileModel.js';
import { uploadFile, deleteFile, headObject } from '../utils/s3.js';
import { v4 as uuidv4 } from 'uuid';
import logger from '../lib/logger.js';
import statsdClient from '../lib/statsdClient.js';

/**
 * Creates a new file record and uploads it to S3.
 * @param {Object} file - The file object (received from an upload request).
 * @returns {Promise<Object>} - The created file record.
 */
export const createFile = async (file) => {
  // Generate a unique ID for the file
  const fileId = uuidv4();
  const bucketName = process.env.S3_BUCKET;
  // Define the file path in S3
  const key = `${fileId}/${file.originalname}`;

  logger.debug(`Preparing to upload file ${file.originalname} to ${bucketName}/${key}`);
  
  let awsUploadDuration;
  let dbCreateDuration;
  let fileRecord;

  // Upload the file to S3
  let awsUploadStart;
  try {
    awsUploadStart = Date.now();
    await uploadFile(file.buffer, bucketName, key, file.mimetype);
  } catch (error) {
    logger.error('S3 upload failed', { error: error.message });
    throw error;
  } finally {
    awsUploadDuration = Date.now() - awsUploadStart;
    statsdClient.timing('aws.s3.uploadFile.duration', awsUploadDuration);
    logger.info(`S3 uploadFile completed in ${awsUploadDuration}ms`);
  }

  // Create a record in the database with file details
  let dbCreateStart;
  try {
    dbCreateStart = Date.now();
    fileRecord = await File.create({
      id: fileId,
      file_name: file.originalname,
      url: `${bucketName}/${key}`, // Store the S3 file path in the database
    });
  } catch (error) {
    // Check if it's a Sequelize connection error
    if (error.name && error.name.includes('SequelizeConnection')) {
      logger.warn('Sequelize connection issue encountered during file create');
      error.status = 503;
    } else {
      logger.error('Unexpected DB error during file create', { error: error.message });
    }
    throw error;
  } finally {
    dbCreateDuration = Date.now() - dbCreateStart;
    statsdClient.timing('db.file.create.duration', dbCreateDuration);
    logger.info(`DB File.create completed in ${dbCreateDuration}ms`);
  }

  return fileRecord;
};

/**
 * Retrieves a file record from the database by ID.
 * @param {string} id - The unique identifier of the file.
 * @returns {Promise<Object|null>} - The file record if found, otherwise null.
 */
export const getFile = async (id) => {
  let fileRecord;
  let dbFindDuration;
  let awsHeadDuration;
  let dbFindStart, awsHeadStart;

  logger.debug(`getFile() - Looking for file with ID: ${id}`);

  // Find file by primary key (ID)
  try {
    dbFindStart = Date.now();
    fileRecord = await File.findByPk(id);
  } catch (error) {
    // Check for DB connection errors
    logger.error(`DB error while finding file with ID=${id}`, {
      error: error.message,
      stack: error.stack
    });
    if (error.name && error.name.includes('SequelizeConnection')) {
      error.status = 503;
    }
    throw error;
  } finally {
    dbFindDuration = Date.now() - dbFindStart;
    statsdClient.timing('db.file.find.duration', dbFindDuration);
    logger.info(`DB File.findByPk completed in ${dbFindDuration}ms`);
  }

  if (!fileRecord){
    logger.warn(`File ID=${id} not found in DB`);
    return null; // If not in DB, return null
  }

  logger.debug(`File record retrieved: ${JSON.stringify(fileRecord)}`);

  // Extract bucket name and key from the stored URL
  const [bucketName, ...keyParts] = fileRecord.url.split('/');
  const key = keyParts.join('/');

  // Check if the file exists in S3
  let fileExists;
  try {
    awsHeadStart = Date.now();
    fileExists = await headObject(bucketName, key); // This function sends a HEAD request to check object existence
  } catch (error) {
    logger.error(`Error while performing S3 headObject for ID=${id}`, {
      error: error.message,
      stack: error.stack
    });
    throw error;
  } finally {
    awsHeadDuration = Date.now() - awsHeadStart;
    statsdClient.timing('aws.s3.headObject.duration', awsHeadDuration);
    logger.info(`S3 headObject completed in ${awsHeadDuration}ms`);
  }

  if (!fileExists){
    logger.warn(`S3 object not found for file ID=${id}`);
    return null;  // If the file doesn't exist in S3, return null
  }
  return fileRecord;
};

/**
 * Deletes a file from S3 and removes its record from the database.
 * @param {string} id - The unique identifier of the file.
 * @returns {Promise<Object|null>} - The deleted file record if found, otherwise null.
 */
export const removeFile = async (id) => {
  let fileRecord;
  let dbFindDuration, awsDeleteDuration, dbDeleteDuration;
  let dbFindStart, awsDeleteStart, dbDeleteStart;

  logger.debug(`removeFile() - Attempting to delete file with ID: ${id}`);

  // Find file by primary key (ID)
  try {
    dbFindStart = Date.now();
    fileRecord = await File.findByPk(id);
  } catch (error) {
    logger.error(`Error querying DB for file ID=${id}`, {
      error: error.message,
      stack: error.stack
    });
    throw error;
  } finally {
    dbFindDuration = Date.now() - dbFindStart;
    statsdClient.timing('db.file.find.duration', dbFindDuration);
    logger.info(`DB File.findByPk (for deletion) completed in ${dbFindDuration}ms`);
  }

  if (!fileRecord) {
    logger.warn(`File ID=${id} not found for deletion`);
    return null;
  }

  // Extract bucket name and key from the stored URL
  const [bucketName, ...keyParts] = fileRecord.url.split('/');
  const key = keyParts.join('/');

  logger.debug(`Parsed S3 location - bucket: ${bucketName}, key: ${key}`);

  // Delete file from S3
  try {
    awsDeleteStart = Date.now();
    await deleteFile(bucketName, key);
  } catch (error) {
    logger.error(`S3 deleteFile failed for key=${key}`, {
      error: error.message,
      stack: error.stack
    });
    throw error;
  } finally {
    awsDeleteDuration = Date.now() - awsDeleteStart;
    statsdClient.timing('aws.s3.deleteFile.duration', awsDeleteDuration);
    logger.info(`S3 deleteFile completed in ${awsDeleteDuration}ms`);
  }

  // Remove file record from the database
  try {
    dbDeleteStart = Date.now();
    await fileRecord.destroy();
  } catch (error) {
    logger.error(`Error deleting DB record for file ID=${id}`, {
      error: error.message,
      stack: error.stack
    });
    // Check for DB connection errors
    if (error.name && error.name.includes('SequelizeConnection')) {
      error.status = 503;
    }
    throw error;
  } finally {
    dbDeleteDuration = Date.now() - dbDeleteStart;
    statsdClient.timing('db.file.delete.duration', dbDeleteDuration);
    logger.info(`DB File.destroy completed in ${dbDeleteDuration}ms`);
  }

  logger.info(`File with ID=${id} deleted from DB and S3`);
  return fileRecord;
};

import { S3Client, PutObjectCommand, DeleteObjectCommand, HeadObjectCommand } from '@aws-sdk/client-s3';

// Initialize an S3 client in the specified region
const s3 = new S3Client({
  region: process.env.AWS_REGION,
});

/**
 * Uploads a file to an S3 bucket.
 * @param {Buffer} fileBuffer - The file data in buffer format.
 * @param {string} bucketName - The name of the S3 bucket.
 * @param {string} key - The S3 key (file path inside the bucket).
 * @param {string} mimetype - The MIME type of the file.
 */
export const uploadFile = async (fileBuffer, bucketName, key, mimetype) => {
  const params = {
    Bucket: bucketName,
    Key: key,
    Body: fileBuffer,
    ContentType: mimetype,
  };

  // Upload the file to S3 using the PutObjectCommand
  await s3.send(new PutObjectCommand(params));
};

/**
 * Deletes a file from an S3 bucket.
 * @param {string} bucketName - The name of the S3 bucket.
 * @param {string} key - The S3 key (file path inside the bucket).
 */
export const deleteFile = async (bucketName, key) => {
  const params = {
    Bucket: bucketName,
    Key: key,
  };

  // Delete the file from S3 using the DeleteObjectCommand
  await s3.send(new DeleteObjectCommand(params));
};

export const headObject = async (bucketName, key) => {
  try {
    await s3.send(new HeadObjectCommand({ Bucket: bucketName, Key: key }));
    return true; // File exists in S3
  } catch (error) {
    if (error.name === "NotFound") {
      return false; // File does not exist
    }
    throw error; // Other S3 errors
  }
};
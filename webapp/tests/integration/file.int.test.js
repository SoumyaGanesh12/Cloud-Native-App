import request from 'supertest';
import app from '../../server.js';
import { sequelize } from '../../models/index.js';
import File from '../../models/fileModel.js';
import { uploadFile, deleteFile, headObject } from '../../utils/s3.js';
import { v4 as uuidv4 } from 'uuid';

// Mock S3 functions, no actual calls made to aws s3
jest.mock('../../utils/s3.js');

// Mock implementations: 
uploadFile.mockImplementation(async () => {
    return {}; // Simulates a successful upload
});

deleteFile.mockImplementation(async () => {
    return {}; // Simulates a successful deletion
});

// Ensure headObject returns `true` when checking for file existence
headObject.mockImplementation(async () => true);

describe('/v1/file API Integration Tests', () => {

    // Before all tests, ensure DB is connected and models are synced
    beforeAll(async () => {
      await sequelize.authenticate();
      // Force sync for a clean slate
      await sequelize.sync({ force: true });
    });
  
    // After all tests, close DB connection
    afterAll(async () => {
      await sequelize.close();
    });
  
    describe('POST /v1/file', () => {
      test('should upload an image and return 201', async () => {
        const response = await request(app)
          .post('/v1/file')
          .attach('file', Buffer.from('fake image content'), 'test.jpg');
  
        expect(response.status).toBe(201);
        expect(response.body).toHaveProperty('id');
        expect(response.body).toHaveProperty('file_name', 'test.jpg');
        expect(response.body).toHaveProperty('url');
        expect(response.body).toHaveProperty('upload_date');
  
        // Verify DB record is created
        const dbRecord = await File.findByPk(response.body.id);
        expect(dbRecord).not.toBeNull();
        expect(dbRecord.file_name).toBe('test.jpg');
      });
  
      test('should return 400 if file is missing', async () => {
        const response = await request(app).post('/v1/file');
        expect(response.status).toBe(400);
      });
  
    //   test('should return 400 for non-image file', async () => {
    //     const response = await request(app)
    //       .post('/v1/file')
    //       .attach('file', Buffer.from('pdf content'), {
    //         filename: 'test.pdf',
    //         contentType: 'application/pdf',
    //       });
    //     expect(response.status).toBe(400);
    //     expect(response.body).toEqual({ message: 'Only image files are allowed.' });
    //   });
    });
  
    describe('GET /v1/file/:id', () => {
      let fileId;
  
      beforeEach(async () => {
        // Insert a record for testing
        const newFile = await File.create({
          id: uuidv4(),
          file_name: 'example.jpg',
          url: 'my-test-bucket/test-file-id/example.jpg',
        });
        fileId = newFile.id;
      });
  
      afterEach(async () => {
        // Clear table after each test
        await File.truncate({ cascade: true });
      });
  
      test('should return file metadata if file exists', async () => {
        const response = await request(app).get(`/v1/file/${fileId}`);
        expect(response.status).toBe(200);
        expect(response.body).toHaveProperty('id', fileId);
        expect(response.body).toHaveProperty('file_name', 'example.jpg');
      });
  
      test('should return 404 if file does not exist', async () => {
        const nonExistentUUID = uuidv4();  // Generate a valid UUID
        const response = await request(app).get(`/v1/file/${nonExistentUUID}`);
        expect(response.status).toBe(404);
      });
    });
  
    describe('DELETE /v1/file/:id', () => {
      let fileId;
  
      beforeEach(async () => {
        // Insert a record for testing
        const newFile = await File.create({
          id: uuidv4(),
          file_name: 'deleteTest.jpg',
          url: 'my-test-bucket/del-file-id/deleteTest.jpg',
        });
        fileId = newFile.id;
      });
  
      afterEach(async () => {
        await File.truncate({ cascade: true });
      });
  
      test('should delete file if it exists', async () => {
        const response = await request(app).delete(`/v1/file/${fileId}`);
        expect(response.status).toBe(204);
  
        // Verify record is removed from DB
        const dbRecord = await File.findByPk(fileId);
        expect(dbRecord).toBeNull();
      });
  
      test('should return 404 if file does not exist', async () => {
        const nonExistentUUID = uuidv4();  // Generate a valid UUID
        const response = await request(app).get(`/v1/file/${nonExistentUUID}`);
        expect(response.status).toBe(404);
      });
    });
});

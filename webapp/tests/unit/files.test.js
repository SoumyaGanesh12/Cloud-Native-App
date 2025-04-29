import request from 'supertest';
import { jest } from '@jest/globals';
import app from '../../server.js';
import * as fileService from '../../services/fileService.js';

jest.mock('../../services/fileService');

const mockFileRecord = {
    file_name: 'test-image.jpg',
    id: '1234-5678-9012',
    url: 'bucket/1234-5678-9012/test-image.jpg',
    upload_date: '2024-03-17',
};

describe('/v1/file API Unit Tests', () => {

    beforeAll(() => {
        jest.spyOn(console, 'log').mockImplementation(() => {});
        jest.spyOn(console, 'error').mockImplementation(() => {});
    });

    afterAll(() => {
        console.log.mockRestore(); // Restore original console.log
        console.error.mockRestore(); // Restore original console.error
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    // ----- POST Endpoint Tests -----

    test('POST /v1/file - should upload file and return 201', async () => {
        fileService.createFile.mockResolvedValue(mockFileRecord);

        const response = await request(app)
            .post('/v1/file')
            .attach('file', Buffer.from('image content'), 'test-image.jpg');

        expect(response.status).toBe(201);
        expect(response.body).toEqual(mockFileRecord);
    });

    test('POST /v1/file - should return 400 if query parameters are provided', async () => {
        const response = await request(app)
            .post('/v1/file?unexpected=param')
            .attach('file', Buffer.from('image content'), 'test-image.jpg');
        expect(response.status).toBe(400);
    });

    test('POST /v1/file - should return 400 if no file is provided', async () => {
        const response = await request(app).post('/v1/file');
        expect(response.status).toBe(400);
    });

    // test('POST /v1/file - should return 400 for non-image file', async () => {
    //     const response = await request(app)
    //         .post('/v1/file')
    //         .attach('file', Buffer.from('pdf content'), {
    //             filename: 'test.pdf',
    //             contentType: 'application/pdf',
    //         });

    //     expect(response.status).toBe(400);
    //     expect(response.body).toEqual({ message: 'Only image files are allowed.' });
    // });

    test('POST /v1/file - should return 503 if DB is unreachable', async () => {
        // Simulate Sequelize connection error
        const dbError = new Error('Database unreachable');
        dbError.name = 'SequelizeConnectionError';
        dbError.status = 503;

        // Mock the createFile call to reject with that error
        fileService.createFile.mockRejectedValue(dbError);

        const response = await request(app)
            .post('/v1/file')
            .attach('file', Buffer.from('fake content'), 'test.jpg');

        // Expect 503
        expect(response.status).toBe(503);
    });

    // ----- GET Endpoint Tests -----

    test('GET /v1/file/:id - should return 200 and file metadata', async () => {
        fileService.getFile.mockResolvedValue(mockFileRecord);

        const response = await request(app).get(`/v1/file/${mockFileRecord.id}`);

        expect(response.status).toBe(200);
        expect(response.body).toEqual(mockFileRecord);
    });

    test('GET /v1/file/:id - should return 404 if file not found', async () => {
        fileService.getFile.mockResolvedValue(null);

        const response = await request(app).get('/v1/file/nonexistent-id');

        expect(response.status).toBe(404);
    });

    test('GET /v1/file/:id - should return 400 if query parameters are provided', async () => {
        const response = await request(app).get(`/v1/file/${mockFileRecord.id}?unexpected=param`);
        expect(response.status).toBe(400);
    });

    test('GET /v1/file/:id - should return 400 if request body is provided', async () => {
        const response = await request(app)
            .get(`/v1/file/${mockFileRecord.id}`)
            .send("unexpected body"); // This simulates a body in a GET request
        expect(response.status).toBe(400);
    });

    // ----- DELETE Endpoint Tests -----

    test('DELETE /v1/file/:id - should return 204 when file is deleted', async () => {
        fileService.removeFile.mockResolvedValue(mockFileRecord);

        const response = await request(app).delete('/v1/file/file-id');

        expect(response.status).toBe(204);
        expect(response.body).toEqual({});
    });

    test('DELETE /v1/file/:id - should return 404 when file not found', async () => {
        fileService.removeFile.mockResolvedValue(null);

        const response = await request(app).delete('/v1/file/nonexistent-id');

        expect(response.status).toBe(404);
    });

    test('DELETE /v1/file/:id - should return 400 if query parameters are provided', async () => {
        const response = await request(app).delete(`/v1/file/${mockFileRecord.id}?unexpected=param`);
        expect(response.status).toBe(400);
    });

    test('DELETE /v1/file/:id - should return 400 if request body is provided', async () => {
        const response = await request(app)
            .delete(`/v1/file/${mockFileRecord.id}`)
            .send("unexpected body"); // Simulate a body in DELETE request
        expect(response.status).toBe(400);
    });
    
    // ----- Unsupported Methods Tests -----

    test('Unsupported methods should return 405', async () => {
        const unsupportedMethods = [
            { method: 'get', url: '/v1/file' },
            { method: 'put', url: '/v1/file' },
            { method: 'patch', url: '/v1/file' },
            { method: 'delete', url: '/v1/file' },
            { method: 'head', url: '/v1/file/:id' },
            { method: 'post', url: '/v1/file/file-id' },
        ];

        for (const { method, url } of unsupportedMethods) {
            const response = await request(app)[method](url);
            expect(response.status).toBe(405);
        }
    });
});

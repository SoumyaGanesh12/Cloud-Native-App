import request from 'supertest';
import app from '../../server.js';
import * as healthService from '../../services/healthService.js';
jest.mock('../../services/healthService'); // Mock the health service for unit tests

describe('/healthz API Unit Tests', () => {
    afterEach(() => {
        jest.clearAllMocks();
    });

    beforeAll(() => {
        jest.spyOn(console, 'log').mockImplementation(() => {}); // Suppress console.log
        jest.spyOn(console, 'error').mockImplementation(() => {}); // Suppress console.error
    });
    
    afterAll(() => {
        console.log.mockRestore(); // Restore original console.log
        console.error.mockRestore(); // Restore original console.error
    });

    test('Should return 200 OK when database connection and health check creation succeed', async () => {
        healthService.checkDatabaseConnection.mockResolvedValue(true); // DB is connected
        healthService.createHealthCheck.mockResolvedValue({}); // Simulate successful record creation

        const response = await request(app).get('/healthz');

        expect(response.status).toBe(200);
        expect(response.headers['cache-control']).toBe('no-cache, no-store, must-revalidate');
        expect(response.headers['content-length']).toBe('0');
    });

    test('Should return 503 Service Unavailable if database insertion fails', async () => {
        healthService.checkDatabaseConnection.mockResolvedValue(false); // DB connection fails

        const response = await request(app).get('/healthz');

        expect(response.status).toBe(503);
    });

    test('Should return 503 Service Unavailable if health check record creation fails', async () => {
        healthService.checkDatabaseConnection.mockResolvedValue(true); // DB is connected
        healthService.createHealthCheck.mockRejectedValue(new Error('DB Insert Error')); // Insert fails

        const response = await request(app).get('/healthz');

        expect(response.status).toBe(503);
    });

    test('Should return 405 Method Not Allowed for non-GET requests', async () => {
        const methods = ['post', 'put', 'delete', 'patch'];
        for (const method of methods) {
            const response = await request(app)[method]('/healthz');
            expect(response.status).toBe(405);
        }
    });

    test('Should return 400 Bad Request if request has a payload', async () => {
        const response = await request(app)
            .get('/healthz')
            .send({ data: 'invalid' });

        expect(response.status).toBe(400);
    });

    test('Should return 400 Bad Request if request has query parameters', async () => {
        const response = await request(app).get('/healthz?param=1');
        expect(response.status).toBe(400);
    });
});

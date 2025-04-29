import request from 'supertest';
import app from '../../server.js';
import { sequelize } from '../../models/index.js'; // Import Sequelize instance
import HealthCheck from '../../models/healthModel.js';

// Ensure we are testing against the actual database
beforeAll(async () => {
    await sequelize.sync({ force: true }); // Sync DB to ensure test tables exist

    // Suppress console logs
    jest.spyOn(console, 'log').mockImplementation(() => {}); 
    jest.spyOn(console, 'error').mockImplementation(() => {});
});

// Clean database between tests
afterEach(async () => {
    await HealthCheck.destroy({ where: {} });
});

// Close DB connection after tests
afterAll(async () => {
    console.log.mockRestore(); // Restore console.log
    console.error.mockRestore(); // Restore console.error
    
    await sequelize.close();
});

describe('/healthz API Integration Tests', () => {
    test('Should return 200 OK and insert into database', async () => {
        const response = await request(app).get('/healthz');
        expect(response.status).toBe(200);

        // Check if the record exists in the database
        const result = await HealthCheck.findAll();
        expect(result.length).toBe(1);
    });

    test('Should return 503 Service Unavailable if database insertion fails', async () => {
        jest.spyOn(HealthCheck, 'create').mockImplementation(() => {
            throw new Error('DB Insert Error');
        });

        const response = await request(app).get('/healthz');
        expect(response.status).toBe(503);

        HealthCheck.create.mockRestore();
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

import express from 'express';
import { handleHealthCheck, handleUnsupportedMethods } from '../controllers/healthController.js';

const router = express.Router();

// Unsupported methods explicitly defined for '/v1/file'
router.post('/healthz', handleUnsupportedMethods);
router.put('/healthz', handleUnsupportedMethods);
router.patch('/healthz', handleUnsupportedMethods);
router.delete('/healthz', handleUnsupportedMethods);
router.head('/healthz', handleUnsupportedMethods);
router.options('/healthz', handleUnsupportedMethods);

// Health check route (GET request only)
router.get('/healthz', handleHealthCheck);

// CICD health route
// Unsupported methods explicitly defined for '/v1/file'
router.post('/cicd', handleUnsupportedMethods);
router.put('/cicd', handleUnsupportedMethods);
router.patch('/cicd', handleUnsupportedMethods);
router.delete('/cicd', handleUnsupportedMethods);
router.head('/cicd', handleUnsupportedMethods);
router.options('/cicd', handleUnsupportedMethods);

// CICD - Health check route (GET request only)
router.get('/cicd', handleHealthCheck);

export default router;

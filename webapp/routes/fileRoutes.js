import express from 'express';
import multer from 'multer';
import { uploadFile, getFileById, deleteFileById, handleUnsupportedMethods } from '../controllers/fileController.js';

const router = express.Router();
const upload = multer();

// Unsupported methods explicitly defined for '/v1/file'
router.get('/v1/file', handleUnsupportedMethods);
router.put('/v1/file', handleUnsupportedMethods);
router.patch('/v1/file', handleUnsupportedMethods);
router.delete('/v1/file', handleUnsupportedMethods);
router.head('/v1/file', handleUnsupportedMethods);
router.options('/v1/file', handleUnsupportedMethods);

// Unsupported methods explicitly defined for '/v1/file/:id'
router.post('/v1/file/:id', handleUnsupportedMethods);
router.put('/v1/file/:id', handleUnsupportedMethods);
router.patch('/v1/file/:id', handleUnsupportedMethods);
router.head('/v1/file/:id', handleUnsupportedMethods);
router.options('/v1/file/:id', handleUnsupportedMethods);

// Supported methods - upload a file, get file by id and delete file by id
router.post('/v1/file', upload.single('file'), uploadFile);
router.get('/v1/file/:id', getFileById);
router.delete('/v1/file/:id', deleteFileById);

export default router;

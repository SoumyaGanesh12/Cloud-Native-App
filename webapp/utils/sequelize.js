import { Sequelize } from 'sequelize';
import dotenv from 'dotenv';

dotenv.config(); // Load environment variables from .env

const database = process.env.NODE_ENV === 'test' ? process.env.TEST_DB_NAME : process.env.DB_NAME;
const username = process.env.DB_USER;
const password = process.env.DB_PASS;
const host = process.env.DB_HOST;
const dialect = process.env.DB_DIALECT;
const port = process.env.DB_PORT || 5432;

// Configure and initialize Sequelize
const sequelize = new Sequelize(
    database,
    username,
    password,
  {
    host,
    port,
    dialect,
    logging: false, // Disable SQL query logging
  }
);

export default sequelize;

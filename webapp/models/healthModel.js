import { DataTypes } from 'sequelize';
import sequelize from '../utils/sequelize.js';

// Define the HealthCheck table
const HealthCheck = sequelize.define('HealthCheck', {
  checkId: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  datetime: {
    type: DataTypes.DATE,
    defaultValue: sequelize.fn('NOW'),
    allowNull: false,
  },
});

export default HealthCheck;

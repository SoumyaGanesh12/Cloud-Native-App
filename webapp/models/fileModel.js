import { DataTypes } from 'sequelize';
import sequelize from '../utils/sequelize.js';

// Define the File table
const File = sequelize.define('File', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
    readOnly: true,
  },
  file_name: {
    type: DataTypes.STRING,
    allowNull: false,
    readOnly: true,
  },
  url: {
    type: DataTypes.STRING,
    allowNull: false,
    readOnly: true,
  },
  upload_date: {
    type: DataTypes.DATEONLY,
    defaultValue: DataTypes.NOW,
    allowNull: false,
    readOnly: true,
  },
});

export default File;

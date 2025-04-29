import { createLogger, format, transports } from 'winston';
import path from 'path';
import fs from 'fs';
import appRoot from 'app-root-path';

// Determine the log directory relative to project root
const logDir = path.join(appRoot.path, 'logs');

// Ensure the log directory exists
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

const { combine, timestamp, json } = format;
const addSeverity = format((info) => {
  info.severity = info.level.toUpperCase();
  return info;
});

// Create the logger
const logger = createLogger({
  level: 'info', // log 'info' and above

  format: combine(
    timestamp({ format: () => new Date().toISOString() }), // UTC timestamps
    addSeverity(), 
    json()
  ),
  transports: [
    // File transport: logs info/warn/error to webapp.log
    new transports.File({
      filename: path.join(logDir, 'webapp.log'),
      level: 'info'
    }),
    // Console transport: only logs error and above (error, fatal, etc.)
    new transports.Console({
      level: 'error'
    })
  ]
});

export default logger;

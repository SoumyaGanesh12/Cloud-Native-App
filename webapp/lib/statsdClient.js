import { StatsD } from 'node-statsd';

/**
 * Configure a StatsD client that sends metrics to localhost:8125 by default.
 */

let statsdClient;

if (process.env.NODE_ENV === 'test') {
  // In test mode, export a dummy client that does nothing.
  statsdClient = {
    increment: () => {},
    timing: () => {},
    close: () => {},
    socket: {
      on: () => {},
    },
  };
} else {
  statsdClient = new StatsD({
    host: 'localhost',
    port: 8125,
  });

  // Log any socket errors
  statsdClient.socket.on('error', (error) => {
    console.error("Error in StatsD socket:", error);
  });

  // Ensure the socket is closed when the process exits
  process.on('exit', () => {
    statsdClient.close();
  });
}


export default statsdClient;

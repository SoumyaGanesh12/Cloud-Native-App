#!/bin/bash

# Assignment 4 script - includes db installation and configurations
# Exit on any error
set -e
set -x
export DEBIAN_FRONTEND=noninteractive

# Define color variables
RED='\033[0;31m'
NC='\033[0m' # No Color

# Initialize the tracking variables
current_command=""
last_command=""

# Save the previous command and update current command before each command runs
trap 'last_command="$current_command"; current_command="$BASH_COMMAND"' DEBUG

# When an error occurs, print the last executed command and its exit status
trap 'echo -e "${RED}Error: command \"${last_command}\" exited with status $?${NC}"' ERR

echo "====================================="
echo "Checking for existing APT locks..."
echo "====================================="
# Ensure the APT lock is released before proceeding
while sudo lsof /var/lib/apt/lists/lock >/dev/null 2>&1; do
  echo "APT lock still held. Waiting..."
  sleep 5
done

echo "APT lock is released. Proceeding with package update..."
sudo dpkg --configure -a

echo "====================================="
echo "Updating system packages..."
echo "====================================="
sudo apt-get update -y && sudo apt-get upgrade -y

echo "====================================="
echo "Installing Node.js and npm..."
echo "====================================="
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -

# Remove any conflicting npm package if it exists
sudo apt-get remove -y npm || true
sudo apt-get install -y nodejs
node -v
npm -v

echo "====================================="
echo "Installing PostgreSQL..."
echo "====================================="
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "====================================="
echo "Setting up PostgreSQL database and user..."
echo "====================================="
sudo -u postgres psql <<EOF
-- Create the main application database
CREATE DATABASE $DB_NAME;

-- Create the test database for automated testing
CREATE DATABASE $TEST_DB_NAME;

-- Create the database user
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';

-- Grant privileges on both the databases
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $TEST_DB_NAME TO $DB_USER;

-- Change ownership of the public schema to the new user
ALTER DATABASE $DB_NAME OWNER TO $DB_USER;
ALTER DATABASE $TEST_DB_NAME OWNER TO $DB_USER;

-- Ensure the user has necessary privileges on both databases
\c $DB_NAME
ALTER SCHEMA public OWNER TO $DB_USER;
GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;

\c $TEST_DB_NAME;
ALTER SCHEMA public OWNER TO $DB_USER;
GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
EOF

echo "====================================="
echo "Creating Linux group and user..."
echo "====================================="
sudo groupadd csye6225
sudo useradd -m -g csye6225 -s /usr/sbin/nologin csye6225

echo "====================================="
echo "Setting up application directory..."
echo "====================================="
sudo mkdir -p /opt/csye6225
sudo chown csye6225:csye6225 /opt/csye6225
sudo chmod 755 /opt/csye6225

echo "====================================="
echo "Moving and unzipping the application..."
echo "====================================="
sudo mv /tmp/webapp.zip /opt/csye6225/
sudo apt install -y unzip
sudo unzip /opt/csye6225/webapp.zip -d /opt/csye6225/webapp

echo "====================================="
echo "Creating .env file..."
echo "====================================="
if [ ! -d /opt/csye6225/webapp ]; then
    echo "/opt/csye6225/webapp path does not exist. Exiting."
    exit 1
fi
cat <<EOF | sudo tee /opt/csye6225/webapp/.env > /dev/null
DB_NAME=${DB_NAME}
TEST_DB_NAME=${TEST_DB_NAME}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
DB_HOST=${DB_HOST}
DB_DIALECT=${DB_DIALECT}
PORT=${PORT}
EOF

echo "====================================="
echo "Setting ownership and permissions..."
echo "====================================="
sudo chown -R csye6225:csye6225 /opt/csye6225/webapp
sudo chmod -R 755 /opt/csye6225/webapp
sudo chmod 644 /opt/csye6225/webapp/.env

echo "====================================="
echo "Installing Node.js dependencies..."
echo "====================================="
cd /opt/csye6225/webapp
sudo -u csye6225 npm install

echo "====================================="
echo "Verifying PostgreSQL setup..."
echo "====================================="
sudo systemctl status postgresql
sudo -u postgres psql -c "\l"   # List databases
sudo -u postgres psql -c "\du"  # List users

echo "====================================="
echo "Running application tests..."
echo "====================================="
sudo -u csye6225 npm run test

echo "====================================="
echo "Setting up systemd service..."
echo "====================================="
sudo mv /tmp/webapp.service /etc/systemd/system/webapp.service
sudo systemctl daemon-reload
sudo systemctl enable webapp.service
sudo systemctl start webapp.service

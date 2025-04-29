#!/bin/bash

# Exit immediately if a command fails
set -e  

# echo "====================================="
# echo "Updating system packages..."
# echo "====================================="
# Ensure package upgrades automatically select "Keep Local Version" for SSH config
# echo 'openssh-server openssh-server/sshd_config select keep_local' | sudo debconf-set-selections

# Set Dpkg to keep existing configurations by default
# echo 'Dpkg::Options {
#    "--force-confdef";
#    "--force-confold";
# };' | sudo tee /etc/apt/apt.conf.d/local > /dev/null

# export DEBIAN_FRONTEND=noninteractive

# echo "====================================="
# echo "Updating and Upgrading System Packages..."
# echo "====================================="
# sudo apt update -y && sudo apt upgrade -y --allow-downgrades --allow-change-held-packages --no-install-recommends
# sudo apt -y full-upgrade
# sudo dpkg --configure -a

# Check that required environment variables are set
for var in PORT DB_NAME DB_USER DB_PASS DB_HOST DB_DIALECT DB_NAME TEST_DB_NAME; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not set. Please source the source.env file before running this script."
    exit 1
  fi
done

echo "====================================="
echo "Updating system packages..."
echo "====================================="
sudo apt update -y && sudo apt upgrade -y

echo "====================================="
echo "Installing Node.js and npm..."
echo "====================================="
sudo apt install -y nodejs npm
node -v
npm -v

echo "====================================="
echo "Installing PostgreSQL..."
echo "====================================="
sudo apt install -y postgresql postgresql-contrib
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
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '${DB_PASS}';

-- Grant privileges on the main database
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

-- Grant privileges on the test database
GRANT ALL PRIVILEGES ON DATABASE $TEST_DB_NAME TO $DB_USER;

-- Set ownership of the public schema for both databases
ALTER SCHEMA public OWNER TO $DB_USER;

-- Ensure the user has necessary privileges on both databases
\c $DB_NAME;
ALTER SCHEMA public OWNER TO $DB_USER;
GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;

\c $TEST_DB_NAME;
ALTER SCHEMA public OWNER TO $DB_USER;
GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
EOF

echo "====================================="
echo "Creating Linux group and user..."
echo "====================================="
sudo groupadd webapp_group
sudo useradd -m -g webapp_group -s /bin/bash webapp_user

echo "====================================="
echo "Setting up application directory..."
echo "====================================="
sudo mkdir -p /opt/csye6225
sudo chown webapp_user:webapp_group /opt/csye6225
sudo chmod 755 /opt/csye6225

echo "====================================="
echo "Moving and unzipping the application..."
echo "====================================="
sudo mv /tmp/webapp.zip /opt/csye6225/
sudo apt install -y unzip
sudo unzip /opt/csye6225/webapp.zip -d /opt/csye6225/
sudo chown -R webapp_user:webapp_group /opt/csye6225
sudo chmod -R 755 /opt/csye6225

echo "====================================="
echo "Creating .env file for environment variables..."
echo "====================================="
if [ -f ~/source.env ]; then
    sudo cp ~/source.env /opt/csye6225/webapp/.env
else
    echo "Error: source.env file not found in your home directory. Please ensure it was uploaded."
    exit 1
fi

echo "====================================="
echo "Installing Node.js dependencies..."
echo "====================================="
cd /opt/csye6225/webapp
sudo -u webapp_user npm install

echo "====================================="
echo "Verifying PostgreSQL setup..."
echo "====================================="
sudo systemctl status postgresql
sudo -u postgres psql -c "\l"   # List databases
sudo -u postgres psql -c "\du"  # List users

echo "====================================="
echo "Running application tests..."
echo "====================================="
sudo -u webapp_user npm run test

echo "====================================="
echo "Starting the application..."
echo "====================================="
sudo -u webapp_user npm run dev

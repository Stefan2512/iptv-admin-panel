#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to print messages
log() {
  echo "[INFO] $1"
}

# Update package lists
log "Updating package lists..."
sudo apt-get update -y

# Function to install essential packages
install_essentials() {
  log "Installing essential packages (curl, wget, git, unzip)..."
  sudo apt-get install -y curl wget git unzip
  log "Essential packages installed."
}

# Call the function (for now, we'll call it directly, later integrate into main flow)
# install_essentials

log "Installer script initialized."

# Function to install Node.js and npm using nvm
install_nodejs() {
  log "Installing Node.js and npm via nvm..."
  if command -v nvm &> /dev/null; then
    log "nvm is already installed."
  else
    log "Downloading and installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    # Source nvm script to make it available in the current session
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    log "nvm installed."
  fi

  # Install the latest LTS version of Node.js
  log "Installing latest LTS version of Node.js..."
  nvm install --lts
  nvm use --lts # Ensure it's used for the current session, though script might need re-sourcing nvm in new shells/subshells
  nvm alias default 'lts/*' # Set default node version for new shells

  log "Node.js and npm installed."
  log "Node version: $(node -v)"
  log "npm version: $(npm -v)"
}

# Example of how to call (will be integrated later)
# install_nodejs

# Function to install Apache2 web server
install_apache() {
  log "Installing Apache2 web server..."
  sudo apt-get install -y apache2
  log "Apache2 installed."

  log "Enabling necessary Apache modules (rewrite, proxy, proxy_http)..."
  sudo a2enmod rewrite
  sudo a2enmod proxy
  sudo a2enmod proxy_http
  # PHP module will be enabled when PHP is installed, if using libapache2-mod-php
  log "Apache modules enabled."

  log "Restarting Apache to apply changes..."
  sudo systemctl restart apache2
  log "Apache restarted."
}

# Example of how to call (will be integrated later)
# install_apache

# Function to install PHP and required extensions
install_php() {
  log "Installing PHP and extensions (php, libapache2-mod-php, php-mysql, php-json, php-pdo)..."
  # Add ondrej/php PPA for latest PHP versions if needed, but try system default first for wider compatibility.
  # For simplicity, this example uses the default PHP version from Ubuntu's repositories.
  # Users might need to adjust this for specific PHP version requirements.
  sudo apt-get install -y php libapache2-mod-php php-mysql php-json php-pdo

  # Verify PHP installation
  if command -v php &> /dev/null; then
    PHP_VERSION=$(php -r 'echo PHP_VERSION;')
    log "PHP version $PHP_VERSION installed successfully."
  else
    log "PHP installation failed. Please check for errors."
    # exit 1 # Consider exiting if PHP is critical and fails
  fi

  log "Enabling PHP module for Apache..."
  # This should be handled automatically by libapache2-mod-php, but check just in case
  # sudo a2enmod php$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;') # More specific version
  # For libapache2-mod-php, the module name is usually just 'phpX.Y' or 'php'
  # The specific module name can vary. `a2query -m` lists enabled modules.
  # Often, libapache2-mod-php handles its own enabling.
  # If issues, one might need: sudo a2enmod php$(php -r 'echo explode(".", PHP_VERSION)[0].".".explode(".", PHP_VERSION)[1];')

  log "Restarting Apache to load PHP module..."
  sudo systemctl restart apache2
  log "Apache restarted."
}

# Example of how to call (will be integrated later)
# install_php

# Function to install MySQL server and set up the database
install_mysql() {
  log "Installing MySQL server..."
  sudo apt-get install -y mysql-server
  log "MySQL server installed."

  log "Starting MySQL service..."
  sudo systemctl start mysql
  sudo systemctl enable mysql # Enable on boot

  # Secure installation and database setup
  # Note: mysql_secure_installation is interactive. For a fully non-interactive setup,
  # we might need to use DEBIAN_FRONTEND=noninteractive or preseed configurations,
  # or directly manipulate mysql users and privileges.
  # This script will guide the user to secure MySQL and then set up the DB.

  echo ""
  log "IMPORTANT: MySQL Secure Installation"
  log "You may be prompted to set a root password and other security options."
  log "If you have already secured MySQL and set a root password, you can skip some steps."
  log "It is highly recommended to run mysql_secure_installation if this is a new MySQL setup."
  read -p "Run 'sudo mysql_secure_installation' now? (y/N): " run_secure_install
  if [[ "$run_secure_install" =~ ^[Yy]$ ]]; then
    sudo mysql_secure_installation
  else
    log "Skipping mysql_secure_installation. Ensure your MySQL is secure."
  fi

  echo ""
  log "Database Setup for IPTV Admin Panel"
  # Get MySQL root password from user
  read -s -p "Enter MySQL root password (will not be shown): " MYSQL_ROOT_PASSWORD
  echo ""

  DB_NAME="iptv_panel"
  DB_USER_APP="iptv_user" # Optional: Create a dedicated user
  DB_PASS_APP=""          # Will be generated or asked

  # Check if database exists
  if sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "USE ${DB_NAME};" 2>/dev/null; then
    log "Database '${DB_NAME}' already exists."
  else
    log "Creating database '${DB_NAME}'..."
    sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    log "Database '${DB_NAME}' created."
  fi

  # Optional: Create a dedicated application user
  read -p "Create a dedicated MySQL user '${DB_USER_APP}' for the application? (Y/n): " create_app_user
  if [[ ! "$create_app_user" =~ ^[Nn]$ ]]; then
    log "Setting up dedicated application user '${DB_USER_APP}'..."
    read -s -p "Enter password for MySQL user '${DB_USER_APP}' (leave blank to auto-generate): " DB_PASS_APP_INPUT
    echo ""
    if [ -z "$DB_PASS_APP_INPUT" ]; then
      DB_PASS_APP=$(openssl rand -base64 12) # Generate a random password
      log "Generated password for ${DB_USER_APP}: ${DB_PASS_APP}"
    else
      DB_PASS_APP=$DB_PASS_APP_INPUT
    fi

    # Check if user exists
    if sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT User FROM mysql.user WHERE User = '${DB_USER_APP}' AND Host = 'localhost';" | grep "${DB_USER_APP}"; then
      log "User '${DB_USER_APP}'@'localhost' already exists. Granting privileges..."
    else
      log "Creating user '${DB_USER_APP}'@'localhost'..."
      sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER '${DB_USER_APP}'@'localhost' IDENTIFIED BY '${DB_PASS_APP}';"
    fi
    sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER_APP}'@'localhost';"
    sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
    log "User '${DB_USER_APP}' created and granted privileges on '${DB_NAME}'."
    log "IMPORTANT: Store these credentials securely for the backend config:"
    log "DB User: ${DB_USER_APP}"
    log "DB Password: ${DB_PASS_APP}"
  else
    log "Skipping dedicated application user creation. The backend will need to use root or another existing user."
  fi

  log "MySQL setup complete."
}

# Example of how to call (will be integrated later)
# install_mysql

# Function to configure the PHP backend
configure_backend() {
  log "Configuring the backend..."

  # Define web root and backend path
  # This assumes the main project directory is the current directory when script is run,
  # or that the script is run from within the 'installer' directory.
  # Adjust PROJECT_ROOT_DIR if the script is meant to be run from elsewhere.

  # Try to determine project root (assuming installer script is in 'installer' subdir)
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  PROJECT_ROOT_DIR="$(dirname "$SCRIPT_DIR")" # Moves one level up from installer script's dir

  if [ ! -d "${PROJECT_ROOT_DIR}/backend" ]; then
    log "Error: Backend directory not found at ${PROJECT_ROOT_DIR}/backend."
    log "Please ensure you are running the script correctly or specify the project path."
    # Here you could add logic to ask the user for the project path.
    # For now, we'll assume it's found relative to the script.
    # If not found, try current working directory as project root
    if [ -d "./backend" ]; then
        PROJECT_ROOT_DIR="."
        log "Using current directory as project root."
    else
        log "Could not determine project root. Exiting."
        exit 1
    fi
  fi

  WEB_ROOT_APACHE="/var/www/html" # Default Apache root
  APP_BASE_DIR_NAME="iptv-admin-panel" # Name of the directory to create in web root
  TARGET_BACKEND_DIR="${WEB_ROOT_APACHE}/${APP_BASE_DIR_NAME}/backend"
  SOURCE_BACKEND_DIR="${PROJECT_ROOT_DIR}/backend"

  log "Creating application directory in web root: ${WEB_ROOT_APACHE}/${APP_BASE_DIR_NAME}"
  sudo mkdir -p "${WEB_ROOT_APACHE}/${APP_BASE_DIR_NAME}"

  log "Copying backend files from ${SOURCE_BACKEND_DIR} to ${TARGET_BACKEND_DIR}..."
  sudo cp -r "${SOURCE_BACKEND_DIR}" "${TARGET_BACKEND_DIR}"
  # Ensure web server has correct permissions (adjust user/group if not www-data)
  sudo chown -R www-data:www-data "${TARGET_BACKEND_DIR}"
  sudo chmod -R 755 "${TARGET_BACKEND_DIR}"
  log "Backend files copied."

  echo ""
  log "Backend Database Configuration"
  log "Please provide the database connection details for the backend."
  read -p "Database Host (default: localhost): " DB_HOST_INPUT
  DB_HOST=${DB_HOST_INPUT:-localhost}

  read -p "Database Name (default: iptv_panel): " DB_NAME_INPUT
  DB_NAME_APP=${DB_NAME_INPUT:-iptv_panel}

  read -p "Database User (e.g., root or iptv_user): " DB_USER_APP_CFG
  read -s -p "Database Password for ${DB_USER_APP_CFG}: " DB_PASS_APP_CFG
  echo ""

  CONFIG_FILE_PATH="${TARGET_BACKEND_DIR}/config.php"
  log "Creating backend configuration file at ${CONFIG_FILE_PATH}..."

  # Create config.php content
  # Note: Using a heredoc for multiline content.
  # Important: Ensure no leading spaces/tabs before EOF marker if using <<-EOF
  sudo bash -c "cat > ${CONFIG_FILE_PATH}" << EOF
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // Consider making this configurable for security
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if (\$_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration
define('DB_HOST', '${DB_HOST}');
define('DB_USER', '${DB_USER_APP_CFG}');
define('DB_PASS', '${DB_PASS_APP_CFG}');
define('DB_NAME', '${DB_NAME_APP}');

try {
    \$pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8", DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException \$e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed: ' . \$e->getMessage()]);
    exit();
}

function response(\$data, \$code = 200) {
    http_response_code(\$code);
    echo json_encode(\$data);
    exit();
}
?>
EOF

  # Set permissions for config.php (readable by web server, not world-writable)
  sudo chown www-data:www-data "${CONFIG_FILE_PATH}"
  sudo chmod 640 "${CONFIG_FILE_PATH}" # Owner read/write, group read, others no access

  log "Backend configuration file created at ${CONFIG_FILE_PATH}."
  log "Backend configuration complete."
}

# Example of how to call (will be integrated later)
# configure_backend

# Function to build and install the frontend
build_and_install_frontend() {
  log "Building and installing the frontend..."

  # Define paths (similar to backend configuration)
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  PROJECT_ROOT_DIR="$(dirname "$SCRIPT_DIR")"

  if [ ! -f "${PROJECT_ROOT_DIR}/package.json" ]; then
    log "Error: package.json not found at ${PROJECT_ROOT_DIR}."
    log "Attempting to use current directory as project root..."
    if [ -f "./package.json" ]; then
        PROJECT_ROOT_DIR="."
        log "Using current directory as project root for frontend build."
    else
        log "Could not determine project root for frontend. Exiting."
        exit 1
    fi
  fi

  WEB_ROOT_APACHE="/var/www/html"
  APP_BASE_DIR_NAME="iptv-admin-panel" # Should match backend setup
  TARGET_FRONTEND_DIR="${WEB_ROOT_APACHE}/${APP_BASE_DIR_NAME}/frontend" # Or just APP_BASE_DIR_NAME if frontend is at root

  # Source nvm if it was installed by this script to ensure node/npm are available
  if [ -s "$HOME/.nvm/nvm.sh" ]; then
    log "Sourcing nvm for frontend build..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then # Fallback for Homebrew on macOS (though this is Ubuntu installer)
    export NVM_DIR="/usr/local/opt/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  fi

  # Verify Node and npm are available
  if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    log "Error: Node.js or npm is not available. Please ensure Node.js is installed and in PATH."
    log "If nvm was just installed, you might need to open a new terminal or run 'source ~/.nvm/nvm.sh'"
    exit 1
  fi
  log "Using Node version: $(node -v)"
  log "Using npm version: $(npm -v)"

  log "Navigating to project root: ${PROJECT_ROOT_DIR}"
  cd "${PROJECT_ROOT_DIR}"

  log "Installing frontend dependencies (npm install)..."
  npm install
  log "Frontend dependencies installed."

  log "Building frontend application (npm run build)..."
  npm run build # This should create a 'dist' directory
  log "Frontend application built."

  log "Creating frontend directory in web root: ${TARGET_FRONTEND_DIR}"
  sudo mkdir -p "${TARGET_FRONTEND_DIR}"

  # Vite typically builds to 'dist' directory
  BUILD_OUTPUT_DIR="${PROJECT_ROOT_DIR}/dist"
  if [ ! -d "${BUILD_OUTPUT_DIR}" ]; then
    log "Error: Build output directory '${BUILD_OUTPUT_DIR}' not found after build."
    exit 1
  fi

  log "Copying frontend build files from ${BUILD_OUTPUT_DIR} to ${TARGET_FRONTEND_DIR}..."
  # Using rsync for better copying of contents
  sudo rsync -av --delete "${BUILD_OUTPUT_DIR}/" "${TARGET_FRONTEND_DIR}/"
  # Ensure web server has correct permissions
  sudo chown -R www-data:www-data "${TARGET_FRONTEND_DIR}"
  sudo chmod -R 755 "${TARGET_FRONTEND_DIR}"
  log "Frontend files copied."

  # Navigate back to the installer script directory if needed, though script execution path handling is better
  cd "${SCRIPT_DIR}"

  log "Frontend build and installation complete."
}

# Example of how to call (will be integrated later)
# build_and_install_frontend

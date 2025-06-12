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


# Function to install Nginx web server
install_nginx() {
  log "Installing Nginx web server..."
  sudo apt-get install -y nginx
  log "Nginx installed."

  log "Starting Nginx service..."
  sudo systemctl start nginx
  sudo systemctl enable nginx # Enable on boot
  log "Nginx service started and enabled."

  # Basic check
  if systemctl is-active --quiet nginx; then
    log "Nginx is active."
  else
    log "Warning: Nginx does not seem to be active. Check installation."
  fi
}


# Function to install PHP and required extensions for Nginx (PHP-FPM)
install_php() {
  log "Installing PHP and extensions (php-fpm, php-mysql, php-json, php-pdo)..."
  # Add ondrej/php PPA for latest PHP versions if desired, but system default is often fine.
  sudo apt-get install -y php-fpm php-mysql php-json php-pdo php-xml # Added php-xml as it's often useful

  # Determine PHP version to correctly enable and check php-fpm service
  PHP_VERSION_FULL=$(php -r 'echo PHP_VERSION;')
  PHP_MAJOR_MINOR=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')

  if [ -z "$PHP_MAJOR_MINOR" ]; then
    log "Could not determine PHP version. Attempting to use a common default for php-fpm service."
    # Attempt to find a generic fpm service; this is a fallback
    PHP_FPM_SERVICE_NAME=$(systemctl list-units --type=service --all | grep -o 'php[0-9]\.[0-9]*-fpm\.service' | head -n 1)
    if [ -z "$PHP_FPM_SERVICE_NAME" ]; then
        PHP_FPM_SERVICE_NAME="php-fpm" # Generic fallback, might not be version specific
        log "Warning: Using generic 'php-fpm' service name. This might not be correct for your PHP version."
    else
        # Extract version from service name if possible, e.g. phpX.Y-fpm.service
        PHP_FPM_SERVICE_NAME=${PHP_FPM_SERVICE_NAME%.service} # remove .service suffix
        log "Detected PHP-FPM service: $PHP_FPM_SERVICE_NAME"
    fi
  else
    PHP_FPM_SERVICE_NAME="php${PHP_MAJOR_MINOR}-fpm"
    log "PHP version $PHP_VERSION_FULL detected. Corresponding FPM service should be $PHP_FPM_SERVICE_NAME."
  fi

  log "Starting and enabling PHP-FPM service (${PHP_FPM_SERVICE_NAME})..."
  sudo systemctl start "${PHP_FPM_SERVICE_NAME}"
  sudo systemctl enable "${PHP_FPM_SERVICE_NAME}"

  if systemctl is-active --quiet "${PHP_FPM_SERVICE_NAME}"; then
    log "PHP-FPM service (${PHP_FPM_SERVICE_NAME}) is active."
  else
    log "Warning: PHP-FPM service (${PHP_FPM_SERVICE_NAME}) does not seem to be active. Please check installation and service name."
    log "Common service names are php-fpm, phpX.Y-fpm (e.g., php8.2-fpm)."
    log "You can check available services with 'systemctl list-units --type=service | grep fpm'"
  fi

  log "PHP with FPM installed and configured for Nginx."
}


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


# Function to configure Nginx for the IPTV Admin Panel
configure_nginx() {
  log "Configuring Nginx for the application..."

  APP_NAME="iptv-admin-panel" # Used for config file name and paths
  WEB_ROOT="/var/www/html" # Base web root
  APP_ROOT_DIR="${WEB_ROOT}/${APP_NAME}"
  FRONTEND_DIR="${APP_ROOT_DIR}/frontend"
  BACKEND_DIR="${APP_ROOT_DIR}/backend" # Physical path to backend files

  # Determine PHP-FPM socket path
  # This should ideally match the version used in install_php or be dynamically found
  PHP_MAJOR_MINOR=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
  PHP_FPM_SOCK_PATH=""
  if [ -n "$PHP_MAJOR_MINOR" ]; then
      PHP_FPM_SOCK_PATH="/var/run/php/php${PHP_MAJOR_MINOR}-fpm.sock"
      if [ ! -e "$PHP_FPM_SOCK_PATH" ]; then # Check if specific version socket exists
          log "Warning: PHP-FPM socket at ${PHP_FPM_SOCK_PATH} not found. Trying generic /run/php/php-fpm.sock"
          PHP_FPM_SOCK_PATH="/run/php/php-fpm.sock" # Common alternative path
          if [ ! -e "$PHP_FPM_SOCK_PATH" ]; then
              log "Error: Could not find a valid PHP-FPM socket. Tried php${PHP_MAJOR_MINOR}-fpm.sock and /run/php/php-fpm.sock"
              log "Please check your PHP-FPM configuration and socket path."
              # Find any available fpm socket as a last resort.
              PHP_FPM_SOCK_PATH=$(find /var/run/php /run/php -name "php*-fpm.sock" -type s | head -n 1)
              if [ -z "$PHP_FPM_SOCK_PATH" ]; then
                log "Critical: No PHP-FPM socket found. Nginx configuration will likely fail."
                # exit 1 # Or allow to proceed and let nginx -t fail
              else
                log "Found a PHP-FPM socket at: ${PHP_FPM_SOCK_PATH}. Using this."
              fi
          fi
      fi
  else
      log "Warning: Could not determine PHP version for FPM socket. Using generic /run/php/php-fpm.sock"
      PHP_FPM_SOCK_PATH="/run/php/php-fpm.sock" # Fallback if PHP version detection failed
  fi

  NGINX_CONF_FILE="/etc/nginx/sites-available/${APP_NAME}"

  log "Creating Nginx server block configuration at ${NGINX_CONF_FILE}..."

  # Heredoc for Nginx configuration
  # Note: Using \$uri and \$args to prevent Bash variable expansion inside the heredoc.
  # Ensure backend_dir variable is correctly expanded if it's a bash variable.
  # The alias for backend should point to the directory containing index.php and other PHP files.
  # The location /api/ {} block will pass requests to PHP-FPM.
  # All other requests will be handled by the frontend location block.

  sudo bash -c "cat > ${NGINX_CONF_FILE}" << EOF
server {
    listen 80;
    listen [::]:80;

    server_name _; # Replace with your domain if you have one, e.g., iptv.example.com
    root ${FRONTEND_DIR}; # Serves frontend files

    index index.html index.htm;

    # Frontend: Serve static files and handle client-side routing
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API: Pass PHP requests to PHP-FPM
    # Assumes your backend entry point (e.g., index.php for routing, or specific .php files)
    # is within a directory aliased or accessible here.
    # If backend files are in ${BACKEND_DIR} and requests are like /api/users.php
    location ~ ^/api/(.+\.php)$ {
        alias ${BACKEND_DIR}; # Alias to the actual backend files directory
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_FPM_SOCK_PATH};
        fastcgi_param SCRIPT_FILENAME \$request_filename; # Or use \$document_root\$fastcgi_script_name if alias is tricky
        # fastcgi_split_path_info ^(.+\.php)(/.+)$; # If using PATH_INFO
        # include fastcgi_params; # Already included by snippets/fastcgi-php.conf in modern Nginx
    }

    # Optional: If you have other specific backend non-PHP files to serve directly from backend
    # location /api/static/ {
    #    alias ${BACKEND_DIR}/static/;
    # }

    # Security: Deny access to .htaccess files (though Nginx doesn't use them)
    location ~ /\.ht {
        deny all;
    }

    access_log /var/log/nginx/${APP_NAME}.access.log;
    error_log /var/log/nginx/${APP_NAME}.error.log;
}
EOF

  log "Nginx server block created."

  # Enable the site by creating a symlink
  SYMLINK_PATH="/etc/nginx/sites-enabled/${APP_NAME}"
  if [ -L "${SYMLINK_PATH}" ]; then
    log "Symlink ${SYMLINK_PATH} already exists."
  elif [ -f "${SYMLINK_PATH}" ]; then
    log "Warning: A file exists at ${SYMLINK_PATH} (expected a symlink). Backing up and creating symlink."
    sudo mv "${SYMLINK_PATH}" "${SYMLINK_PATH}.bak"
    sudo ln -s "${NGINX_CONF_FILE}" "${SYMLINK_PATH}"
    log "Symlink created."
  else
    sudo ln -s "${NGINX_CONF_FILE}" "${SYMLINK_PATH}"
    log "Symlink created."
  fi

  # Remove default Nginx config if it exists and this is the only site
  DEFAULT_SYMLINK="/etc/nginx/sites-enabled/default"
  if [ -L "${DEFAULT_SYMLINK}" ]; then
    log "Disabling default Nginx site configuration..."
    sudo rm "${DEFAULT_SYMLINK}"
  fi

  log "Testing Nginx configuration..."
  if sudo nginx -t; then
    log "Nginx configuration is OK."
    log "Reloading Nginx..."
    sudo systemctl reload nginx
    log "Nginx reloaded."
  else
    log "Error: Nginx configuration test failed. Please review the error messages."
    log "The problematic configuration file is: ${NGINX_CONF_FILE}"
    log "You might need to manually fix it and then run 'sudo nginx -t' and 'sudo systemctl reload nginx'."
    # exit 1 # Or provide guidance
  fi

  log "Nginx configuration for ${APP_NAME} complete."
}

# Function to display post-installation instructions
post_install_instructions() {
  log "Installation Complete! Please review the summary below."
  echo ""
  echo "=============================================================="
  echo "          IPTV Admin Panel Installation Summary"
  echo "=============================================================="
  echo ""
  echo "Application URL: http://<your_server_ip_or_domain>"
  echo "  - Replace <your_server_ip_or_domain> with your server's actual IP address or configured domain name."
  echo ""
  echo "Key Configuration Files & Details:"
  echo "  - Nginx Site Configuration: /etc/nginx/sites-available/iptv-admin-panel"
  echo "    (Symlinked from /etc/nginx/sites-enabled/iptv-admin-panel)"
  echo "  - Nginx Access Log: /var/log/nginx/iptv-admin-panel.access.log"
  echo "  - Nginx Error Log: /var/log/nginx/iptv-admin-panel.error.log"
  echo ""
  echo "  - Backend Root: /var/www/html/iptv-admin-panel/backend"
  echo "  - Backend Config (Database): /var/www/html/iptv-admin-panel/backend/config.php"
  echo ""
  echo "  - Frontend Root: /var/www/html/iptv-admin-panel/frontend"
  echo ""
  echo "Database:"
  echo "  - MySQL Database Name: iptv_panel (unless changed during setup)"
  echo "  - MySQL User/Password: As entered or generated during the MySQL setup step."
  echo ""

  # Attempt to display the PHP-FPM socket from Nginx config
  NGINX_CONF_FILE="/etc/nginx/sites-available/iptv-admin-panel"
  PHP_FPM_SOCKET_INFO="Could not automatically determine. Please check Nginx config."
  if [ -f "\$NGINX_CONF_FILE" ]; then
    SOCKET_LINE=\$(sudo grep -E 'fastcgi_pass[[:space:]]+unix:' "\$NGINX_CONF_FILE" | sed -e 's/^[[:space:]]*fastcgi_pass[[:space:]]*//' -e 's/;//')
    if [ -n "\$SOCKET_LINE" ]; then
      PHP_FPM_SOCKET_INFO="\$SOCKET_LINE (from Nginx config)"
    fi
  fi
  echo "PHP-FPM Socket: \$PHP_FPM_SOCKET_INFO"
  echo ""
  echo "Important Next Steps:"
  echo "  1. Test the application by navigating to its URL in a web browser."
  echo "  2. If you encounter issues, check the Nginx error logs and PHP-FPM logs."
  echo "     (PHP-FPM log location varies, e.g., /var/log/phpX.Y-fpm.log)"
  echo "  3. For production, consider securing your server (firewall, HTTPS with Let's Encrypt, etc.)."
  echo ""
  echo "=============================================================="
  log "Thank you for using the installer!"
}

# Main function to orchestrate the installation
main() {
  log "Starting IPTV Admin Panel Installation for Nginx..."

  # Check for root/sudo privileges early
  if [ "$EUID" -ne 0 ]; then
    log "This script needs to be run with sudo or as root."
    # Check if sudo is available and re-run with sudo
    if command -v sudo &> /dev/null; then
        log "Attempting to re-run with sudo..."
        sudo bash "$0" "$@" # Re-execute the script with sudo
        exit $? # Exit with the same code as the sudo command
    else
        log "sudo command not found. Please run this script as root."
        exit 1
    fi
  fi

  install_essentials
  install_nodejs # Installs nvm, node, npm
  install_nginx # Installs Nginx
  install_php   # Installs PHP-FPM and extensions
  install_mysql # Installs MySQL server and sets up DB

  # Source nvm again before frontend build if not already in sourced environment from install_nodejs
  # This is crucial if install_nodejs ran in a subshell that exited.
  # However, install_nodejs already tries to make nvm available.
  # If issues occur, uncommenting these lines might be necessary:
  # if [ -s "$HOME/.nvm/nvm.sh" ]; then
  #   log "Sourcing nvm before frontend build in main..."
  #   export NVM_DIR="$HOME/.nvm"
  #   [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  # fi

  configure_backend # Copies backend files, creates config.php
  build_and_install_frontend # Builds React app, copies to web root
  configure_nginx # Sets up Nginx server block

  post_install_instructions

  log "IPTV Admin Panel Installation for Nginx finished!"
  log "Please check for any errors in the output above."
}

# Execute the main function
main "$@"

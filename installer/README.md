# IPTV Admin Panel Installer for Ubuntu (Nginx)

This script automates the installation of the IPTV Admin Panel on a fresh Ubuntu server, using Nginx as the web server and PHP-FPM.

## Prerequisites

- A server running Ubuntu (tested on 20.04 LTS, 22.04 LTS, should work on similar versions).
- Root or sudo privileges are required to run the script.
- Internet connection to download packages.
- It's recommended to run this on a clean system to avoid conflicts, although the script tries to handle existing components where possible.
- If you have an existing MySQL server, you'll be prompted for the root password. If not, MySQL server will be installed, and you'll be guided through `mysql_secure_installation`.

## What it Installs

- **Nginx**: Web server.
- **PHP-FPM**: PHP FastCGI Process Manager for Nginx.
- **PHP Extensions**: `php-mysql` (for database connectivity), `php-json`, `php-pdo`, `php-xml`.
- **Node.js & npm**: Via nvm (Node Version Manager), for building the frontend.
- **MySQL Server**: Database server (unless an existing one is used).
- **Project Dependencies**: Frontend npm packages.
- **Application Files**: Copies backend and built frontend files to `/var/www/html/iptv-admin-panel/`.
- **Nginx Configuration**: Sets up a server block for the application.

## How to Use

1.  **Clone the Repository (if you haven't already):**
    ```bash
    git clone <repository_url>
    cd <repository_directory>
    ```

2.  **Navigate to the Installer Directory:**
    ```bash
    cd installer
    ```

3.  **Make the Installer Script Executable (if needed, though it should be set by git):**
    ```bash
    chmod +x install_nginx.sh
    ```

4.  **Run the Installer Script:**
    You need to run the script with sudo privileges. The script has a check and will attempt to re-run itself with `sudo` if not already run as root or with sudo.
    ```bash
    ./install_nginx.sh
    ```
    Or explicitly:
    ```bash
    sudo ./install_nginx.sh
    ```

5.  **Follow On-Screen Prompts:**
    The script will prompt you for:
    - MySQL root password.
    - Confirmation for creating a dedicated MySQL user for the application (recommended).
    - Password for the new MySQL application user (or it can be auto-generated).
    - Database connection details for the backend `config.php` (host, database name, user, password). Defaults are provided where sensible.

## After Installation

-   Review the summary printed at the end of the installation for important paths, URLs, and credentials.
-   Access the application via your server's IP address or domain name in a web browser.
-   Check Nginx and PHP-FPM logs if you encounter any issues:
    -   Nginx logs: `/var/log/nginx/iptv-admin-panel.access.log` and `iptv-admin-panel.error.log`.
    -   PHP-FPM logs: Vary by version (e.g., `/var/log/php8.2-fpm.log`).

## Idempotency

-   The script attempts to be somewhat idempotent (re-runnable). For example, it checks if packages are already installed before trying to install them again, and checks if directories or symlinks exist.
-   However, for major configuration changes or if something goes wrong, manual intervention might be required. Re-running on a system where a partial installation failed might not always fix all issues.

## Customization

-   **PHP Version**: The script installs the default PHP version available in your Ubuntu repositories along with its corresponding FPM package. If you need a specific PHP version, you might need to add a PPA (e.g., `ppa:ondrej/php`) before running the script or modify the script.
-   **Paths**: Default installation path is `/var/www/html/iptv-admin-panel/`. This can be changed by modifying the script variables.
-   **Nginx Configuration**: The Nginx server block is fairly standard. For advanced configurations (e.g., SSL/HTTPS, custom headers), you may need to edit `/etc/nginx/sites-available/iptv-admin-panel` after installation.

## Troubleshooting

-   "Could not determine PHP version" or "PHP-FPM service not found": Ensure PHP and its FPM variant are correctly installed. The script tries to auto-detect the service name (e.g., `php8.2-fpm`), but this can sometimes fail if using non-standard PHP installations.
-   "Nginx configuration test failed": Carefully check the error message provided by `nginx -t`. The script will point to the generated config file. Common issues include typos, incorrect paths, or problems with the PHP-FPM socket.
-   "Frontend not loading correctly": Check browser developer console for errors. Ensure `npm install` and `npm run build` completed without errors during installation. Verify Nginx is correctly serving files from the frontend directory.
-   "Backend API errors / Database connection failed": Double-check the database credentials in `/var/www/html/iptv-admin-panel/backend/config.php`. Ensure the MySQL user has correct privileges on the `iptv_panel` database.

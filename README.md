# IPTV Admin Panel

Modern React + PHP admin panel for IPTV management.

## Features
- Real-time dashboard with MySQL data
- Stream management (Live TV, Movies, Series, Radio)
- User account management
- Server monitoring
- Device management (MAG, Enigma2)
- Modern responsive UI

## Tech Stack
- Frontend: React + Vite + Tailwind CSS
- Backend: PHP 8.4 + MySQL
- Server: Nginx
- Charts: Recharts

## Setup
1. Clone repository
2. Install dependencies: `npm install`
3. Configure MySQL in `backend/config.php`
4. Start frontend: `npm run dev`
5. Access: http://your-server:3000

## API Endpoints
- `GET /dashboard` - Dashboard stats
- `GET /streams` - Stream list
- `GET /users` - User management
- `GET /servers` - Server status
- `GET /devices` - Device management

## Production
- Frontend: http://95.216.67.55:3000/
- API: http://95.216.67.55:9999/
- Compatible with XUI One v1.2.12

Created by Stefan2512

<?php
require_once 'config.php';

try {
    // Get total streams
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM streams");
    $totalStreams = $stmt->fetch()['total'];
    
    // Get active users
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM lines WHERE enabled = 1 AND admin_enabled = 1");
    $activeUsers = $stmt->fetch()['total'];
    
    // Get online connections
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM lines_live");
    $onlineConnections = $stmt->fetch()['total'];
    
    // Get servers count
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM servers WHERE enabled = 1");
    $servers = $stmt->fetch()['total'];
    
    // Get stream types distribution
    $stmt = $pdo->query("
        SELECT 
            CASE 
                WHEN type = 1 THEN 'Live TV'
                WHEN type = 2 THEN 'Movies' 
                WHEN type = 4 THEN 'Radio'
                WHEN type = 5 THEN 'Series'
                ELSE 'Other'
            END as name,
            COUNT(*) as count,
            CASE 
                WHEN type = 1 THEN '#3B82F6'
                WHEN type = 2 THEN '#10B981'
                WHEN type = 4 THEN '#EF4444'
                WHEN type = 5 THEN '#F59E0B'
                ELSE '#6B7280'
            END as color
        FROM streams 
        GROUP BY type
    ");
    $streamStats = $stmt->fetchAll();
    
    // Get connection data for today (mock data - you can implement real tracking)
    $connectionData = [
        ['time' => '00:00', 'connections' => rand(100, 300)],
        ['time' => '04:00', 'connections' => rand(50, 200)],
        ['time' => '08:00', 'connections' => rand(200, 500)],
        ['time' => '12:00', 'connections' => rand(400, 800)],
        ['time' => '16:00', 'connections' => rand(500, 1000)],
        ['time' => '20:00', 'connections' => rand(800, 1500)],
        ['time' => '23:59', 'connections' => $onlineConnections]
    ];
    
    response([
        'dashboardData' => [
            'totalStreams' => (int)$totalStreams,
            'activeUsers' => (int)$activeUsers,
            'onlineConnections' => (int)$onlineConnections,
            'servers' => (int)$servers,
            'totalBandwidth' => '2.4 TB', // You can calculate this from your logs
            'peakConnections' => max(array_column($connectionData, 'connections'))
        ],
        'streamStats' => $streamStats,
        'connectionData' => $connectionData
    ]);
    
} catch (Exception $e) {
    response(['error' => $e->getMessage()], 500);
}
?>

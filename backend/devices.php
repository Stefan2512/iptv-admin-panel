<?php
require_once 'config.php';

try {
    $stmt = $pdo->query("
        SELECT mag_id as id, mac, user_id, last_active,
               CASE 
                   WHEN last_active > (UNIX_TIMESTAMP() - 300) THEN 'online'
                   ELSE 'offline'
               END as status
        FROM mag_devices 
        ORDER BY last_active DESC 
        LIMIT 100
    ");
    $devices = $stmt->fetchAll();
    response($devices);
    
} catch (Exception $e) {
    response(['error' => $e->getMessage()], 500);
}
?>

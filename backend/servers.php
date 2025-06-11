<?php
require_once 'config.php';

try {
    $stmt = $pdo->query("
        SELECT id, server_name, server_ip, server_type, status, enabled,
               total_clients, http_broadcast_port, https_broadcast_port,
               CASE 
                   WHEN status = 1 THEN 'online'
                   WHEN status = 0 THEN 'offline'
                   WHEN status = -1 THEN 'maintenance'
                   ELSE 'unknown'
               END as status_text
        FROM servers 
        ORDER BY is_main DESC, server_name ASC
    ");
    $servers = $stmt->fetchAll();
    response($servers);
    
} catch (Exception $e) {
    response(['error' => $e->getMessage()], 500);
}
?>

<?php
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        try {
            $stmt = $pdo->query("
                SELECT id, username, enabled, admin_enabled, exp_date, 
                       max_connections, last_ip, created_at,
                       CASE 
                           WHEN enabled = 1 AND admin_enabled = 1 THEN 'active'
                           WHEN enabled = 0 OR admin_enabled = 0 THEN 'disabled'
                           ELSE 'unknown'
                       END as status
                FROM lines 
                ORDER BY created_at DESC 
                LIMIT 100
            ");
            $users = $stmt->fetchAll();
            response($users);
        } catch (Exception $e) {
            response(['error' => $e->getMessage()], 500);
        }
        break;
        
    case 'POST':
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            
            $stmt = $pdo->prepare("
                INSERT INTO lines (username, password, enabled, admin_enabled, max_connections, exp_date, created_at) 
                VALUES (?, ?, 1, 1, ?, ?, ?)
            ");
            
            $stmt->execute([
                $input['username'],
                $input['password'],
                $input['max_connections'] ?? 1,
                strtotime($input['exp_date'] ?? '+1 year'),
                time()
            ]);
            
            $userId = $pdo->lastInsertId();
            response(['id' => $userId, 'message' => 'User created successfully']);
            
        } catch (Exception $e) {
            response(['error' => $e->getMessage()], 500);
        }
        break;
        
    case 'PUT':
        // Update user logic
        $pathInfo = $_SERVER['PATH_INFO'] ?? '';
        $userId = trim($pathInfo, '/');
        
        if (!$userId) {
            response(['error' => 'User ID required'], 400);
        }
        
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            
            $stmt = $pdo->prepare("UPDATE lines SET enabled = ?, admin_enabled = ? WHERE id = ?");
            $stmt->execute([
                $input['enabled'] ?? 1,
                $input['admin_enabled'] ?? 1,
                $userId
            ]);
            
            response(['message' => 'User updated successfully']);
            
        } catch (Exception $e) {
            response(['error' => $e->getMessage()], 500);
        }
        break;
        
    case 'DELETE':
        $pathInfo = $_SERVER['PATH_INFO'] ?? '';
        $userId = trim($pathInfo, '/');
        
        if (!$userId) {
            response(['error' => 'User ID required'], 400);
        }
        
        try {
            $stmt = $pdo->prepare("DELETE FROM lines WHERE id = ?");
            $stmt->execute([$userId]);
            
            response(['message' => 'User deleted successfully']);
            
        } catch (Exception $e) {
            response(['error' => $e->getMessage()], 500);
        }
        break;
}
?>

<?php
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        try {
            $stmt = $pdo->query("
                SELECT s.*, 
                       sc.category_name,
                       CASE 
                           WHEN s.type = 1 THEN 'Live TV'
                           WHEN s.type = 2 THEN 'Movie'
                           WHEN s.type = 4 THEN 'Radio'
                           WHEN s.type = 5 THEN 'Series'
                           ELSE 'Unknown'
                       END as type_name
                FROM streams s 
                LEFT JOIN streams_categories sc ON FIND_IN_SET(sc.id, s.category_id)
                ORDER BY s.added DESC 
                LIMIT 100
            ");
            $streams = $stmt->fetchAll();
            response($streams);
        } catch (Exception $e) {
            response(['error' => $e->getMessage()], 500);
        }
        break;
        
    case 'POST':
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            
            $stmt = $pdo->prepare("
                INSERT INTO streams (stream_display_name, stream_source, type, category_id, added, enabled) 
                VALUES (?, ?, ?, ?, ?, 1)
            ");
            
            $stmt->execute([
                $input['stream_display_name'],
                $input['stream_source'],
                $input['type'],
                $input['category_id'] ?? null,
                time()
            ]);
            
            $streamId = $pdo->lastInsertId();
            response(['id' => $streamId, 'message' => 'Stream created successfully']);
            
        } catch (Exception $e) {
            response(['error' => $e->getMessage()], 500);
        }
        break;
        
    case 'PUT':
        // Update stream logic here
        break;
        
    case 'DELETE':
        // Delete stream logic here
        break;
}
?>

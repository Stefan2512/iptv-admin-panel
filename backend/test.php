<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

echo json_encode([
    'status' => 'success',
    'message' => 'PHP + Nginx working!',
    'timestamp' => date('Y-m-d H:i:s')
]);
?>

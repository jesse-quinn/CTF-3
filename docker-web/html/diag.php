<?php
// NetDiag runner. The operator picks a diagnostic and a target host, and the
// tool output is returned verbatim. The host value is concatenated into the
// shell command so operators can append their own flags (for example
// "-c 4 10.0.0.1"). No input validation is performed, which is the whole bug:
// the host field reaches /bin/sh unsanitized (OS command injection).

error_reporting(0);
ini_set('display_errors', 0);

$host = $_POST['host'] ?? '';
$tool = $_POST['tool'] ?? 'ping';

$commands = [
    'ping'     => 'ping -c 1 -W 1',
    'nslookup' => 'nslookup',
    'whois'    => 'whois',
];

$binary = $commands[$tool] ?? $commands['ping'];

$output = '';
if ($host !== '') {
    $cmd = $binary . ' ' . $host . ' 2>&1';
    $output = shell_exec($cmd);
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NetDiag Result</title>
    <link href="https://fonts.googleapis.com/css2?family=Roboto+Mono:wght@400;700&display=swap" rel="stylesheet">
    <style>
        body {
            background-color: #0d1117;
            color: #c9d1d9;
            font-family: 'Roboto Mono', monospace;
            margin: 0;
            padding: 6vh 8vw;
        }
        h1 { font-size: 18px; color: #58a6ff; }
        a { color: #8b949e; font-size: 13px; }
        pre {
            background-color: #161b22;
            border: 1px solid #30363d;
            border-radius: 6px;
            padding: 16px;
            white-space: pre-wrap;
            word-wrap: break-word;
            font-size: 13px;
            line-height: 1.5;
        }
    </style>
</head>
<body>
    <h1>Diagnostic output</h1>
    <pre><?php echo htmlspecialchars($output ?? '(no output)'); ?></pre>
    <a href="index.php">Run another diagnostic</a>
</body>
</html>

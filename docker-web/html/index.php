<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NetDiag Console</title>
    <link href="https://fonts.googleapis.com/css2?family=Roboto+Mono:wght@400;700&display=swap" rel="stylesheet">
    <style>
        body {
            background-color: #0d1117;
            color: #c9d1d9;
            font-family: 'Roboto Mono', monospace;
            display: flex;
            justify-content: center;
            align-items: flex-start;
            min-height: 100vh;
            margin: 0;
            padding-top: 8vh;
        }
        .panel {
            background-color: #161b22;
            border: 1px solid #30363d;
            border-radius: 8px;
            padding: 28px 34px;
            width: 460px;
            box-shadow: 0 6px 20px rgba(0, 0, 0, 0.6);
        }
        h1 {
            font-size: 20px;
            margin: 0 0 4px 0;
            color: #58a6ff;
        }
        p.sub {
            margin: 0 0 20px 0;
            color: #8b949e;
            font-size: 13px;
        }
        label {
            display: block;
            margin: 12px 0 4px 0;
            font-size: 13px;
            color: #8b949e;
        }
        input[type="text"], select {
            width: 100%;
            box-sizing: border-box;
            padding: 9px 10px;
            border: 1px solid #30363d;
            border-radius: 5px;
            background-color: #0d1117;
            color: #c9d1d9;
            font-family: inherit;
            font-size: 14px;
        }
        input[type="submit"] {
            margin-top: 18px;
            width: 100%;
            padding: 10px;
            background-color: #238636;
            border: none;
            border-radius: 5px;
            color: #ffffff;
            font-size: 15px;
            cursor: pointer;
        }
        input[type="submit"]:hover {
            background-color: #2ea043;
        }
    </style>
</head>
<body>
    <div class="panel">
        <h1>NetDiag Console</h1>
        <p class="sub">Internal network diagnostics for the operations team.</p>
        <!--
            TODO(ops): the host field is handed straight to the shell so
            operators can pass their own ping flags. Sanitize it before we
            expose this beyond the LAN.
        -->
        <form action="diag.php" method="POST">
            <label for="host">Host or IP</label>
            <input type="text" id="host" name="host" placeholder="e.g. 10.0.0.1" autofocus>
            <label for="tool">Diagnostic</label>
            <select id="tool" name="tool">
                <option value="ping">ping</option>
                <option value="nslookup">nslookup</option>
                <option value="whois">whois</option>
            </select>
            <input type="submit" value="Run">
        </form>
    </div>
</body>
</html>

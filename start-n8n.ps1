# Start n8n as a background process and open the UI
# Run this once per Windows session (or add to startup)

$already = Get-Process -Name "node" -ErrorAction SilentlyContinue |
    Where-Object { (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine -like "*n8n*" }

if ($already) {
    Write-Host "n8n is already running (PID $($already.Id)). Opening UI..." -ForegroundColor Green
} else {
    Write-Host "Starting n8n..." -ForegroundColor Cyan

    # Load .env into the current process so n8n inherits the vars
    $envFile = Join-Path $PSScriptRoot ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | Where-Object { $_ -match "^\s*[^#].*=.*" } | ForEach-Object {
            $parts = $_ -split "=", 2
            [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim(), "Process")
        }
        Write-Host ".env loaded" -ForegroundColor DarkGray
    }

    Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c n8n start" `
        -WindowStyle Minimized `
        -WorkingDirectory $PSScriptRoot

    # Wait until port 5678 is accepting connections
    $timeout = 30
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        try {
            $null = (New-Object System.Net.Sockets.TcpClient).Connect("localhost", 5678)
            break
        } catch {
            Start-Sleep -Seconds 1
            $elapsed++
        }
    }

    if ($elapsed -ge $timeout) {
        Write-Host "n8n did not start within ${timeout}s. Check for errors." -ForegroundColor Red
        exit 1
    }

    Write-Host "n8n is up at http://localhost:5678" -ForegroundColor Green
}

Start-Process "http://localhost:5678"

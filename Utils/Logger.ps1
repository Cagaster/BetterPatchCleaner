# Classe Logger centralisée
class Logger {
    hidden [string] $LogPath

    Logger() {
        $rootPath = Split-Path $PSScriptRoot -Parent
        $logDir   = Join-Path (Join-Path $rootPath "Resources") "Logs"
    
        # S'assure que le dossier existe
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
    
        $this.LogPath = Join-Path $logDir ("InstallerCacheCleaner_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    }    

    [void] StartLog() {
        if (-not (Test-Path (Split-Path $this.LogPath -Parent))) { New-Item -ItemType Directory -Force -Path (Split-Path $this.LogPath -Parent) | Out-Null }
        "# $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') — Démarrage du log" | Out-File -FilePath $this.LogPath -Append
    }

    [void] StopLog() {
        
    }

    [void] LogInfo([string]$message) {
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [INFO] $message" | Out-File -FilePath $this.LogPath -Append
    }

    [void] LogError([object]$errObj) {
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [ERROR] $errObj" | Out-File -FilePath $this.LogPath -Append
    }
}

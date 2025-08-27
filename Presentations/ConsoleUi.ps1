# Interaction console (Write-Verbose, Write-Host…)
class ConsoleUi {
    hidden [Logger] $Logger

    ConsoleUi([Logger]$logger) {
        $this.Logger = $logger
    }

    [void] RunCliMode([PatchCleaner]$patchCleaner, [string]$installerFolder, [hashtable]$config, [string]$cliAction, [string]$cliDestination, [bool]$whatIf) {
        $records = $patchCleaner.FindOrphanedFiles($installerFolder, $config)

        if ($cliAction -ne 'None') {
            if ($cliAction -eq 'Move' -and -not $cliDestination) { throw "Dossier de destination requis pour l'action Move en mode CLI." }

            $orphans = $records | Where-Object { -not $_.InUse -and -not $_.Excluded }
            foreach ($orphan in $orphans) { $orphan.SelectedAction = [ActionType]::$cliAction }

            $patchCleaner.PerformActions($orphans, $cliDestination, $whatIf)
        }

        $rootPath = Split-Path $PSScriptRoot -Parent
        $reportDir = Join-Path (Join-Path $rootPath "Resources") "Reports"
        if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }
        $reportPath = Join-Path $reportDir "InstallerCacheCleaner_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        $report = $patchCleaner.GenerateReport($records, $reportPath)
        Write-Host "Rapport généré : $report" -ForegroundColor Green
        Start-Process $report
    }
}

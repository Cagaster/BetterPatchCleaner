# Orchestration : parsing CLI, lancement GUI, appels aux services
function Invoke-Main {
    param(
        [string] $InstallerFolder,
        [string] $DefaultQuarantineFolder,
        [string] $UiCulture,
        [switch] $NoGui,
        [switch] $WhatIfOnly,
        [string] $CliAction,
        [string] $CliDestination
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

    $logger = [Logger]::new()
    $logger.StartLog()

    try {
        Ensure-Administrator

        $configProvider = [ConfigProvider]::new()
        $config = $configProvider.GetConfig()

        if ($WhatIfOnly) { $WhatIfPreference = $true }

        $patchCleaner = [PatchCleaner]::new($logger, $configProvider)

        if ($NoGui) {
            # Mode CLI
            $consoleUi = [ConsoleUi]::new($logger)
            $consoleUi.RunCliMode($patchCleaner, $InstallerFolder, $config, $CliAction, $CliDestination, $WhatIfOnly)
        } else {
            # Mode GUI
            $wpfUi = [WpfUi]::new($logger, $patchCleaner, $DefaultQuarantineFolder, $WhatIfOnly)
            $wpfUi.RunGuiMode($InstallerFolder, $config)
        }
    } catch {
        $logger.LogError($_)
        throw
    } finally {
        $logger.StopLog()
    }
}

function Ensure-Administrator {
    if (-not (Test-IsAdministrator)) {
        Write-Host "Élévation des privilèges requise…" -ForegroundColor Yellow
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = (Get-Process -Id $PID).Path
        $psi.Arguments = ('-NoProfile -ExecutionPolicy Bypass -File "{0}" {1}' -f $MyInvocation.MyCommand.Path, ($PSBoundParameters.Keys | ForEach-Object { "-$_ `"$($PSBoundParameters[$_])`"" } -join ' '))
        $psi.Verb = 'runas'
        try {
            $proc = [System.Diagnostics.Process]::Start($psi)
            $proc.WaitForExit()
            exit $proc.ExitCode
        } catch {
            throw "Élévation refusée par l'utilisateur. Arrêt."
        }
    }
}

function Test-IsAdministrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

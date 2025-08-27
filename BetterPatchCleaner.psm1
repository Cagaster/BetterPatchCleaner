<#
.SYNOPSIS
Module d’agrégation et de chargement des composants OOP de BetterPatchCleaner.
.DESCRIPTION
Charge dynamiquement toutes les classes et fonctions des sous-dossiers, expose
les cmdlets publiques et prépare l’environnement du module.
#>

# Point d'entrée du module qui exporte les classes et cmdlets

$ErrorActionPreference = 'Stop'

# Empêche le chargement multiple
if (-not $script:ModuleInitialized) {
    $script:ModuleInitialized = $true

    Set-StrictMode -Version Latest

    Add-Type -AssemblyName System.Web
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    Add-Type -AssemblyName System.Windows.Forms

    $moduleRoot = $PSScriptRoot

    # Liste ordonnée des fichiers à charger (dépendances d'abord)
    $filesToSource = @(
        "$moduleRoot\Utils\Logger.ps1",
        "$moduleRoot\Domains\ActionType.ps1",
        "$moduleRoot\Domains\FileRecord.ps1",
        "$moduleRoot\Domains\CleanResult.ps1",
        "$moduleRoot\Infrastructures\ConfigProvider.ps1",
        "$moduleRoot\Infrastructures\FileValidator.ps1",
        "$moduleRoot\Infrastructures\RegistryReader.ps1",
        "$moduleRoot\Infrastructures\ReportGenerator.ps1",
        "$moduleRoot\Domains\PatchCleaner.ps1",
        "$moduleRoot\Presentations\ConsoleUi.ps1",
        "$moduleRoot\Views\MainWindow.xaml.ps1",
        "$moduleRoot\Presentations\WpfUi.ps1",
        "$moduleRoot\App\Main.ps1"
    )

    foreach ($file in $filesToSource) {
        if (Test-Path $file) {
            . $file
        } else {
            Write-Error "Fichier manquant : $file"
        }
    }
}

Export-ModuleMember -Function Start-PatchCleaner

# Fonction d'entrée pour lancer l'outil
function Start-PatchCleaner {
    param(
        [string] $InstallerFolder = 'C:\Windows\Installer',
        [string] $DefaultQuarantineFolder = "$env:PUBLIC\InstallerCacheQuarantine",
        [ValidateSet('fr-FR','en-US')] [string] $UiCulture = 'fr-FR',
        [switch] $NoGui,
        [switch] $WhatIfOnly,
        [ValidateSet('None','Move','Delete')] [string] $CliAction = 'None',
        [string] $CliDestination
    )

    # Orchestration déplacée vers App\Main.ps1
    Invoke-Main -InstallerFolder $InstallerFolder `
                -DefaultQuarantineFolder $DefaultQuarantineFolder `
                -UiCulture $UiCulture `
                -NoGui:$NoGui `
                -WhatIfOnly:$WhatIfOnly `
                -CliAction $CliAction `
                -CliDestination $CliDestination
}

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

Export-ModuleMember -Function Start-PatchCleaner

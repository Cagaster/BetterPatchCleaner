<#
.SYNOPSIS
    Script de lancement de BetterPatchCleaner avec élévation automatique en administrateur.

.DESCRIPTION
    - Vérifie si PowerShell est lancé avec des privilèges administrateur.
    - Si non, relance le script en mode administrateur.
    - Importe le module BetterPatchCleaner.psm1.
    - Exécute la fonction Start-PatchCleaner.

.NOTES
    Auteur   : Gilles
    Date     : 2025-08-21
#>

# Vérifie si l'utilisateur a les droits administrateur
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Relance du script en mode administrateur..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-sta -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Positionne le chemin courant sur le dossier du script
Set-Location -Path (Split-Path -Parent $PSCommandPath)

# Importation du module
try {
    Import-Module .\BetterPatchCleaner.psm1 -Force -ErrorAction Stop
    Write-Host "Module BetterPatchCleaner importé avec succès." -ForegroundColor Green
}
catch {
    Write-Error "Échec lors de l'import du module : $($_.Exception.Message)"
    Read-Host "Appuyez sur Entrée pour quitter..."
    exit 1
}

# Lancement de la fonction principale
try {
    # Start-PatchCleaner -NoGui -CliAction Move -CliDestination 'C:\Quarantine'  # Décommentez pour tester CLI
    Write-Host "Lancement de BetterPatchCleaner..." -ForegroundColor Cyan
    Write-Host "Version PowerShell : $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "Apartment State : $([System.Threading.Thread]::CurrentThread.ApartmentState)" -ForegroundColor Cyan
    Start-PatchCleaner
    Write-Host "Exécution terminée avec succès." -ForegroundColor Green
}
catch {
    Write-Error "Erreur lors de l'exécution de Start-PatchCleaner : $($_.Exception.Message)"
    Write-Host "Détails : $($_.Exception | Format-List -Force | Out-String)" -ForegroundColor Red
}

# Pause pour garder la console ouverte (debug)
Read-Host "Appuyez sur Entrée pour quitter..."

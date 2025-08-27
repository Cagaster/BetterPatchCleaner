# Classe principale qui orchestre le nettoyage
class PatchCleaner {
    hidden [Logger] $Logger
    hidden [ConfigProvider] $ConfigProvider
    hidden [RegistryReader] $RegistryReader
    hidden [ReportGenerator] $ReportGenerator

    PatchCleaner([Logger]$logger, [ConfigProvider]$configProvider) {
        $this.Logger = $logger
        $this.ConfigProvider = $configProvider
        $this.RegistryReader = [RegistryReader]::new()
        $this.ReportGenerator = [ReportGenerator]::new()
    }

    [FileRecord[]] FindOrphanedFiles([string]$installerFolder, [hashtable]$config) {
        $inUseFiles = $this.RegistryReader.GetInUseInstallerFiles()
        $inUseSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($file in $inUseFiles) { [void]$inUseSet.Add($file.Path) }

        $files = Get-ChildItem -LiteralPath $installerFolder -File -Include *.msi,*.msp -Force -ErrorAction SilentlyContinue
        $results = @()

        foreach ($file in $files) {
            $inUse = $inUseSet.Contains($file.FullName)
            $meta = $this.GetMetadata($file.FullName, $config.InspectMetadata)
            $result = $this.IsExcluded($file, $meta, $config)
            $excluded = $result.Excluded
            $reason = $result.Reason

            $recommended = if ($config.RecommendMoveByDefault -and -not $inUse -and -not $excluded) { [ActionType]::Move } else { [ActionType]::None }

            $record = [FileRecord]::new($file, $inUse, $excluded, $reason, $meta, $recommended)
            $results += $record
        }

        return $results
    }

    hidden [hashtable] GetMetadata([string]$path, [bool]$inspect) {
        if (-not $inspect) { return @{ Manufacturer = $null; ProductName = $null; ProductVersion = $null } }

        $kind = [IO.Path]::GetExtension($path).TrimStart('.').ToUpperInvariant()
        if ($kind -eq 'MSI') { return [FileValidator]::GetMsiMetadata($path) }
        if ($kind -eq 'MSP') { return [FileValidator]::GetMspMetadata($path) }
        return @{ Manufacturer = $null; ProductName = $null; ProductVersion = $null }
    }

    hidden [pscustomobject] IsExcluded([System.IO.FileInfo]$file, [hashtable]$meta, [hashtable]$config) {
        foreach ($rx in $config.ExcludedFilePatterns) {
            if ($file.FullName -match $rx) { return [pscustomobject]@{ Excluded = $true; Reason = "Exclu par motif de fichier : $rx" } }
        }
        if ($meta.Manufacturer) {
            foreach ($rx in $config.ExcludedVendors) {
                if ($meta.Manufacturer -match $rx) { return [pscustomobject]@{ Excluded = $true; Reason = "Exclu par éditeur : $($meta.Manufacturer)" } }
            }
        }
        if ($meta.ProductName) {
            foreach ($rx in $config.ExcludedProducts) {
                if ($meta.ProductName -match $rx) { return [pscustomobject]@{ Excluded = $true; Reason = "Exclu par produit : $($meta.ProductName)" } }
            }
        }
        return [pscustomobject]@{ Excluded = $false; Reason = $null }
    }

    [CleanResult[]] PerformActions([FileRecord[]]$records, [string]$destination, [bool]$whatIf) {
        $results = @()

        if ($records | Where-Object { $_.SelectedAction -eq [ActionType]::Move }) {
            if (-not $destination) { throw 'Destination requise pour Move.' }
            if (-not (Test-Path $destination)) { New-Item -ItemType Directory -Force -Path $destination | Out-Null }
        }

        foreach ($record in $records) {
            $action = $record.SelectedAction
            if ($action -eq [ActionType]::None) { continue }

            $success = $true
            $message = ""

            try {
                switch ($action) {
                    ([ActionType]::Move) {
                        $dest = Join-Path $destination $record.FileName
                        if ($whatIf) {
                            $message = "[SIMULATION] Move: $($record.Path) -> $dest"
                        } else {
                            Move-Item -LiteralPath $record.Path -Destination $dest -Force
                            $message = "[OK] Déplacé: $($record.Path) -> $dest"
                        }
                    }
                    ([ActionType]::Delete) {
                        if ($whatIf) {
                            $message = "[SIMULATION] Delete: $($record.Path)"
                        } else {
                            Remove-Item -LiteralPath $record.Path -Force
                            $message = "[OK] Supprimé: $($record.Path)"
                        }
                    }
                }
            } catch {
                $success = $false
                $message = "Erreur: $_"
            }

            $results += [CleanResult]::new($success, $message, $record, $action)
            $this.Logger.LogInfo($message)
        }

        return $results
    }

    [string] GenerateReport([FileRecord[]]$records, [string]$reportPath) {
        return $this.ReportGenerator.NewHtmlReport($records, $reportPath)
    }
}

# Logique derrière l’UI WPF
class WpfUi {
    hidden [Logger] $Logger
    hidden [PatchCleaner] $PatchCleaner
    hidden [string] $DefaultQuarantineFolder
    hidden [bool] $WhatIf
    hidden [FileRecord[]] $LastAnalysis = @()
    WpfUi([Logger]$logger, [PatchCleaner]$patchCleaner, [string]$defaultQuarantineFolder, [bool]$whatIf) {
        $this.Logger = $logger
        $this.PatchCleaner = $patchCleaner
        $this.DefaultQuarantineFolder = $defaultQuarantineFolder
        $this.WhatIf = $whatIf
    }
    [void] RunGuiMode([string]$installerFolder, [hashtable]$config) {
        $xaml = Get-MainWindowXaml
        $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
        $window = [Windows.Markup.XamlReader]::Load($reader)
        # Raccourcis contrôles
        $btnScan = $window.FindName('BtnScan')
        $btnSimulate = $window.FindName('BtnSimulate')
        $btnMove = $window.FindName('BtnMove')
        $btnDelete = $window.FindName('BtnDelete')
        $btnChangeToDelete = $window.FindName('BtnChangeToDelete')
        $btnSaveConfig = $window.FindName('BtnSaveConfig')
        $txtSearch = $window.FindName('TxtSearch')
        $chkShowExcluded = $window.FindName('ChkShowExcluded')
        $grid = $window.FindName('GridItems')
        $txtVendors = $window.FindName('TxtVendors')
        $txtProducts = $window.FindName('TxtProducts')
        $txtFiles = $window.FindName('TxtFiles')
        $chkRecommend = $window.FindName('ChkRecommendMove')
        $chkInspect = $window.FindName('ChkInspectMeta')
        # Charger config
        $txtVendors.Text = ($config.ExcludedVendors -join "`r`n")
        $txtProducts.Text = ($config.ExcludedProducts -join "`r`n")
        $txtFiles.Text = ($config.ExcludedFilePatterns -join "`r`n")
        $chkRecommend.IsChecked = $config.RecommendMoveByDefault
        $chkInspect.IsChecked = $config.InspectMetadata
        $obs = New-Object System.Collections.ObjectModel.ObservableCollection[object]
        $grid.ItemsSource = $obs
        # Capture $this pour utilisation dans les scriptblocks et fonctions locales
        $self = $this
        function Refresh-Grid([FileRecord[]]$data) {
            $obs.Clear()
            foreach ($d in $data) {
                $obs.Add([pscustomobject]@{
                    Selected = $d.Selected
                    FileName = $d.FileName
                    Kind = $d.Kind
                    SizeMB = $d.SizeMB
                    InUse = $d.InUse
                    Excluded = $d.Excluded
                    Manufacturer = $d.Manufacturer
                    ProductName = $d.ProductName
                    Reason = $d.Reason
                    SelectedAction = $d.SelectedAction.ToString()
                    Path = $d.Path
                }) | Out-Null
            }
        }
        function Update-Grid {
            if ($self.LastAnalysis.Count -eq 0) { return }
            $q = $txtSearch.Text
            $filtered = $self.LastAnalysis | Where-Object {
                ($chkShowExcluded.IsChecked -or -not $_.Excluded) -and (
                    [string]::IsNullOrWhiteSpace($q) -or $_.FileName -like "*${q}*" -or $_.ProductName -like "*${q}*" -or $_.Manufacturer -like "*${q}*"
                )
            }
            Refresh-Grid $filtered
        }
        $btnScan.Add_Click({
            $config.ExcludedVendors = @($txtVendors.Text -split "`r?`n" | Where-Object { $_ -ne '' })
            $config.ExcludedProducts = @($txtProducts.Text -split "`r?`n" | Where-Object { $_ -ne '' })
            $config.ExcludedFilePatterns = @($txtFiles.Text -split "`r?`n" | Where-Object { $_ -ne '' })
            $config.RecommendMoveByDefault = $chkRecommend.IsChecked
            $config.InspectMetadata = $chkInspect.IsChecked
            Write-Host "Analyse en cours…" -ForegroundColor Cyan
            $self.LastAnalysis = $self.PatchCleaner.FindOrphanedFiles($installerFolder, $config)
            Update-Grid
            Write-Host ("Analyse terminée — {0} éléments" -f $self.LastAnalysis.Count) -ForegroundColor Green
        })
        $txtSearch.Add_TextChanged({ Update-Grid })
        $chkShowExcluded.Add_Click({ Update-Grid })
        $btnSimulate.Add_Click({
            if ($self.LastAnalysis.Count -eq 0) { [System.Windows.MessageBox]::Show('Veuillez exécuter une analyse d''abord.'); return }
            $rootPath = Split-Path $PSScriptRoot -Parent
            $reportDir = Join-Path (Join-Path $rootPath "Resources") "Reports"
            if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }
            $reportPath = Join-Path $reportDir "InstallerCacheCleaner_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
            $report = $self.PatchCleaner.GenerateReport($self.LastAnalysis, $reportPath)
            [System.Windows.MessageBox]::Show("Rapport généré:`n$report") | Out-Null
            Start-Process $report
        })
        $btnMove.Add_Click({
            if ($self.LastAnalysis.Count -eq 0) { [System.Windows.MessageBox]::Show('Veuillez exécuter une analyse d''abord.'); return }
            $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
            $dlg.Description = 'Sélectionnez un dossier de quarantaine (déplacement).'
            $dlg.SelectedPath = $self.DefaultQuarantineFolder
            if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
            $destination = $dlg.SelectedPath
            $selected = @($grid.ItemsSource | Where-Object { $_.Selected -and $_.SelectedAction -eq 'Move' })
            if ($selected.Count -eq 0) { [System.Windows.MessageBox]::Show('Aucun élément sélectionné avec action Move.'); return }
            $map = @{}
            foreach ($s in $selected) { $map[$s.Path] = $s }
            $records = $self.LastAnalysis | Where-Object { $map.ContainsKey($_.Path) }
            $self.PatchCleaner.PerformActions($records, $destination, $self.WhatIf)
            $btnScan.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
        })
        $btnDelete.Add_Click({
            if ($self.LastAnalysis.Count -eq 0) { [System.Windows.MessageBox]::Show('Veuillez exécuter une analyse d''abord.'); return }
            $selected = @($grid.ItemsSource | Where-Object { $_.Selected -and $_.SelectedAction -eq 'Delete' })
            if ($selected.Count -eq 0) { [System.Windows.MessageBox]::Show('Aucun élément sélectionné avec action Delete.'); return }
            if ([System.Windows.MessageBox]::Show('Confirmez-vous la suppression définitive ?', 'Confirmation', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning) -ne [System.Windows.MessageBoxResult]::Yes) { return }
            $map = @{}
            foreach ($s in $selected) { $map[$s.Path] = $s }
            $records = $self.LastAnalysis | Where-Object { $map.ContainsKey($_.Path) }
            $self.PatchCleaner.PerformActions($records, $null, $self.WhatIf)
            $btnScan.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
        })
        $btnChangeToDelete.Add_Click({
            if ($self.LastAnalysis.Count -eq 0) { [System.Windows.MessageBox]::Show('Veuillez exécuter une analyse d''abord.'); return }
            if ([System.Windows.MessageBox]::Show('Confirmez-vous le changement de tous les Move en Delete ?', 'Confirmation', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning) -ne [System.Windows.MessageBoxResult]::Yes) { return }
            foreach ($record in $self.LastAnalysis) {
                if ($record.SelectedAction -eq [ActionType]::Move) {
                    $record.SelectedAction = [ActionType]::Delete
                }
            }
            Update-Grid
        })
        $btnSaveConfig.Add_Click({
            $config.ExcludedVendors = @($txtVendors.Text -split "`r?`n" | Where-Object { $_ -ne '' })
            $config.ExcludedProducts = @($txtProducts.Text -split "`r?`n" | Where-Object { $_ -ne '' })
            $config.ExcludedFilePatterns = @($txtFiles.Text -split "`r?`n" | Where-Object { $_ -ne '' })
            $config.RecommendMoveByDefault = $chkRecommend.IsChecked
            $config.InspectMetadata = $chkInspect.IsChecked
            $self.PatchCleaner.ConfigProvider.SaveConfig($config)
            [System.Windows.MessageBox]::Show("Configuration sauvegardée :`n$($self.PatchCleaner.ConfigProvider.ConfigPath)") | Out-Null
        })
        $null = $window.ShowDialog()
    }
}

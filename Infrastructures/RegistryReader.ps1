# Lit les infos du registre Windows Installer
class RegistryReader {
    [pscustomobject[]] GetInUseInstallerFiles() {
        $base = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData'
        $inUse = @()
        if (-not (Test-Path $base)) { return $inUse }
        foreach ($sid in Get-ChildItem $base -ErrorAction SilentlyContinue) {
            $productsKey = Join-Path $sid.PSPath 'Products'
            if (Test-Path $productsKey) {
                foreach ($p in Get-ChildItem $productsKey -ErrorAction SilentlyContinue) {
                    $props = Join-Path $p.PSPath 'InstallProperties'
                    if (Test-Path $props) {
                        $installProps = Get-ItemProperty -Path $props -ErrorAction SilentlyContinue
                        $lp = $null
                        if ($installProps.PSObject.Properties.Name -contains 'LocalPackage') {
                            $lp = $installProps.LocalPackage
                        }
                        $dn = $null
                        if ($installProps.PSObject.Properties.Name -contains 'DisplayName') {
                            $dn = $installProps.DisplayName
                        }
                        $pub = $null
                        if ($installProps.PSObject.Properties.Name -contains 'Publisher') {
                            $pub = $installProps.Publisher
                        }
                        if ($lp -and -not [string]::IsNullOrEmpty($lp) -and (Test-Path -LiteralPath $lp)) {
                            $gi = Get-Item -LiteralPath $lp -ErrorAction SilentlyContinue
                            if ($gi) {
                                $kind = if ($lp -like '*.msi') { 'MSI' } else { [IO.Path]::GetExtension($lp).TrimStart('.') }
                                $inUse += [pscustomobject]@{
                                    Path = $gi.FullName
                                    Kind = $kind
                                    Source = 'Registry'
                                    ProductCode = $p.PSChildName
                                    PatchCode = $null
                                    ProductName = $dn
                                    Publisher = $pub
                                }
                            }
                        }
                    }
                }
            }
            $patchesKey = Join-Path $sid.PSPath 'Patches'
            if (Test-Path $patchesKey) {
                foreach ($pc in Get-ChildItem $patchesKey -ErrorAction SilentlyContinue) {
                    $patchProps = Get-ItemProperty -Path $pc.PSPath -ErrorAction SilentlyContinue
                    $lp = $null
                    if ($patchProps.PSObject.Properties.Name -contains 'LocalPackage') {
                        $lp = $patchProps.LocalPackage
                    }
                    $dn = $null
                    if ($patchProps.PSObject.Properties.Name -contains 'DisplayName') {
                        $dn = $patchProps.DisplayName
                    }
                    $pub = $null
                    if ($patchProps.PSObject.Properties.Name -contains 'MoreInfoURL') {
                        $pub = $patchProps.MoreInfoURL
                    }
                    if ($lp -and -not [string]::IsNullOrEmpty($lp) -and (Test-Path -LiteralPath $lp)) {
                        $gi = Get-Item -LiteralPath $lp -ErrorAction SilentlyContinue
                        if ($gi) {
                            $kind = if ($lp -like '*.msp') { 'MSP' } else { [IO.Path]::GetExtension($lp).TrimStart('.') }
                            $inUse += [pscustomobject]@{
                                Path = $gi.FullName
                                Kind = $kind
                                Source = 'Registry'
                                ProductCode = $null
                                PatchCode = $pc.PSChildName
                                ProductName = $dn
                                Publisher = $pub
                            }
                        }
                    }
                }
            }
        }
        return $inUse | Group-Object Path | ForEach-Object { $_.Group | Select-Object -First 1 }
    }
}

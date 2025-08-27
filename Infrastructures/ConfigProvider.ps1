# Charge/enregistre la configuration JSON
class ConfigProvider {
    hidden [hashtable] $DefaultConfig = @{
        ExcludedVendors = @('^Adobe$','Adobe Systems','Adobe Inc')
        ExcludedProducts = @('Acrobat','Reader')
        ExcludedFilePatterns = @('^.*\\Adobe.*$')
        RecommendMoveByDefault = $true
        InspectMetadata = $true
    }
    hidden [string] $ConfigPath

    ConfigProvider() {
        $rootPath = Split-Path $PSScriptRoot -Parent
        $this.ConfigPath = Join-Path $rootPath "Resources\Configs\InstallerCacheCleaner.config.json"
    }

    [hashtable] GetConfig() {
        if (Test-Path $this.ConfigPath) {
            try {
                $jsonObj = Get-Content $this.ConfigPath -Raw | ConvertFrom-Json
                return $this.ConvertToHashtable($jsonObj)
            } catch { }
        }
        return $this.DefaultConfig
    }

    [void] SaveConfig([hashtable]$config) {
        $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $this.ConfigPath
    }

    hidden [hashtable] ConvertToHashtable([psobject]$object) {
        $ht = @{}
        foreach ($prop in $object.PSObject.Properties) {
            $ht[$prop.Name] = $prop.Value
        }
        return $ht
    }
}

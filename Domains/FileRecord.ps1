# Classe représentant un fichier (avec état : utilisé/orphelin)
class FileRecord {
    [string] $Path
    [string] $FileName
    [string] $Kind
    [long] $SizeBytes
    [double] $SizeMB
    [bool] $InUse
    [bool] $Excluded
    [string] $Reason
    [string] $Manufacturer
    [string] $ProductName
    [string] $ProductVersion
    [ActionType] $RecommendedAction
    [ActionType] $SelectedAction
    [bool] $Selected = $false

    FileRecord([System.IO.FileInfo]$file, [bool]$inUse, [bool]$excluded, [string]$reason, [hashtable]$meta, [ActionType]$recommended) {
        $this.Path = $file.FullName
        $this.FileName = $file.Name
        $this.Kind = ($file.Extension -replace '^\.', '').ToUpperInvariant()
        $this.SizeBytes = $file.Length
        $this.SizeMB = [Math]::Round($file.Length / 1MB, 2)
        $this.InUse = $inUse
        $this.Excluded = $excluded
        $this.Reason = $reason
        $this.Manufacturer = $meta.Manufacturer
        $this.ProductName = $meta.ProductName
        $this.ProductVersion = $meta.ProductVersion
        $this.RecommendedAction = $recommended
        $this.SelectedAction = $recommended
        $this.Selected = ($recommended -ne [ActionType]::None)
    }
}

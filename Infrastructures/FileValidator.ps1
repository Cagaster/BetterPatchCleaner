# Vérifie l’existence et l’état des fichiers, inclut extraction métadonnées
class FileValidator {
    static [hashtable] GetMsiMetadata([string]$path) {
        try {
            $installer = New-Object -ComObject WindowsInstaller.Installer
            $db = $installer.OpenDatabase($path, 0)
            $q = 'SELECT Value FROM Property WHERE Property = ?'
            $view = $db.OpenView($q)
            $props = @{}

            foreach ($name in 'ProductName','Manufacturer','ProductVersion') {
                $record = $installer.CreateRecord(1)
                $record.StringData(1) = $name
                $view.Execute($record)
                $rec = $view.Fetch()
                if ($rec) { $props[$name] = $rec.StringData(1) }
                $view.Close()
                $view = $db.OpenView($q)
            }

            return $props
        } catch {
            return @{ ProductName=$null; Manufacturer=$null; ProductVersion=$null }
        }
    }

    static [hashtable] GetMspMetadata([string]$path) {
        try {
            $installer = New-Object -ComObject WindowsInstaller.Installer
            $db = $installer.OpenDatabase($path, 0)
            $summary = $db.SummaryInformation
            return @{
                ProductName = $summary.Property(3)  # Subject
                Manufacturer = $summary.Property(4) # Author
                ProductVersion = $null
            }
        } catch {
            return @{ ProductName=$null; Manufacturer=$null; ProductVersion=$null }
        }
    }
}

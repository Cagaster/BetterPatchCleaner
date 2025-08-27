# Résultat structuré d’une opération
class CleanResult {
    [bool] $Success
    [string] $Message
    [FileRecord] $FileRecord
    [ActionType] $ActionTaken

    CleanResult([bool]$success, [string]$message, [FileRecord]$fileRecord, [ActionType]$action) {
        $this.Success = $success
        $this.Message = $message
        $this.FileRecord = $fileRecord
        $this.ActionTaken = $action
    }
}

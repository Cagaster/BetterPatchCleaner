# Génère rapport HTML
class ReportGenerator {
    [string] NewHtmlReport([FileRecord[]]$records, [string]$path) {
        $css = @'
body{font-family:Segoe UI,Arial,sans-serif;margin:24px}
h1{font-size:20px}
table{border-collapse:collapse;width:100%;margin-top:12px}
th,td{border:1px solid #ddd;padding:8px}
th{background:#f4f6f8;text-align:left;cursor:pointer;}
tr:nth-child(even){background:#fafafa}
.tag{padding:2px 6px;border-radius:4px;border:1px solid #ccc;font-size:12px}
.ok{background:#e6ffed;border-color:#b7f5c1}
.warn{background:#fff8e1;border-color:#ffe28a}
.bad{background:#ffecec;border-color:#f5b7b1}
'@
        $js = @'
function sortTable(n) {
  var table = document.getElementById("reportTable");
  var headers = table.querySelectorAll('th');
  var currentDir = headers[n].getAttribute('data-sort-dir');
  var dir = currentDir === 'asc' ? 'desc' : 'asc';
  headers.forEach(function(h) { h.removeAttribute('data-sort-dir'); });
  headers[n].setAttribute('data-sort-dir', dir);
  var tbody = table.tBodies[0];
  var rows = Array.from(tbody.rows);
  rows.sort(function(a, b) {
    var xVal = a.cells[n].getAttribute('data-sort-value');
    var yVal = b.cells[n].getAttribute('data-sort-value');
    var x = xVal !== null ? parseFloat(xVal) : a.cells[n].textContent.trim().toLowerCase();
    var y = yVal !== null ? parseFloat(yVal) : b.cells[n].textContent.trim().toLowerCase();
    if (!isNaN(x) && !isNaN(y)) {
      return dir === 'asc' ? x - y : y - x;
    } else {
      if (dir === 'asc') {
        return x.localeCompare(y);
      } else {
        return y.localeCompare(x);
      }
    }
  });
  tbody.innerHTML = '';
  rows.forEach(function(row) { tbody.appendChild(row); });
}
'@
        $sortedRecords = $records | Sort-Object {
            $action = $_.RecommendedAction
            if ($action -match '(?i)supprimer|delete|remove') { 0 }
            elseif ($action -match '(?i)déplacer|move|vérifier|review|check|examiner') { 1 }
            else { 2 }
        }
        $rows = ($sortedRecords | ForEach-Object {
            $cls = if ($_.InUse) { 'ok' } elseif ($_.Excluded) { 'warn' } else { 'bad' }
            $status = if ($_.InUse) {'En cours'} elseif ($_.Excluded) {'Exclu'} else {'Orphelin'}
            $action = $_.RecommendedAction
            $display_action = switch -regex ($action) {
                '(?i)none' { 'Aucune' }
                '(?i)move' { 'Déplacer' }
                '(?i)delete|remove' { 'Supprimer' }
                '(?i)review|check|examiner' { 'Vérifier' }
                default { $action }
            }
            $action_cls = if ($action -match '(?i)supprimer|delete|remove') { 'bad' }
                          elseif ($action -match '(?i)déplacer|move|vérifier|review|check|examiner') { 'warn' }
                          else { 'ok' }
            $action_priority = if ($action -match '(?i)supprimer|delete|remove') { 0 }
                               elseif ($action -match '(?i)déplacer|move|vérifier|review|check|examiner') { 1 }
                               else { 2 }
            $size_mb = $_.SizeMB
            $formatted_size = $size_mb.ToString('N2') + ' MB'
            $sort_size = $size_mb.ToString([System.Globalization.CultureInfo]::InvariantCulture)
            "<tr><td>$([System.Web.HttpUtility]::HtmlEncode($_.FileName))</td><td>$($_.Kind)</td><td data-sort-value=`"$sort_size`">$formatted_size</td><td><span class='tag $cls'>$([System.Web.HttpUtility]::HtmlEncode($status))</span></td><td>$([System.Web.HttpUtility]::HtmlEncode($_.Manufacturer))</td><td>$([System.Web.HttpUtility]::HtmlEncode($_.ProductName))</td><td>$([System.Web.HttpUtility]::HtmlEncode($_.Reason))</td><td data-sort-value=`"$action_priority`"><span class='tag $action_cls'>$([System.Web.HttpUtility]::HtmlEncode($display_action))</span></td></tr>"
        }) -join "`n"
        $html = @"
<!DOCTYPE html>
<html lang='fr'>
<head>
<meta charset='utf-8'/>
<title>Rapport InstallerCacheCleaner</title>
<style>$css</style>
</head>
<body>
<h1>Rapport InstallerCacheCleaner — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</h1>
<p>Dossier analysé : <strong>$($records[0].Path | Split-Path -Parent)</strong></p>
<p>Nombre d'éléments analysés : <strong>$($records.Count)</strong></p>
<table id='reportTable'>
<thead><tr><th onclick='sortTable(0)'>Nom</th><th onclick='sortTable(1)'>Type</th><th onclick='sortTable(2)'>Taille</th><th onclick='sortTable(3)'>État</th><th onclick='sortTable(4)'>Éditeur</th><th onclick='sortTable(5)'>Produit</th><th onclick='sortTable(6)'>Motif</th><th onclick='sortTable(7)'>Action recommandée</th></tr></thead>
<tbody>
$rows
</tbody>
</table>
<script>
$js
</script>
</body>
</html>
"@
        $html | Out-File -FilePath $path -Encoding utf8
        return $path
    }
}

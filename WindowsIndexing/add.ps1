# https://stackoverflow.com/a/70761884/166231
# [wsearch-add-rule.ps1]
# Source: https://stackoverflow.com/questions/13390514/how-to-add-a-location-to-windows-7-8-search-index-using-batch-or-vbscript/13454571#13454571
Add-Type -path ".\Microsoft.Search.Interop.dll"
$sm = New-Object Microsoft.Search.Interop.CSearchManagerClass 
$cat = $sm.GetCatalog("SystemIndex")
$csm = $cat.GetCrawlScopeManager()
$csm.AddUserScopeRule("file:///C:\*\.git\", $1, $0, $null)
$csm.AddUserScopeRule("file:///C:\*\obj\", $1, $0, $null)
$csm.SaveAll()
# [wsearch-list-rules.ps1]
# Source: https://powertoe.wordpress.com/2010/05/17/powershell-tackles-windows-desktop-search/
Add-Type -path "Microsoft.Search.Interop.dll"
$sm = New-Object Microsoft.Search.Interop.CSearchManagerClass 
$cat = $sm.GetCatalog("SystemIndex")
$csm = $cat.GetCrawlScopeManager()
$scopes = @()
$begin = $true
[Microsoft.Search.Interop.CSearchScopeRule]$scope = $null
$enum = $csm.EnumerateScopeRules() 
while ($scope -ne $null -or $begin) {
     $enum.Next(1,[ref]$scope,[ref]$null)
     $begin = $false
     $scopes += $scope
}
$scopes|ogv
Set-Alias e code
Set-Alias ex explorer

# https://www.hanselman.com/blog/my-ultimate-powershell-prompt-with-oh-my-posh-and-the-windows-terminal
# https://www.hanselman.com/blog/a-nightscout-segment-for-ohmyposh-shows-my-realtime-blood-sugar-readings-in-my-git-prompt
#   Second video is live coding of new segment, might have to do that to resolve my to do list
#
# 1. Install PowerShell (.NET Core-powered cross-platform PowerShell)
#       https://www.microsoft.com/en-us/p/powershell/9mz1snwt0n5d?SilentAuth=1&wa=wsignin1.0&WT.mc_id=-blog-scottha&activetab=pivot:overviewtab
# 2. Install Oh My Posh
#       https://ohmyposh.dev/docs/installation/windows
#       Add `oh-my-posh --init --shell pwsh --config ~/ohmyposhv3-2.json | Invoke-Expression` to profile.ps1
#       Make/modify your own prompt and save to user/ohmyposhv3-2.json
# 3. Install Terminal-Icons
#       Install-Module -Name Terminal-Icons -Repository PSGallery
#       Add `Import-Module -Name Terminal-Icons` to profile.ps1
# 4. Install posh-git (tab completion)
#       Install-Module posh-git -Scope CurrentUser -AllowPrerelease -Force
#       https://github.com/dahlbyk/posh-git
#       Add `$env:POSH_GIT_ENABLED = $true` to profile to make sure the posh-git 'tab completion' is working, https://github.com/JanDeDobbeleer/oh-my-posh/issues/126#issuecomment-955198039
#       Add code from GitTabExpansion.KAT.ps1 into GitTabExpansion.ps1 as noted in file

$env:POSH_GIT_ENABLED = $true

Import-Module -Name Terminal-Icons
oh-my-posh --init --shell pwsh --config ~/ohmyposhv3-2.json | Invoke-Expression
Import-Module posh-git

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
           [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# POC of calling C# assemblies from script (pretty slow)
Add-Type -Path "c:\btr\assemblies\btr.evolution.core.dll"

# Sample Command segment
#        {
#          "background": "#906cff",
#          "foreground": "#100e23",
#          "type": "command",
#          "style": "diamond",
#          "leading_diamond": "\ue0b6",
#          "trailing_diamond": "\ue0b0",
#          "properties": {
#            "shell": "powershell",
#            "command": "fooSharp('terry-aney')"
#          }
#        },

function script:barSharp() {
    # Sample posh-git util calls
    cd 'c:\btr\katapp'
    $gitStatus = Get-GitStatus
    cd 'c:\btr\evolution'
    return $gitStatus.AheadBy
}
function script:fooSharp($dataName) {
    # Sample C# method calls...
    [BTR.Evolution.Core.ExtensionMethods]::ToInputName( $dataName )
}

# Helper functions to integrate Visual Studio Command Line Prompt settings
function vs2019 {
  param(
      [string]$edition,
      [string]$basePath = "",
      [switch]$noWeb = $false
  )

  IntegrateVisualStudioCommandLine -edition:$edition -version:"2019" -basePath:$basePath -noWeb:$noWeb
}

function vs2022 {
  param(
      [string]$edition,
      [string]$basePath = "",
      [switch]$noWeb = $false
  )
  IntegrateVisualStudioCommandLine -edition:$edition -version:"2022" -basePath:$basePath -noWeb:$noWeb
}

function IntegrateVisualStudioCommandLine {
  param(
      [string]$version,
      [string]$edition,
      [string]$basePath = "",
      [switch]$noWeb = $false
  )

  $folder = Split-Path $PSCommandPath
  $script = Join-Path $folder "vs.ps1"
  & $script -edition:$edition -version:$version -basePath:$basePath -noWeb:$noWeb
}

# Helper functions for KAT git alias tab completion
function script:gitRefHints($offset) {
    $refHints = New-Object System.Collections.Generic.List[string]

    if ( $offset -eq 0)
    {
        $refHints.Add("HEAD~")
    }
    $refHints.Add("HEAD~~")
    if ( $offset -eq 1)
    {
        $refHints.Add("HEAD~~")
    }
    $refHints.Add("HEAD~N")
    $refHints
}

function script:gitTracked($filter) {
    
    if ( $global:gitVersion -eq "0.7.3" ) 
    {
        $git = git ls-files | Where-Object { $_ -like "$filter*" }
    }
    else 
    {
        $git = Invoke-Utf8ConsoleCommand { (git ls-files) } |
            Where-Object { $_ -like "$filter*" } |
            quoteStringWithSpecialChars
    }    

    return $git
}
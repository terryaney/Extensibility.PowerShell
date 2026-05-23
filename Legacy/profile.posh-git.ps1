# https://github.com/dahlbyk/posh-git#installing-posh-git-via-powershellget-on-linux-macos-and-windows (need to run in Powershell)

Import-Module posh-git
. (Resolve-Path ~/OneDrive/Documents/WindowsPowershell/profile.posh-git.promptsettings.ps1)

Set-Alias e code
Set-Alias ex explorer

set-content Function:prompt {        
    # Start with a blank line, for breathing room :1)
    Write-Host ""

    # Reset the foreground color to default
    if ( $gitVersion -eq "0.7.3" ) {
        $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor
    }
    else {
        $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultColor.ForegroundColor
    }

    # Write ERR for any PowerShell errors
    if ($Error.Count -ne 0) {
        Write-Host " " -NoNewLine
        Write-Host "$($PromptSettings.BeforeErrorText)ERR " -NoNewLine -BackgroundColor DarkRed -ForegroundColor White
        $Error.Clear()
    }

    # Write non-zero exit code from last launched process
    if ($LASTEXITCODE -ne "") {
        Write-Host " " -NoNewLine
        Write-Host "$($PromptSettings.BeforeErrorText)$LASTEXITCODE " -NoNewLine -BackgroundColor DarkRed -ForegroundColor White
        $LASTEXITCODE = ""
    }
    
    # Write any custom prompt environment (f.e., from vs2017.ps1)
    if (get-content variable:\PromptEnvironment -ErrorAction Ignore) {
        Write-Host " " -NoNewLine
        Write-Host $PromptEnvironment -NoNewLine -BackgroundColor DarkMagenta -ForegroundColor White
        Write-Host " " -NoNewLine
    }
    
    # Write the current kubectl context
    if ((Get-Command "kubectl" -ErrorAction Ignore) -ne $null) {
        $currentContext = (& kubectl config current-context 2> $null)
        if ($Error.Count -eq 0) {
            Write-Host " " -NoNewLine
            Write-Host $PromptSettings.BeforeKubernetesText -NoNewLine -BackgroundColor DarkGray -ForegroundColor Green
            Write-Host "$currentContext " -NoNewLine -BackgroundColor DarkGray -ForegroundColor White
        }
        else {
            $Error.Clear()
        }
    }
    
    # Write the current public cloud Azure CLI subscription
    # NOTE: You will need sed from somewhere (for example, from Git for Windows)
    if (Test-Path ~/.azure/clouds.config) {
        $currentSub = & sed -nr "/^\[AzureCloud\]/ { :l /^subscription[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" ~/.azure/clouds.config
        if ($null -ne $currentSub) {
            $currentAccount = (Get-Content ~/.azure/azureProfile.json | ConvertFrom-Json).subscriptions | Where-Object { $_.id -eq $currentSub }
            if ($null -ne $currentAccount) {
                Write-Host " " -NoNewLine
                Write-Host $PromptSettings.BeforeAzureText -NoNewLine -BackgroundColor DarkCyan -ForegroundColor Yellow
                Write-Host "$($currentAccount.name) " -NoNewLine -BackgroundColor DarkCyan -ForegroundColor White
            }
        }
    }
    
    if ((Get-Command "Get-GitDirectory" -ErrorAction Ignore) -ne $null) {
        $gitDir = Get-GitDirectory

        if ($gitDir -ne $null) {
            $currentPath = ([string]$pwd);
            
            $testPath = $currentPath.ToLower()
            $testGitPath = $gitDir.ToLower()

            $nonRepo =  ( $testPath.StartsWith("c:\btr\evolution\websites") -and $testGitPath -eq "c:\btr\evolution\.git" ) -or
                        ( $testPath.StartsWith("c:\btr\evolution\btr.evolution.hangfire.jobs") -and $testGitPath -eq "c:\btr\evolution\.git" ) -or
                        ( $testPath.StartsWith("c:\btr.legacy\madhatter.4.1\websites") -and $testGitPath -eq "c:\btr.legacy\madhatter.4.1\.git" ) -or
                        ( $testPath.StartsWith("c:\btr.legacy\madhatter.4.5\websites.madhatteradmin\clients") -and $testGitPath -eq "c:\btr.legacy\madhatter.4.5\.git" ) -or
                        ( $testPath.StartsWith("c:\btr.legacy\tahiti\btr.websites.madhatter\clients") -and $testGitPath -eq "c:\btr.legacy\tahiti\.git" )

            if ( !$nonRepo ) {
                if ( $gitVersion -eq "0.7.3" ) {
                    Write-Host " " -NoNewLine
                }

                Write-Host (Write-VcsStatus) -NoNewLine
                $title = Get-GitTitleDescription

                if ( $gitVersion -eq "0.7.3" ) {
                    $beforeOriginal = $GitPromptSettings.BeforeText
                }
                else {
                    $beforeOriginal = $GitPromptSettings.BeforeStatus.Text
                }

                $resetGitPrompt = 0

                Get-ChildItem -Directory -Filter Shared* |
                    ForEach-Object {
                        cd $_.FullName

                        if ( $gitVersion -eq "0.7.3" ) {
                            $GitPromptSettings.BeforeText = "$($beforeOriginal)$($_.Name):"
                        }
                        else {
                            $GitPromptSettings.BeforeStatus.Text = "$($beforeOriginal)$($_.Name):"
                        }
                        Write-Host " " -NoNewLine
                        Write-Host (Write-VcsStatus) -NoNewLine
                        
                        cd ..

                        $resetGitPrompt = 1
                    }

                # If there were shared repos...better put path on next line
                if ($resetGitPrompt -eq 1) {
                    # Reset the GitStatus to current repo
                    $Global:GitStatus = Get-GitStatus

                    if ( $gitVersion -eq "0.7.3" ) {
                        $GitPromptSettings.BeforeText = $beforeOriginal
                    }
                    else {
                        $GitPromptSettings.BeforeStatus.Text = $beforeOriginal
                    }
                }

                Write-Host ""
                $WindowTitleSupported = $true
                if (Get-Module NuGet) {
                    $WindowTitleSupported = $false
                }

                if ($WindowTitleSupported) {
                    $Host.UI.RawUI.WindowTitle = $title;
                }
            }
        }
    }
  
    # Write the current directory, with home folder normalized to ~
    $currentPath = (get-location).Path.replace($home, "~")
    $idx = $currentPath.IndexOf("::")
    if ($idx -gt -1) { $currentPath = $currentPath.Substring($idx + 2) }

    Write-Host " " -NoNewLine
    Write-Host "$($PromptSettings.BeforeDirectoryText)" -NoNewLine -BackgroundColor DarkGreen -ForegroundColor White
    Write-Host "$currentPath " -NoNewLine -BackgroundColor DarkGreen -ForegroundColor White

    # Reset LASTEXITCODE so we don't show it over and over again
    $global:LASTEXITCODE = 0

    # Write one + for each level of the pushd stack
    if ((get-location -stack).Count -gt 0) {
      Write-Host " " -NoNewLine -ForegroundColor Cyan
      Write-Host $PromptSettings.BeforeDirectoryMemoryText -NoNewLine -ForegroundColor Cyan    
      Write-Host (("+" * ((get-location -stack).Count))) -NoNewLine -ForegroundColor Cyan
    }

    # Newline
    Write-Host ""

    # Determine if the user is admin, so we color the prompt green or red
    $isAdmin = $false
    $isDesktop = ($PSVersionTable.PSEdition -eq "Desktop")

    if ($isDesktop -or $IsWindows) {
        $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $windowsPrincipal = new-object 'System.Security.Principal.WindowsPrincipal' $windowsIdentity
        $isAdmin = $windowsPrincipal.IsInRole("Administrators") -eq 1
    } else {
        $isAdmin = ((& id -u) -eq 0)
    }

    # Change from Brad's
    # if ($isAdmin) { $color = "Red"; }
    # else { $color = "Green"; }

    $color = "Green";

    if ($isAdmin) {
        $color = "Red";
        Write-Host " [Admin]" -NoNewLine -ForegroundColor $color
        $color = "Green";
    }

    # Write PS> for desktop PowerShell, pwsh> for PowerShell Core
    if ($isDesktop) {
        Write-Host " PS>" -NoNewLine -ForegroundColor $color
    }
    else {
        Write-Host " pwsh>" -NoNewLine -ForegroundColor $color
    }

    # Always have to return something or else we get the default prompt
    return " "    
}

function Get-GitTitleDescription {
    $repoName = Split-Path -Leaf (Split-Path $GitStatus.GitDir)
    $branch = $GitStatus.Branch

    $title = $repoName
    $title += ":"
    $title += $branch
    $title += " "

    if ($GitStatus.BehindBy -gt 0) {
        # We are behind remote
        $title += "(<$($GitStatus.BehindBy))"
    }
    if ($GitStatus.AheadBy -gt 0) {
        $title += "(+$($GitStatus.AheadBy))"
    }
    if ($GitPromptSettings.EnableFileStatus -and ($GitStatus.HasIndex -or $GitStatus.HasWorking)) {
        $title += "["
    }
    if ($GitPromptSettings.EnableFileStatus -and $GitStatus.HasIndex) {
        $title += " +$($GitStatus.Index.Added.Count) ~$($GitStatus.Index.Modified.Count) <$($GitStatus.Index.Deleted.Count)"

        if ($GitStatus.Index.Unmerged) {
            $title += " !$($GitStatus.Index.Unmerged.Count)"
        }

        if($GitStatus.HasWorking) {
            $title += $GitPromptSettings.DelimStatus.Text
        }
    }
    if($GitPromptSettings.EnableFileStatus -and $GitStatus.HasWorking) {
        $title += " +$($GitStatus.Working.Added.Count) ~$($GitStatus.Working.Modified.Count) <$($GitStatus.Working.Deleted.Count)"

        if ($GitStatus.Working.Unmerged) {
            $title += " !$($GitStatus.Working.Unmerged.Count)"
        }
    }
    if ($GitStatus.HasUntracked) {
        $title += $GitPromptSettings.UntrackedText
    }
    if ($GitPromptSettings.EnableFileStatus -and ($GitStatus.HasIndex -or $GitStatus.HasWorking)) {
        $title += " ]"
    }
    return $title
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
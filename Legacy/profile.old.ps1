# My custom prompt, based on:
#
# 1. https://bradwilson.io/blog/prompt/powershell
# 2. https://ohmyposh.dev/docs
# 3. https://www.hanselman.com/blog/my-ultimate-powershell-prompt-with-oh-my-posh-and-the-windows-terminal
#       - Live coding of new segment: https://www.hanselman.com/blog/a-nightscout-segment-for-ohmyposh-shows-my-realtime-blood-sugar-readings-in-my-git-prompt
# 4. https://github.com/dahlbyk/posh-git
#
# Ended up writing my own prompt (which behaves/looks like OMP) following Brad Wilson's pattern because of 
# 'Write-SharedGitSegments' and displaying git status for any nested Shared* repositories.  It was too custom 
# for OMP to consider coding. Here is discussion/issue: https://github.com/JanDeDobbeleer/oh-my-posh/discussions/2144
#
# Installation requirements
# 1. Install PowerShell (.NET Core-powered cross-platform PowerShell)
#       https://www.microsoft.com/en-us/p/powershell/9mz1snwt0n5d?SilentAuth=1&wa=wsignin1.0&WT.mc_id=-blog-scottha&activetab=pivot:overviewtab
# 2. Install Terminal-Icons
#       Install-Module -Name Terminal-Icons -Repository PSGallery
#       Add `Import-Module -Name Terminal-Icons` to profile.ps1
# 3. Install posh-git (tab completion)
#       Install-Module posh-git -Scope CurrentUser -AllowPrerelease -Force
#       https://github.com/dahlbyk/posh-git
#       Add `$GitPromptSettings.EnableStashStatus = $true` to profile.ps1 to make sure the posh-git 'git status' pulls stash count as well
# 4. (OPTIONAL) Install git configuration
#       Read the .gitconfig.README.md to file descriptions and instructions on how to enhance posh-git's GitTabExpansion.ps1 file for custom tab completion requirements

Import-Module -Name Terminal-Icons

Import-Module posh-git
$GitPromptSettings.EnableStashStatus = $true

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
           [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

Set-Alias e code
Set-Alias ex explorer

set-content Function:prompt {
    # Custom prompt following https://bradwilson.io/blog/prompt/powershell  
    try
    {
        # Start with a blank line, for breathing room :1)
        Write-Host ""

        # These can be cleared out by segments before callin gthe ExitSegment
        $ErrorCount = $Error.Count;
        $LastEC = $LASTEXITCODE;

        Write-SharedGitSegments "#D3D3D3" "TRANSPARENT"

        $isAdmin = Get-IsAdmin

        $segmentBackground = "#ff479c";

        if ( $isAdmin ) {
            $segmentBackground = "#ffffff";
        }

        Write-Diamond $segmentBackground;
        $segmentBackground = Write-SessionSegment $segmentBackground "#ffffff" "TRANSPARENT" $isAdmin;
        $segmentBackground = Write-FolderSegment $segmentBackground "#ff479c";
        Write-Powerline "TRANSPARENT" "$segmentBackground";

        $segmentBackground = "TRANSPARENT";
        $segmentBackground = Write-VSSegment $segmentBackground "#8b008b";
        $segmentBackground = Write-DotNetSegment $segmentBackground "#6CA35E"
        $segmentBackground = Write-KubernetesSegment $segmentBackground "#63666A"
        $segmentBackground = Write-AzureSegment $segmentBackground "#0080FF"
        $segmentBackground = Write-GitSegment $segmentBackground "#fffb38" "#193549"
        $segmentBackground = Write-HealthSegment $ErrorCount $LastEC $segmentBackground "#2e9599" "#f1184c";
        $segmentBackground = Write-PromptSegment $segmentBackground "#FFFFFF" "#000000";
        Write-Powerline "TRANSPARENT" "$segmentBackground";
        
        Write-WindowTitle

        # Reset LASTEXITCODE so we don't show it over and over again
        $global:LASTEXITCODE = 0
        $Error.Clear()

        # Always have to return something or else we get the default prompt
        return " "
    }
    catch {
        Write-Debug "Custom prompt failed with error: $_"
    }
}

# Helper functions for Custom Prompt Segments following ideas from https://ohmyposh.dev/docs
function Write-SessionSegment {
	param(
		[Parameter(Mandatory = $true, Position = 0)] [string] $PrevBackground,
		[Parameter(Mandatory = $true, Position = 1)] [string] $Background,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Foreground,
		[Parameter(Mandatory = $true, Position = 3)] [switch] $IsAdmin
	)

    # https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/src/segments/session.go

    if ( $IsAdmin ) {
        Write-Powerline $Background $PrevBackground
        # 26a1 - Lightening
        # fb8a - Skull
        Write-HostColor " $([char]0xfb8a) Admin " $Background $Foreground

        return $Background
    }

    return $PrevBackground
}

function Write-FolderSegment {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [string] $PrevBackground,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Background
	)

    # https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/src/segments/path.go

    Write-Powerline $Background $PrevBackground

    # Write the current directory, with home folder normalized to home icon
    $currentPath = (get-location).Path.replace($home, "$([char]0xf7db)")
    $idx = $currentPath.IndexOf("::")
    if ($idx -gt -1) { $currentPath = $currentPath.Substring($idx + 2) }

    $pathParts = $currentPath -split "\\";
    
    # Home/Drive
    Write-HostColor " $($pathParts[0])\" $Background "#FFFFFF"
    # Folder Iconss for middle path parts
    for($i=1; $i -le $pathParts.Length - 2; $i++)
    {
        Write-HostColor "$([char]0xe5ff)\" $Background "#FFFFFF"
    }
    # Last part (if more than just Home/Drive)
    if ( $pathParts.Length -gt 1 ) {
        Write-HostColor "$($pathParts[$pathParts.Length - 1])" $Background "#FFFFFF"
    }
    Write-HostColor " " $Background "#FFFFFF"

    # Full path...
    # Write-HostColor " $currentPath " $Background "#FFFFFF"

    # Write level of the pushd stack
    $stackLocation = (get-location -stack).Count;
    if ($stackLocation -gt 0) {
        Write-HostColor "$([char]0xe5ff)+$stackLocation " $Background "#FFFFFF"
    }

    return $Background;
}

function Write-VSSegment {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [string] $PrevBackground,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Background
	)

    if (get-content variable:\VSPromptEnvironment -ErrorAction Ignore) {
        Write-Powerline $Background $PrevBackground

        # $([char]0xfb0f)
        Write-HostColor " vs$VSPromptEnvironment " $Background "#FFFFFF"
        return $Background;
    }
    return $PrevBackground;
}

function Write-DotNetSegment {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [string] $PrevBackground,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Background
	)

    # https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/src/segments/dotnet.go
    if (($null -ne (Get-Command "dotnet" -ErrorAction Ignore)) -and (hasLanguageFiles "*.sln,*.csproj")) {
        Write-Powerline $Background $PrevBackground
        $BackgroundColor = ConvertFrom-Hex $Background;

        $dotNetVersion = (& dotnet --version)
        Write-HostColor " $([char]0xfb0f) $dotNetVersion " $Background "#FFFFFF"
        return $Background;
    }
    return $PrevBackground;
}

function Write-KubernetesSegment {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [string] $PrevBackground,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Background
	)

    # Write the current kubectl context
    if ((Get-Command "kubectl" -ErrorAction Ignore) -ne $null) {
        $prevEC = $LASTEXITCODE;
        $currentContext = (& kubectl config current-context 2> $null)

        if ($Error.Count -eq 0 -and $global:LASTEXITCODE -ne 1 ) {
            Write-Powerline $Background $PrevBackground

            Write-HostColor " $([char]0xfd31)" $Background "#C7EA46"
            Write-HostColor " $currentContext " $Background "#FFFFFF"

            return $Background;
        }
        else {
            $Error.Clear()
            $global:LASTEXITCODE = $prevEC;
        }
    }

    return $PrevBackground;
}

function Write-AzureSegment {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [string] $PrevBackground,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Background
	)

    # Write the current public cloud Azure CLI subscription
    # NOTE: You will need sed from somewhere (for example, from Git for Windows)
    if (Test-Path ~/.azure/clouds.config) {
        $currentSub = & sed -nr "/^\[AzureCloud\]/ { :l /^subscription[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" ~/.azure/clouds.config
        if ($null -ne $currentSub) {
            $currentAccount = (Get-Content ~/.azure/azureProfile.json | ConvertFrom-Json).subscriptions | Where-Object { $_.id -eq $currentSub }
            if ($null -ne $currentAccount) {
                Write-Powerline $Background $PrevBackground

                Write-HostColor " $([char]0xf0e7)" $Background "#FFFF00"
                Write-HostColor " $($currentAccount.name) " $Background "#FFFFFF"

                return $Background;
            }
        }
    }

    return $PrevBackground;
}

function Write-HealthSegment {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [int] $ErrorCount,
		[Parameter(Mandatory = $true, Position = 2)] [string] $LastEC,
		[Parameter(Mandatory = $true, Position = 3)] [string] $PrevBackground,
		[Parameter(Mandatory = $true, Position = 4)] [string] $OKBackground,
		[Parameter(Mandatory = $true, Position = 5)] [string] $ErrorBackground
	)

    # https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/src/segments/exit.go
    if ($ErrorCount -ne 0 -or ($LastEC -ne "" -and $LastEC -ne "0")) {
        Write-Powerline $ErrorBackground $PrevBackground

        # Write ERR for any PowerShell errors
        if ($ErrorCount -ne 0) {
            Write-HostColor " $([char]0xe23a) $([char]0xf00d) " $ErrorBackground "#FFFFFF"
        }
        # Write non-zero exit code from last launched process
        if ($LastEC -ne "" -and $LastEC -ne "0") {
            Write-HostColor " $([char]0xe23a) $([char]0xf00d) EC $LastEC " $ErrorBackground "#FFFFFF"
        }        
        return $ErrorBackground
    }
    else {
        Write-Powerline $OKBackground $PrevBackground
        Write-HostColor " $([char]0xe23a) $([char]0xf42e) " $OKBackground "#FFFFFF"
        return $OKBackground
    }
}

function Write-PromptSegment {
	param(
		[Parameter(Mandatory = $true, Position = 0)] [string] $PrevBackground,
		[Parameter(Mandatory = $true, Position = 1)] [string] $Background,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Foreground
	)

    $isDesktop = ($PSVersionTable.PSEdition -eq "Desktop")
    Write-Powerline $Background $PrevBackground

    $executionTime = ""
    $history = ( Get-History -Count 1  )
    
    if ( $history.Count -eq 1  )
    {
        if ( $history.Duration.TotalMilliseconds -gt 1000 )
        {
            $executionTime = " $([char]0xf608) {0:0.0}s" -f $history.Duration.TotalSeconds
        }
        else
        {
            $executionTime = " $([char]0xf608) {0:0}ms" -f $history.Duration.TotalMilliseconds
        }
    }

    if ( $isDesktop ) {
        Write-HostColor "$executionTime PS " $Background $Foreground
    }
    else {
        Write-HostColor "$executionTime pwsh " $Background $Foreground
    }

    return $Background;
}

function Write-SharedGitSegments {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Background,
        [Parameter(Mandatory = $true, Position = 2)] [string] $Foreground
	)

    if (Get-IsGitRepo) {
        $sharedFolders = Get-ChildItem -Directory -Filter Shared*;

        for($i=0; $i -lt $sharedFolders.Length; $i++)
        {
            cd $sharedFolders[$i].FullName

            if ( $i -eq 0 ) {
                Write-Diamond $Background;
            }
            else {
                Write-Powerline $Background "TRANSPARENT"
            }

            Write-GitDetails $Background $Foreground;

            if ( $i -eq $sharedFolders.Length - 1 ) {
                Write-Diamond $Background $true;
            }
            else {
                Write-Powerline "TRANSPARENT" $Background
            }
            
            cd ..
        }

        if ( $sharedFolders.Length -gt 0 ) {
            Write-Host "";
            $global:GitStatus = Get-GitStatus
        }
    }
}

function Write-GitSegment {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [string] $PrevBackground,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Background,
        [Parameter(Mandatory = $true, Position = 3)] [string] $Foreground
	)

    if (Get-IsGitRepo) {
        Write-Powerline $Background $PrevBackground
        Write-GitDetails $Background $Foreground;
        return $Background;
    }
    return $PrevBackground;
}

function Write-GitDetails {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Background,
        [Parameter(Mandatory = $true, Position = 2)] [string] $Foreground
	)
    
    # https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/src/segments/git.go
    # My OMP template: " {{ .HEAD }}{{ if gt .Ahead 0}} \u2261{{ .Ahead }}\u2191{{ end }}{{ if gt .Behind 0}} \u2261{{ .Behind }}\u2193{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Staging.Changed) (.Working.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0}} \uf692 {{ .StashCount }}{{ end }}{{ if gt .WorktreeCount 0}} \uf1bb {{ .WorktreeCount }}{{ end }} "
    #   HEAD property of OMP for git is much more detailed than mine, do I care?

    $global:GitStatus = Get-GitStatus;
    $st = $global:GitStatus;

    $repoName = $st.Branch
    if ( $st.RepoName.StartsWith("Shared") ) {
        $repoName = "$($st.RepoName):$($st.Branch)"
    }
    # detached at [commiticon]{id}

    # Write-HostColor " Head: $([char]0x2261) Branch, $([char]0xF412) Tag, $([char]0xF594) No Commit, $([char]0xF417) Commits " $Background $Foreground
    # Write-HostColor " Branch: $([char]0xf00d) Gone, $([char]0xfbc2) Untracked, $([char]0x2261)$([char]0x2191) Ahead, $([char]0x2261)$([char]0x2193) Behind " $Background $Foreground
    # Write-HostColor " Test: $([char]0xf06a) $([char]0x2262) $([char]0xf00d) $([char]0xfbc2) $([char]0xf5b4) $([char]0xf818) $([char]0xf819)" $Background $Foreground
    # Write-HostColor " OMP Head: $([char]0xF417) Detached, $([char]0xF412) Tag, $([char]0xE728) Rebase, $([char]0xE29B) Cherry, $([char]0xF0E2) Revert, $([char]0xE727) Merge, $([char]0xF594)  No Commit " $Background $Foreground

    # https://github.com/dahlbyk/posh-git#git-status-summary-information
    # https://github.com/JanDeDobbeleer/oh-my-posh/blob/e3b2d86b06dd2b49596543688c4a2383288482d1/src/segments/git.go#L327
    #   - This has all kinds of stuff based on current detached, merge, cherry pick status...see if I can reproduce?
    Write-HostColor " $([char]0xf418) $repoName" $Background $Foreground

    if (!$st.Upstream) {
        Write-HostColor " $([char]0xfbc2)" $Background $Foreground
    }
    elseif ($st.UpstreamGone -eq $true) {
        Write-HostColor " $([char]0xf00d)" $Background $Foreground
    }
    elseif ( $st.AheadBy -gt 0 -and $st.BehindBy -gt 0 ) {
        Write-HostColor " $([char]0xF417)$([char]0x2191)$($st.AheadBy)$([char]0x2193)$($st.BehindBy)" $Background $Foreground
    }
    elseif ( $st.AheadBy -gt 0 ) {
        Write-HostColor " $([char]0xF417)$([char]0x2191)$($st.AheadBy)" $Background $Foreground
    }
    elseif ( $st.BehindBy -gt 0 ) {
        Write-HostColor " $([char]0xF417)$([char]0x2193)$($st.BehindBy)" $Background $Foreground
    }
    
    if ( $st.HasWorking ) {
        Write-GitDetails-ChangeStatus "$([char]0xf044)" $st.Working $Background $Foreground
    }
    if ( $st.HasIndex -and $st.HasWorking ) {
        Write-HostColor " |" $Background $Foreground
    }
    if ( $st.HasIndex ) {
        Write-GitDetails-ChangeStatus "$([char]0xf046)" $st.Index $Background $Foreground
    }

    if ($GitPromptSettings.EnableStashStatus -and ($st.StashCount -gt 0)) {
        Write-HostColor " $([char]0xf692)$($st.StashCount)" $Background $Foreground
    }

    Write-HostColor " " $Background $Foreground
    # Write-Host (Write-VcsStatus) -NoNewLine
}

function Write-GitDetails-ChangeStatus {
	param(        
		[Parameter(Mandatory = $true, Position = 1)] [string] $Icon,
        [Parameter(Mandatory = $true, Position = 2)] $StatusContext,
		[Parameter(Mandatory = $true, Position = 3)] [string] $Background,
        [Parameter(Mandatory = $true, Position = 4)] [string] $Foreground
	)
    Write-HostColor " $Icon" $Background $Foreground
    if ( $StatusContext.Added ) {
        Write-HostColor " +$($StatusContext.Added.Count)" $Background $Foreground
    }
    if ( $StatusContext.Modified ) {
        Write-HostColor " ~$($StatusContext.Modified.Count)" $Background $Foreground
    }
    if ( $StatusContext.Deleted ) {
        Write-HostColor " -$($StatusContext.Deleted.Count)" $Background $Foreground
    }
    if ( $StatusContext.Unmerged ) {
        Write-HostColor " !$($StatusContext.Unmerged.Count)" $Background $Foreground
    }
}

function Get-IsGitRepo {
    if ((Get-Command "Get-GitDirectory" -ErrorAction Ignore) -ne $null) {
        $gitDir = Get-GitDirectory

        if ($gitDir -ne $null) {
            $currentPath = ([string]$pwd);
            
            $testPath = $currentPath.ToLower()
            $testGitPath = $gitDir.ToLower()

            $nonRepo =  ( $testPath.StartsWith("c:\btr\evolution\websites") -and $testGitPath -eq "c:\btr\evolution\.git" ) -or
                        ( $testPath.StartsWith("c:\btr\evolution\api") -and $testGitPath -eq "c:\btr\evolution\.git" ) -or
                        ( $testPath.StartsWith("c:\btr\evolution\btr.evolution.hangfire.jobs") -and $testGitPath -eq "c:\btr\evolution\.git" ) -or
                        ( $testPath.StartsWith("c:\btr.legacy\madhatter.4.1\websites") -and $testGitPath -eq "c:\btr.legacy\madhatter.4.1\.git" ) -or
                        ( $testPath.StartsWith("c:\btr.legacy\madhatter.4.5\websites.madhatteradmin\clients") -and $testGitPath -eq "c:\btr.legacy\madhatter.4.5\.git" ) -or
                        ( $testPath.StartsWith("c:\btr.legacy\tahiti\btr.websites.madhatter\clients") -and $testGitPath -eq "c:\btr.legacy\tahiti\.git" )

            return !$nonRepo;
        }
    }
    return $false;
}

function Write-Diamond {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Foreground,
        [Parameter(Mandatory = $false, Position = 2)] [switch] $IsTrailing
	)

    $diamond = "$([char]0xe0b6)";

    if ( $IsTrailing ) {
        $diamond = "$([char]0xe0b4)";
    }
    Write-HostColor $diamond "TRANSPARENT" $Foreground
}

function Write-Powerline {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Background,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Foreground
	)
    if ($Foreground -eq "" -or $Foreground -eq $Background) {
        return;
    }

    Write-HostColor "$([char]0xe0b0)" $Background $Foreground
}

function Write-HostColor {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Text,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Background,
		[Parameter(Mandatory = $true, Position = 3)] [string] $Foreground
	)

    if ( $Foreground -eq "TRANSPARENT" ) {
        $Foreground = "#193549";
    }

    $ForegroundColor = ConvertFrom-Hex $Foreground;

    if ( $Background -eq "TRANSPARENT" ) {
        Write-Host "$([char]27)[38;2;${ForegroundColor}m$Text$([char]27)[0m" -NoNewLine
    }
    else {
        $BackgroundColor = ConvertFrom-Hex $Background;
        Write-Host "$([char]27)[38;2;${ForegroundColor};48;2;${BackgroundColor}m$Text$([char]27)[0m" -NoNewLine
    }
}

function hasLanguageFiles {
    param(
        [Parameter(Mandatory = $true, Position = 0)] [string] $filePatterns,
        [Parameter(Mandatory = $false, Position = 1)] [switch] $IncludeParent
    )
    
    $currentFolder = Get-Location
    
    while ($currentFolder -ne "") {
        foreach ($filePath in $filePatterns.Split(',', [StringSplitOptions]::RemoveEmptyEntries)) {
            if ((Get-ChildItem -ErrorAction Ignore -LiteralPath $currentFolder -Filter $filePath).Count -gt 0) {
                return $true
            }
        }
        if ( $IncludeParent ) {
            $currentFolder = Split-Path $currentFolder
        }
        else {
            $currentFolder = ""
        }
    }
    
    return $false
}

function ConvertFrom-Hex {
	param(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Color
	)

    # https://github.com/brunovieira97/ps-color/blob/main/src/util/Color.ps1

	# Remove # symbol
	$Color = $Color.Remove(0, 1);

	$red	= $Color.Remove(2, 4);
	$green	= $Color.Remove(4, 2).Remove(0, 2);
	$blue	= $Color.Remove(0, 4);

	$red	= [System.Convert]::ToInt32($red, 16);
	$green	= [System.Convert]::ToInt32($green, 16);
	$blue	= [System.Convert]::ToInt32($blue, 16);

	return "$red;$green;$blue";
}

function Get-IsAdmin {
    $isAdmin = $false
    $isDesktop = ($PSVersionTable.PSEdition -eq "Desktop")

    if ($isDesktop -or $IsWindows) {
        $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $windowsPrincipal = new-object 'System.Security.Principal.WindowsPrincipal' $windowsIdentity
        $isAdmin = $windowsPrincipal.IsInRole("Administrators") -eq 1
    }
    else {
        $isAdmin = ((& id -u) -eq 0)
    }

    return $isAdmin    
}

$global:OriginalTitle = ""

function Write-WindowTitle {
    $WindowTitleSupported = $true
    if (Get-Module NuGet) {
        $WindowTitleSupported = $false
    }
    if ($WindowTitleSupported) {
        if ( $global:OriginalTitle -eq "" ) {
            $global:OriginalTitle = $Host.UI.RawUI.WindowTitle
        }

        $title = $global:OriginalTitle

        if ( 0 -gt 1 ) {
            if (Get-IsGitRepo) {
                $st = $GitStatus;

                $repoName = Split-Path -Leaf (Split-Path $st.GitDir)
                $branch = $GitStatus.Branch

                $title = "$($repoName):$($branch) "

                if ( $st.AheadBy -gt 0 -and $st.BehindBy -gt 0 ) {
                    $title += "↑$($st.AheadBy)↓$($st.BehindBy) "
                }
                elseif ( $st.AheadBy -gt 0 ) {
                    $title += "↑$($st.AheadBy) "
                }
                elseif ( $st.BehindBy -gt 0 ) {
                    $title += "↓$($st.BehindBy) "
                }


                if ($GitPromptSettings.EnableFileStatus -and ($st.HasIndex -or $st.HasWorking)) {
                    if ($st.HasWorking) {
                        if ( $st.Working.Added ) {
                            $title += "+$($st.Working.Added.Count)"
                        }
                        if ( $st.Working.Modified ) {
                            $title += "~$($st.Working.Modified.Count)"
                        }
                        if ( $st.Working.Deleted ) {
                            $title += "-$($st.Working.Deleted.Count)"
                        }
                        if ( $st.Working.Unmerged ) {
                            $title += "!$($st.Working.Unmerged.Count)"
                        }
                    }
                    if ( $st.HasIndex -and $st.HasWorking ) {
                        $title += " | "
                    }
                    if ( $st.HasIndex ) {
                        if ( $st.Index.Added ) {
                            $title += "+$($st.Working.Added.Count)"
                        }
                        if ( $st.Index.Modified ) {
                            $title += "~$($st.Index.Modified.Count)"
                        }
                        if ( $st.Index.Deleted ) {
                            $title += "-$($st.Index.Deleted.Count)"
                        }
                        if ( $st.Index.Unmerged ) {
                            $title += "!$($st.Index.Unmerged.Count)"
                        }
                    }
                }
            }
        }

        if ( $title.StartsWith("Administrator: ") ) {
            $title = $title.Substring("Administrator: ".Length)
        }

        $Host.UI.RawUI.WindowTitle = $title
    }
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

function Unblock-Files {
    param(
        [Parameter(Mandatory = $true, Position = 1)] [string] $Directory
    )
    Get-ChildItem -Path $Directory -Recurse | ForEach-Object {
        if ( Test-Path -Path $_ -PathType Leaf ) {
            Write-Host "Unblocking file $($_.Name) ..."
        }
        else {
            Write-Host "Unblocking directory $($_.Name) ..."
        }
        Unblock-File $_
    }
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
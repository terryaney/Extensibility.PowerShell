param(
    [string]$edition,
    [string]$version = "2017",
    [string]$basePath = "",
    [switch]$noWeb = $false
)

function append-path {
    param(
        [string[]][Parameter(Mandatory = $true)]$pathsToAdd
    )

    $local:separator = ";"
    if (($PSVersionTable.PSVersion.Major -gt 5) -and ($PSVersionTable.Platform -eq "Unix")) {
        $local:separator = ":"
    }

    $env:PATH = $env:PATH + $local:separator + ($pathsToAdd -join $local:separator)
}

# Only support one prompt environment at a time
if ($PromptEnvironment -ne $null) {
    write-host "error: Prompt is already in a custom environment." -ForegroundColor Red
    exit 1
}

# Look in the standard installation location unless they override
if ($basePath -eq "") {
    $basePath = join-path (join-path ${env:ProgramFiles(x86)} "Microsoft Visual Studio") $version
}

# Test to see if it's installed
if ((test-path $basePath) -eq $false) {
    $basePath = join-path (join-path ${env:ProgramFiles} "Microsoft Visual Studio") $version
}
if ((test-path $basePath) -eq $false) {
    write-warning "Visual Studio $version is not installed in '$basePath'."
    exit 1
}

# If edition wasn't specified, see what's there, and bail out if there is more than 1
if ($edition -eq "") {
    $editions = (get-childitem $basePath | where-object { $_.PSIsContainer })
    if ($editions.Count -eq 0) {
        write-warning "Visual Studio $version is not installed."
        exit 1
    }
    if ($editions.Count -gt 1) {
        write-warning "Multiple editions of Visual Studio $version are installed. Please specify one of the editions ($($editions -join ', ')) with the -edition switch."
        exit 1
    }
    $edition = $editions[0].Name
}

# Find VsDevCmd.bat
$path = join-path (join-path (join-path $basePath $edition) "Common7") "Tools"

if ((test-path $path) -eq $false) {
    write-warning "Visual Studio $version edition '$edition' could not be found."
    exit 1
}

$cmdPath = join-path $path "VsDevCmd.bat"

if ((test-path $cmdPath) -eq $false) {
    write-warning "File not found: $cmdPath"
    exit 1
}

# Run VsDevCmd.bat and then dump all environment variables, so we can
# overwrite ours with theirs
$tempFile = [IO.Path]::GetTempFileName()

cmd /c " `"$cmdPath`" && set > `"$tempFile`" "

Get-Content $tempFile | %{
    if ($_ -match "^(.*?)=(.*)$") {
        Set-Content "env:\$($matches[1])" $matches[2]
    }
}

# Optionally add the external web tools unless skipped
if ($noWeb -eq $false) {
    $path = join-path (join-path (join-path $basePath $edition) "Web") "External"

    if (test-path $path) {
        append-path $path
    } else {
        write-warning "Path $path not found; specify -noWeb to skip searching for web tools"
    }
}

# Set the prompt environment variable (printed in our prompt function)
$global:VSPromptEnvironment = "$version"
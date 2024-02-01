function gitOff_UsingPrePushHook {
    $command = $Args[0]

    # Check if the first argument is "push"
    if ($command -eq "push" -and $Args.Length -eq 1) {
        # Add your custom behavior for the "git push" command here

		$configValue = Invoke-Expression "git config --get remote.gh.url" | Out-String
		$configValue = $configValue.Trim()

		if ($configValue -ne "") {
			Write-Host "Pushing to Github..."
			$newCommand = "git.exe push gh main"
			Invoke-Expression $newCommand		
			Write-Host "Github push complete."
			Write-Host ""
			Write-Host "Pushing to origin"
		}
    }

	# Run whatever was requested
	$newCommand = "git.exe"
	foreach ($arg in $Args) {
		if ($arg -match '\s') {
			$newCommand += ' "' + $arg + '"'
		}
		else {
			$newCommand += ' ' + $arg
		}
	}

	# Write-Host $newCommand
	Invoke-Expression $newCommand		
}
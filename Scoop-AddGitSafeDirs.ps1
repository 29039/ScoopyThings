$scoopdir = "$env:USERPROFILE\scoop"

$modifiedPaths = Get-ChildItem -Path $scoopdir -Directory -Filter .git -Recurse -Force | ForEach-Object {
    ($_.FullName -replace '\\.git$', '') -replace '\\', '/'
}

function Get-IniContent {
    param (
        [string]$Path
    )

    $iniContent = @{}
    $currentSection = ""

    Get-Content -Path $Path -ErrorAction SilentlyContinue | ForEach-Object {
        $line = $_.Trim()

        if ($line -match '^\[([^\]]+)\]$') {
            $currentSection = $matches[1]
            $iniContent[$currentSection] = @{}
        }
        elseif ($line -match '^(.*?)\s*=\s*(.*?)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()

            # If the key already exists, convert the value to an array
            if ($iniContent[$currentSection].ContainsKey($key)) {
                $iniContent[$currentSection][$key] += $value
            } else {
                $iniContent[$currentSection][$key] = @($value)
            }
        }
    }

    $iniContent
}

$gitConfigFile = Join-Path $scoopdir 'apps\git\current\etc\gitconfig'
$gitConfigContent = Get-IniContent -Path $gitConfigFile

# Check if [safe] section exists
if ($gitConfigContent.ContainsKey('safe')) {
    $safeDirectory = $gitConfigContent['safe']['directory']

    foreach ($path in $modifiedPaths) {
        Write-Output "Checking if path $path exists in the [safe] section of gitconfig..."

        # Check if the path exists in the [safe] section of the gitconfig file
        $pathExistsInConfig = $safeDirectory -contains $path

        if (-not $pathExistsInConfig) {
            Write-Output "Path $path not found in gitconfig. Adding to [safe] section..."
            # Run the git config command for each path
            git config --system --add safe.directory $path
            Write-Output "Added $path to [safe] section."
            Write-Output ""  # Add a newline
        } else {
            Write-Output "Path $path already exists in the [safe] section of gitconfig. Skipping..."
            Write-Output "Skipped $path."
            Write-Output ""  # Add a newline
        }
    }
} else {
    # If [safe] section does not exist, assume no match and run git config commands
    foreach ($path in $modifiedPaths) {
        Write-Output "Path $path not found in gitconfig. Adding to [safe] section..."
        # Run the git config command for each path
        git config --system --add safe.directory $path
        Write-Output "Added $path to [safe] section."
        Write-Output ""  # Add a newline
    }
}

$ErrorActionPreference = "Stop"
Set-PSDebug -Trace 1
$tmpdir = $Env:TEMP
$BINSTALL_VERSION = $Env:BINSTALL_VERSION
if ($BINSTALL_VERSION -and $BINSTALL_VERSION -notlike 'v*') {
    # prefix version with v
    $BINSTALL_VERSION = "v$BINSTALL_VERSION"
}
# Fetch binaries from `[..]/releases/latest/download/[..]` if _no_ version is
# given, otherwise from `[..]/releases/download/VERSION/[..]`. Note the shifted
# location of '/download'.
$base_url = if (-not $BINSTALL_VERSION) {
    "https://github.com/cargo-bins/cargo-binstall/releases/latest/download/cargo-binstall-"
} else {
    "https://github.com/cargo-bins/cargo-binstall/releases/download/$BINSTALL_VERSION/cargo-binstall-"
}

$proc_arch = [Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE", [EnvironmentVariableTarget]::Machine)
if ($proc_arch -eq "AMD64") {
	$arch = "x86_64"
} elseif ($proc_arch -eq "ARM64") {
	$arch = "aarch64"
} else {
	Write-Host "Unsupported Architecture: $type" -ForegroundColor Red
	[Environment]::Exit(1)
}
$url = "$base_url$arch-pc-windows-msvc.zip"
Invoke-WebRequest $url -OutFile $tmpdir\cargo-binstall.zip
Expand-Archive -Force $tmpdir\cargo-binstall.zip $tmpdir\cargo-binstall
Write-Host ""

$ps = Start-Process -PassThru -Wait "$tmpdir\cargo-binstall\cargo-binstall.exe" "--self-install"
if ($ps.ExitCode -ne 0) {
    Invoke-Expression "$tmpdir\cargo-binstall\cargo-binstall.exe -y --force cargo-binstall"
}

Remove-Item -Force $tmpdir\cargo-binstall.zip
Remove-Item -Recurse -Force $tmpdir\cargo-binstall
$cargo_home = if ($Env:CARGO_HOME -ne $null) { $Env:CARGO_HOME } else { "$HOME\.cargo" }
if ($Env:Path -split ";" -notcontains "$cargo_home\bin") {
    if (($Env:CI -ne $null) -and ($Env:GITHUB_PATH -ne $null)) {
        Add-Content -Path "$Env:GITHUB_PATH" -Value "$cargo_home\bin"
    } else {
	    Write-Host ""
    	Write-Host "Your path is missing $cargo_home\bin, you might want to add it." -ForegroundColor Red
	    Write-Host ""
     }
}

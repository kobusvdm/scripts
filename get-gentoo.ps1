
$WslRoot = "$(Resolve-Path $PWD)\.temp"
New-Item -ItemType Directory -Path $WslRoot -Force | Out-Null
New-Item -ItemType Directory -Path $WslRoot\downloads -Force | Out-Null
New-Item -ItemType Directory -Path $WslRoot\wsl -Force | Out-Null
$BouncerURL = "https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds"
$LatestStageBounderFile = "latest-stage3-amd64-openrc.txt"
$LatestBuildManifestURL = "$BouncerURL/$LatestStageBounderFile"
$DownloadPath = "$WslRoot\downloads\wsl"
New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null
$DistroSourcePath = "$WslRoot\wsl\source"
New-Item -ItemType Directory -Path $DistroSourcePath -Force | Out-Null
$WSLDistroBase = "$WslRoot\wsl\distro"
New-Item -ItemType Directory -Path $WSLDistroBase -Force | Out-Null
$GentooWSLPath = "$WSLDistroBase\gentoo"
New-Item -ItemType Directory -Path $GentooWSLPath -Force | Out-Null

$Stage3Manifest = $(Invoke-RestMethod -Uri $LatestBuildManifestURL -FollowRelLink)

$Stage3FileURLPath = (($Stage3Manifest -split "`n" | Where-Object { $_ -match "stage3-amd64-openrc-\d{8}T\d{6}Z.tar.xz" }) -split " " | Select-Object -First 1).Trim()

$Stage3FileName = $Stage3FileURLPath -split "/" | Select-Object -Last 1
Write-Host "Stage3FileName=[${Stage3FileName}]"

$Stage3XZPath = "$DownloadPath\$Stage3FileName"
Write-Host "Stage3XZPath=[${Stage3XZPath}]"
$Stage3GZPath = "$DistroSourcePath\$Stage3FileName" -replace ".tar.xz", ".tar.gz"
Write-Host "Stage3GZPath=[${Stage3GZPath}]"

if (-not (Test-Path $Stage3GZPath)) {
    if (-not (Test-Path $Stage3XZPath)) {
        Write-Host "Downloading $BouncerURL/$Stage3FileURLPath"
        Invoke-WebRequest -Uri "$BouncerURL/$Stage3FileURLPath" -OutFile "$Stage3XZPath" -AllowInsecureRedirect
    }
        
    & xz -d -c $Stage3XZPath | & gzip > $Stage3GZPath
    
}

Write-Host "Stage3FileName=[${Stage3FileName}]"
$DistroName = "gentoo-$($Stage3FileName -split "\.tar" | Select-Object -First 1)"
Write-Host "DistroName=[$DistroName]"

if ("$DistroName".Length -eq 0) {
    Write-Host Invalid distro name. Aborting.
    exit
}

if (Test-Path "$GentooWSLPath\$DistroName") {
    Write-Host "Distribution $DistroName already exists. Skipping import."
} else {
    New-Item -ItemType Directory -Path $GentooWSLPath\$DistroName -Force | Out-Null
    wsl --import $DistroName $GentooWSLPath\$DistroName $Stage3GZPath
}
Write-Host "Gentoo has been successfully installed as a WSL distro. You can now start it using 'wsl -d Gentoo'."


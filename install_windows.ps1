
#install choco
If(-Not (Test-Path -Path "$env:ProgramData\Chocolatey")) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

choco install -y miniconda3 --params="'/AddToPath:1'"
choco install -y openssh
choco install -y git
choco install -y cmake
choco install -y vscode
choco install -y pycharm-community
choco install -y qbittorrent
choco install -y vlc
choco install -y 7zip
choco install -y hwinfo
choco install -y procexp

refreshenv

conda init powershell

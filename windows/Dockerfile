# escape=`
# https://learn.microsoft.com/en-us/visualstudio/install/build-tools-container?view=vs-2022

# Use the latest Windows Server Core 2022 image.
FROM mcr.microsoft.com/windows-cssc/python:3.11-servercore-ltsc2019

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

RUN `
    # Download the Build Tools bootstrapper.
    curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe `
    `
    # Install Build Tools with the Microsoft.VisualStudio.Workload.AzureBuildTools workload, excluding workloads and components with known issues.
    && (start /w vs_buildtools.exe --quiet --wait --norestart --nocache `
        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" `
        --add Microsoft.VisualStudio.Workload.AzureBuildTools `
        --add Microsoft.VisualStudio.Workload.VCTools `
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        --add Microsoft.VisualStudio.Component.Windows10SDK.19041 `
        --add Microsoft.VisualStudio.Component.VC.CMake.Project `
        --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 `
        --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 `
        --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 `
        --remove Microsoft.VisualStudio.Component.Windows81SDK `
        || IF "%ERRORLEVEL%"=="3010" EXIT 0) `
    `
    # Cleanup
    && del /q vs_buildtools.exe


RUN powershell.exe -Command `
    $ErrorActionPreference = 'Stop'; `
    Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.45.2.windows.1/Git-2.45.2-64-bit.exe" -OutFile "C:\\Git-2.45.2-64-bit.exe"; `
    Start-Process -FilePath "C:\\Git-2.45.2-64-bit.exe" -ArgumentList '/VERYSILENT', '/NORESTART' -Wait; `
    Remove-Item -Force "C:\\Git-2.45.2-64-bit.exe"


RUN powershell.exe -Command `
    $ErrorActionPreference = 'Stop'; `
    Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "C:\\vc_redist.x64.exe"; `
    Start-Process -FilePath "C:\\vc_redist.x64.exe" -ArgumentList '/install', '/quiet', '/norestart' -Wait; `
    Remove-Item -Force "C:\\vc_redist.x64.exe"; 


# Set environment variables
ENV BOOST_VERSION=1.81.0
ENV BOOST_VERSION_UNDERSCORE=1_81_0

# Download and install Boost from GitHub using PowerShell and tar
RUN powershell.exe -Command `
    $ErrorActionPreference = 'Stop'; `
    Invoke-WebRequest -Uri "https://github.com/MarkusJx/prebuilt-boost/releases/download/$env:BOOST_VERSION/boost-$env:BOOST_VERSION-windows-2022-msvc-shared-x86.tar.gz" -OutFile "C:\\boost_%BOOST_VERSION_UNDERSCORE%.tar.gz"; `
    tar -xf C:\\boost_$env:BOOST_VERSION_UNDERSCORE.tar.gz -C C:\\; `
    Remove-Item -Force C:\\boost_$env:BOOST_VERSION_UNDERSCORE.tar.gz


# Download and install 7zip
RUN powershell -Command `
    $ErrorActionPreference = 'Stop'; `
    Invoke-WebRequest -Uri https://www.7-zip.org/a/7z1900-x64.msi -OutFile C:\7z1900-x64.msi; `
    Start-Process msiexec.exe -ArgumentList '/i', 'C:\7z1900-x64.msi', '/quiet', '/norestart' -NoNewWindow -Wait; `
    Remove-Item C:\7z1900-x64.msi

ENV BOOST_ROOT C:\boost
RUN setx PATH "%PATH%;%BOOST_ROOT%\lib;C:\Program Files\7-Zip"

# Define the entry point for the docker container.
# This entry point starts the developer command prompt and launches the PowerShell shell.
ENTRYPOINT ["C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "-arch=amd64", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
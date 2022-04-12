::
::  app-config.cmd - Generates nrtest app configuration file for SUT executable
::
::  Date Created: 10/16/2019
::  Date Modified: 10/17/2019
::
::  Author: See AUTHORS
::
::  Requires:
::    git
::
::  Environment Variables:
::    PROJECT
::
::  Arguments:
::    1 - absolute path to test executable (valid path seperator for nrtest is "/")
::    2 - (platform)
::    3 - (build identifier for SUT)
::

@echo off
setlocal


:: check requirements
where git > nul
if %ERRORLEVEL% NEQ 0 ( echo "ERROR: git not installed" & exit /B 1 )

:: check environment
if not defined PROJECT ( echo "ERROR: PROJECT must be defined" & exit /B 1 )


:: CLE target created by the cmake build script
set TEST_CMD=run%PROJECT%.exe

:: remove quotes from path and convert backward to forward slash
set ABS_BUILD_PATH=%~1
set ABS_BUILD_PATH=%ABS_BUILD_PATH:\=/%

if [%2]==[] ( set "PLATFORM=unknown"
) else ( set "PLATFORM=%~2" )

if [%3]==[] ( set "BUILD_ID=unknown"
) else ( set "BUILD_ID=%~3" )

:: determine GIT_HASH
for /F "tokens=1" %%h in ( 'git rev-parse --short HEAD' ) do ( set "GIT_HASH=%%h" )
if not defined GIT_HASH ( echo "WARNING: GIT_HASH could not be determined" )

:: determine VERSION
for /F "tokens=1" %%v in ( '%ABS_BUILD_PATH%/%TEST_CMD% -v' ) do ( set "VERSION=%%v" )
if not defined VERSION ( echo "WARNING: VERSION could not be determined" )


echo {
echo     "name" : "%PROJECT%",
echo     "version" : "%VERSION%",
echo     "description" : "%PLATFORM% %BUILD_ID% %GIT_HASH%",
echo     "setup_script" : "",
echo     "exe" : "%ABS_BUILD_PATH%/%TEST_CMD%"
echo }

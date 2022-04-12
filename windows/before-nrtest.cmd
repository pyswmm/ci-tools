::
::  before-test.cmd - Stages test and benchmark files for nrtest
::
::  Created: Oct 16, 2019
::  Updated: Dec 6, 2021
::
::  Author: See AUTHORS
::
::  Dependencies:
::    curl
::    7z
::
::  Environment Variables:
::    PROJECT
::    BUILD_HOME - defaults to "build"
::    PLATFORM
::    NRTESTS_URL - URL to set the test suite defaults to "https://github.com/OpenWaterAnalytics/%PROJECT%-nrtestsuite"
::
::  Arguments:
::    1 - (RELEASE_TAG) release tag for benchmark version (defaults to latest tag)
::
::  Note:
::    Tests and benchmark files are stored in the "%PROJECT%-nrtestsuite" repo.
::    This script retrieves them using a stable URL associated with a GitHub
::    release, stages the files, and sets up the environment for nrtest to run.
::

@echo off

:: set global default
set "TEST_HOME=nrtests"


echo INFO: Staging files for regression testing

:: check env variables and apply defaults
for %%v in (PROJECT BUILD_HOME PLATFORM) do (
  if not defined %%v ( echo ERROR: %%v must be defined & goto ERROR )
)
echo CHECK: all required variables are set


:: determine project directory
set "SCRIPT_HOME=%~dp0"
cd %SCRIPT_HOME%
pushd ..
pushd ..
set "PROJECT_DIR=%CD%"


setlocal


:: create a clean directory for staging regression tests
if exist %TEST_HOME% (
  rmdir /s /q %TEST_HOME%
)
mkdir %TEST_HOME% && cd %TEST_HOME% || (
  echo ERROR: unable to create %TEST_HOME% dir & goto ERROR
)

set "DEFAULT_TESTSUITE=https://github.com/OpenWaterAnalytics/%PROJECT%-nrtestsuite"


:: check that dependencies are installed
for %%d in (curl 7z) do (
  where %%d > nul
  if %ERRORLEVEL% neq 0 ( echo ERROR: %%d not installed ] & goto ERROR )
)
echo CHECK: all dependencies are installed


:: set URL to github repo with test files
if not defined NRTESTS_URL (
  set "NRTESTS_URL=%DEFAULT_TESTSUITE%"
)
echo CHECK: using NRTESTS_URL = %NRTESTS_URL%


:: if release tag isn't provided latest tag will be retrieved
if [%1] == [] (set "RELEASE_TAG="
) else (set "RELEASE_TAG=%~1")

:: determine latest tag in the tests repo
if [%RELEASE_TAG%] == [] (
  for /F delims^=^"^ tokens^=2 %%g in ('curl --silent %NRTESTS_URL%/releases/latest') do (
    set "RELEASE_TAG=%%~nxg"
  )
)

if defined RELEASE_TAG (
  echo CHECK: using RELEASE_TAG = %RELEASE_TAG%
) else (
  echo ERROR: tag %RELEASE_TAG% is invalid & goto ERROR
)


:: Set up test files
set TESTFILES_URL=%NRTESTS_URL%/archive/%RELEASE_TAG%.zip
echo CHECK: using TESTFILES_URL = %TESTFILES_URL%

:: retrieve nrtest cases for regression testing
curl -fsSL -o nrtestfiles.zip %TESTFILES_URL% && (
  echo CHECK: testfiles download successful
) || (
  echo ERROR: unable to download testfiles & goto ERROR
)

:: extract tests
7z x nrtestfiles.zip * > nul && (
  echo CHECK: testfiles extraction successful
) || (
  echo ERROR: file nrtestfiles.zip does not exist & goto ERROR
)

:: create symlink to test folder
mklink /D .\tests .\%PROJECT%-nrtestsuite-%RELEASE_TAG:~1%\public > nul && (
  echo CHECK: symlink creation successful
) || (
  echo ERROR: unable to create tests dir symlink & goto ERROR
)


:: Set up benchmark files
set BENCHFILES_URL=%NRTESTS_URL%/releases/download/%RELEASE_TAG%/benchmark-%PLATFORM%.zip
echo CHECK: using BENCHFILES_URL = %BENCHFILES_URL%

curl -fsSL -o benchmark.zip %BENCHFILES_URL% && (
  echo CHECK: benchfiles download successful
) || (
  echo WARNING: unable to download benchmark files & goto WARNING
)

7z x benchmark.zip -obenchmark\ > nul && (
  echo CHECK: benchfiles extraction successful
) || (
  echo ERROR: file benchmark.zip does not exist & goto ERROR
)

7z e benchmark.zip -o. manifest.json -r > nul && (
  echo CHECK: manifest file extraction successful
) || (
  echo ERROR: file benchmark.zip does not exist & goto ERROR
)


endlocal


:: determine REF_BUILD_ID from manifest file
for /F delims^=^"^ tokens^=4 %%d in ( 'findstr %PLATFORM% %TEST_HOME%\manifest.json' ) do (
  for /F "tokens=2" %%r in ( 'echo %%d' ) do ( set "REF_BUILD_ID=%%r" )
) || (
  echo ERROR: REF_BUILD_ID could not be determined & goto ERROR
)
echo CHECK: using REF_BUILD_ID = %REF_BUILD_ID%

:: GitHub Actions
echo REF_BUILD_ID=%REF_BUILD_ID%>> %GITHUB_ENV%


:: return to users current directory
echo INFO: before-nrtest exiting successfully
exit /b 0

:WARNING
echo INFO: before-nrtest exiting with warnings
exit /b 0

:ERROR
echo ERROR: before-nrtest exiting with errors
exit /b 1

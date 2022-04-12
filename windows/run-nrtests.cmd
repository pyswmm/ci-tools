::
::  run_nrtest.cmd - Runs numerical regression test
::
::  Created: Oct 16, 2019
::  Updated: Jun 2, 2020
::
::  Author: See AUTHORS
::
::  Dependencies:
::    python -m pip install -r requirements.txt
::
::  Environment Variables:
::    PROJECT
::    BUILD_HOME - relative path
::    TEST_HOME  - relative path
::    PLATFORM
::    REF_BUILD_ID
::
::  Arguments:
::    1 - (SUT_BUILD_ID) - optional argument
::

::@echo off
setlocal EnableDelayedExpansion


:: check that dependencies are installed
where 7z > nul
if %ERRORLEVEL% neq 0 ( echo "ERROR: 7z not installed" & exit /B 1 )

:: Check that required environment variables are set
for %%v in ( PROJECT BUILD_HOME TEST_HOME PLATFORM ) do (
  if not defined %%v ( echo "ERROR: %%v must be defined" & exit /B 1 )
)


:: determine project directory
set "SCRIPT_HOME=%~dp0"
cd %SCRIPT_HOME%
pushd ..
pushd ..
set "PROJ_DIR=%CD%"
::popd


cd %PROJ_DIR%\%TEST_HOME%

:: Process optional arguments
if [%1]==[] ( set "SUT_BUILD_ID=local_%RANDOM%"
) else ( set "SUT_BUILD_ID=%~1" )

echo CHECK: Using SUT_BUILD_ID = %SUT_BUILD_ID%


:: check if app config file exists
if not exist apps\%PROJECT%-%SUT_BUILD_ID%.json (
  mkdir apps
  call %SCRIPT_HOME%\app-config.cmd %PROJ_DIR%\%BUILD_HOME%\bin\Release^
    %PLATFORM% %SUT_BUILD_ID% > apps\%PROJECT%-%SUT_BUILD_ID%.json
)


:: recursively build test list
:: set "TESTS=tests\examples"
set TESTS=
for /F "tokens=*" %%T in ('dir /b /s /a:d tests') do (
  set FULL_PATH=%%T
  set TESTS=!TESTS! !FULL_PATH:*%TEST_HOME%\=!
)


:: determine location of python Scripts folder
for /F "tokens=*" %%G in ('where python.exe') do (
  set PYTHON_DIR=%%~dpG
  goto break_loop_1
)
:break_loop_1
set "NRTEST_SCRIPT_PATH=%PYTHON_DIR%Scripts"


:: build nrtest execute command
set NRTEST_EXECUTE_CMD=python.exe %NRTEST_SCRIPT_PATH%\nrtest execute
set TEST_APP_PATH=apps\%PROJECT%-%SUT_BUILD_ID%.json
set TEST_OUTPUT_PATH=benchmark\%PROJECT%-%SUT_BUILD_ID%

:: change current directory to test suite
::cd %TEST_HOME%

:: if present clean test benchmark results
if exist %TEST_OUTPUT_PATH% (
  rmdir /s /q %TEST_OUTPUT_PATH%
)

:: perform nrtest execute
echo INFO: Creating SUT %SUT_BUILD_ID% artifacts
%NRTEST_EXECUTE_CMD% %TEST_APP_PATH% %TESTS% -o %TEST_OUTPUT_PATH%
set RESULT=!ERRORLEVEL!

if %RESULT% neq 0 (
  echo WARNING: nrtest execute exited with errors
)

echo.

:: perform comparison if there is a reference benchmark
if defined REF_BUILD_ID (
  :: build nrtest compare command
  set NRTEST_COMPARE_CMD=python.exe %NRTEST_SCRIPT_PATH%\nrtest compare
  set REF_OUTPUT_PATH=benchmark\%PROJECT%-%REF_BUILD_ID%
  set RTOL_VALUE=0.01
  set ATOL_VALUE=1.E-6

  :: perform nrtest compare
  echo INFO: Comparing SUT artifacts to REF %REF_BUILD_ID%
  !NRTEST_COMPARE_CMD! %TEST_OUTPUT_PATH% !REF_OUTPUT_PATH! --rtol !RTOL_VALUE! --atol !ATOL_VALUE! -o benchmark\receipt-%PLATFORM%.json
  set RESULT=!ERRORLEVEL!
) else (
  set RESULT=-1
)


echo.

cd .\benchmark

:: stage SUT artifacts/receipt for upload
echo INFO: preparing artifacts for upload
if %RESULT% neq 0 (
  7z a benchmark-%PLATFORM%.zip .\%PROJECT%-%SUT_BUILD_ID% > nul
  move /Y benchmark-%PLATFORM%.zip %PROJ_DIR%\upload > nul
) else (
  move /Y receipt-%PLATFORM%.json %PROJ_DIR%\upload > nul
)


:: return user to their current dir and exit
if %RESULT% neq 0 (
  echo ERROR: run-nrtest exiting with errors
) else (
  echo INFO: run-nrtest exiting successfully
)
cd %PROJ_DIR%
exit /B %RESULT%

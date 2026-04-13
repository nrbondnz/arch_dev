@echo off
setlocal EnableDelayedExpansion

REM Usage:
REM   cleanup-sandbox.bat [TABLE_PREFIX]
REM If TABLE_PREFIX is not provided, defaults to "TransactionHistory".
REM Script also cleans up "User" tables as per original behavior.

REM Determine primary table prefix
if "%~1"=="" (
    set "TABLE_PREFIX=TransactionHistory"
) else (
    set "TABLE_PREFIX=%~1"
)

echo.
echo Cleaning up old Amplify sandbox tables for prefix: %TABLE_PREFIX%
call :DeleteTablesByPrefix "%TABLE_PREFIX%"

echo.
echo Cleaning up old Amplify sandbox tables for prefix: User
call :DeleteTablesByPrefix "User"

echo.
echo Delete old tables manually with:
echo   aws dynamodb delete-table --table-name ^<table-name^>

REM Tidy up node processes and .amplify folders like original script
echo.
taskkill /IM node.exe /F >NUL 2>&1
taskkill /IM node.exe /F >NUL 2>&1

echo Tidy up .amplify (current directory)
if exist ".amplify" (
    echo Removing .amplify in current directory: %CD%
    rmdir /S /Q ".amplify"
    echo ExitCode: %ERRORLEVEL%
)

taskkill /IM node.exe /F >NUL 2>&1

echo Tidy up .amplify (script directory)
if exist "%~dp0\.amplify" (
    echo Removing .amplify in script directory: %~dp0
    rmdir /S /Q "%~dp0\.amplify"
    echo ExitCode: %ERRORLEVEL%
)

taskkill /IM node.exe /F >NUL 2>&1

echo.
echo Delete the sandbox...
npx ampx sandbox delete -y

goto :eof


REM -------------------------------
REM Deletes all DynamoDB tables whose names contain the given prefix.
REM Handles pagination and waits for deletion to complete.
REM Robust to AWS CLI printing multiple names on one line.
REM Arg1: table prefix (substring match)
REM -------------------------------
:DeleteTablesByPrefix
set "PREFIX=%~1"

set "TOKEN="
:LIST_PAGE
if defined TOKEN (
  set "TOKEN_ARG=--starting-token !TOKEN!"
) else (
  set "TOKEN_ARG="
)

REM Get a page of matching table names. AWS CLI sometimes prints multiple names on one line with --output text.
REM We first capture each output line, then split that line into individual table tokens.
for /f "usebackq delims=" %%L in (`
  aws dynamodb list-tables ^
    --no-cli-pager !TOKEN_ARG! ^
    --query "TableNames[?contains(@, '%PREFIX%')][]" ^
    --output text
`) do (
  REM Split the line into tokens (each token is one table name; names never contain spaces)
  for %%T in (%%L) do (
    echo Found table: %%T
    aws dynamodb delete-table --no-cli-pager --table-name "%%T"
    echo Waiting for deletion of %%T ...
    aws dynamodb wait table-not-exists --no-cli-pager --table-name "%%T"
  )
)

REM Get next page token (if any)
for /f "usebackq delims=" %%N in (`
  aws dynamodb list-tables ^
    --no-cli-pager !TOKEN_ARG! ^
    --query "NextToken" ^
    --output text
`) do (
  set "TOKEN=%%N"
)

REM If TOKEN is set and not "None", continue paging
if defined TOKEN if /I not "!TOKEN!"=="None" goto LIST_PAGE

goto :eof
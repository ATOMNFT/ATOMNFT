@echo off
setlocal enabledelayedexpansion

:: Ask for the old and new emails
set /p old_email=Enter the OLD email to remove (e.g., itsmestener@gmail.com): 
set /p new_email=Enter your GitHub no-reply email (e.g., 12345678+user@users.noreply.github.com): 

:: Confirm git-filter-repo is available
where git-filter-repo >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: git-filter-repo is not installed or not in PATH.
    echo Install it using:
    echo     pip install git-filter-repo
    pause
    exit /b
)

:: Confirm the location
echo.
echo Running email rewrite in repo:
cd
echo.

pause

:: Write Python callback script to temp file
set callback_file=_email_callback.py
echo def update_email(email):> %callback_file%
echo     if email == b"%old_email%":>> %callback_file%
echo         return b"%new_email%">> %callback_file%
echo     return email>> %callback_file%

:: Run git-filter-repo to rewrite email in all branches and tags
git filter-repo --force --email-callback %callback_file%

:: Delete temp file
del %callback_file%

:: Check for remaining old emails in history
echo.
echo Verifying if any old emails remain...
git log --all --pretty=format:"%%ae" | findstr /C:"%old_email%" > nul
if %errorlevel% == 0 (
    echo.
    echo WARNING: Old email still found in commit history!
    echo Some commits may not have been rewritten properly.
) else (
    echo.
    echo SUCCESS: Old email removed from commit history.
)

:: Push changes to GitHub
echo.
echo Forcing push of rewritten history...
git push --force --all
git push --force --tags

echo.
echo Done.
pause

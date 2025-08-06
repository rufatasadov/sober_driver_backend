@echo off
echo ========================================
echo           GIT PUSH SCRIPT
echo ========================================
echo.


:: Commit mesajı al
set /p commit_msg="Commit message: "
echo.

:: Commit et
echo [3/5] Commit edilir...
git commit -m "%commit_msg%"
echo.


:: Push et
echo [5/5] Push edilir...
git push
echo.

echo ========================================
echo           TAMAMLANDI!
 
 
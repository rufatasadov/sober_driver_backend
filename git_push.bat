@echo off
echo ========================================
echo           GIT PUSH SCRIPT
echo ========================================
echo.

:: Git status yoxla
echo [1/5] Git status yoxlanılır...
git status
echo.

:: Bütün dəyişiklikləri add et
echo [2/5] Dəyişikliklər add edilir...
git add .
echo.

:: Commit mesajı al
set /p commit_msg="Commit mesajını daxil edin: "
echo.

:: Commit et
echo [3/5] Commit edilir...
git commit -m "%commit_msg%"
echo.

:: Remote branch-i yoxla
echo [4/5] Remote branch yoxlanılır...
git branch -r
echo.

:: Push et
echo [5/5] Push edilir...
git push
echo.

echo ========================================
echo           TAMAMLANDI!
echo ========================================
echo.
echo Dəyişikliklər uğurla push edildi!
echo.
pause 
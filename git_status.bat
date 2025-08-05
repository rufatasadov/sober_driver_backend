@echo off
echo ========================================
echo           GIT STATUS CHECK
echo ========================================
echo.

echo [1/3] Git status yoxlanılır...
git status
echo.

echo [2/3] Son commit-lər...
git log --oneline -5
echo.

echo [3/3] Remote branch-lər...
git branch -r
echo.

echo ========================================
echo           TAMAMLANDI!
echo ========================================
echo.
pause 
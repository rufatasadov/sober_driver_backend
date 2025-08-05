@echo off
echo Git Push - Tez Versiya
echo ======================

git add .
set /p msg="Commit mesajı: "
git commit -m "%msg%"
git push

echo.
echo Push tamamlandı!
pause 
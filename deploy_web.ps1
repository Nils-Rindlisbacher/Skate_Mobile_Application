# Timestamp für Commit
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$commitMessage = "build: deploy production web version $timestamp"

Write-Host "Starte Deployment..." -ForegroundColor Cyan

# 1. Sicherstellen, dass main aktuell ist
Write-Host "Pushe Main..." -ForegroundColor Cyan
git push origin main

# 2. Web-Build erstellen
Write-Host "Erstelle Web-Build..." -ForegroundColor Cyan
cd Application/Skaterz
flutter build web --release --base-href "/"
cd ../..

# 3. Alten gh-pages Branch löschen (lokal + remote)
Write-Host "Bereinige alten gh-pages Branch..." -ForegroundColor Cyan
git branch -D gh-pages -ErrorAction SilentlyContinue
git push origin --delete gh-pages -ErrorAction SilentlyContinue

# 4. Subtree erzeugen
Write-Host "Erzeuge neuen gh-pages Branch via Subtree..." -ForegroundColor Cyan
git subtree split --prefix Application/Skaterz/build/web -b gh-pages

# 5. Deployment pushen
Write-Host "Pushe neuen gh-pages Branch..." -ForegroundColor Cyan
git push -f origin gh-pages

Write-Host "-------------------------------------------" -ForegroundColor Green
Write-Host "Deployment erfolgreich: $timestamp" -ForegroundColor Green
Write-Host "-------------------------------------------" -ForegroundColor Green

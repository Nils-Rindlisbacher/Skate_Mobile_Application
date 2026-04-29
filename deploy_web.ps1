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

# 4. Neuen gh-pages Branch erstellen
Write-Host "Erstelle neuen gh-pages Branch..." -ForegroundColor Cyan
git checkout --orphan gh-pages
git rm -rf .

# 5. Web-Build in Root kopieren
Write-Host "Kopiere Web-Build..." -ForegroundColor Cyan
Copy-Item -Path "Application/Skaterz/build/web/*" -Destination "." -Recurse -Force

# 6. CNAME hinzufügen
"ww.dsdsa.ch" | Out-File -Encoding ascii -FilePath "CNAME"

# 7. Commit + Push
git add .
git commit -m $commitMessage
git push -f origin gh-pages

Write-Host "-------------------------------------------" -ForegroundColor Green
Write-Host "Deployment erfolgreich: $timestamp" -ForegroundColor Green
Write-Host "-------------------------------------------" -ForegroundColor Green
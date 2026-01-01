# Datum und Uhrzeit für die Commit-Nachricht generieren
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$commitMessage = "build: deploy production web version $timestamp"

# 1. Änderungen am Main-Zweig pushen
Write-Host "Pushe Main zu Origin..." -ForegroundColor Cyan
git push origin main

# 2. Build erstellen
Write-Host "Erstelle neuen Web-Build..." -ForegroundColor Cyan
cd Application/Skaterz
flutter build web --release --base-href "/Skate_Mobile_Application/"
cd ../..

# 3. Den build-Ordner kurzzeitig zum Git-Index hinzufügen
Write-Host "Bereite Build-Ordner für Subtree vor..." -ForegroundColor Cyan
git add -f Application/Skaterz/build/web
git commit -m $commitMessage

# 4. Alten gh-pages Branch lokal und remote löschen
Write-Host "Lösche alten gh-pages Branch..." -ForegroundColor Cyan
if (git branch -list "gh-pages") {
    git branch -D gh-pages
}
git push origin --delete gh-pages --error-handling=silent

# 5. Subtree split ausführen und neuen Branch erstellen
Write-Host "Führe Subtree Split aus..." -ForegroundColor Cyan
git subtree split --prefix Application/Skaterz/build/web -b gh-pages

# 6. Zu gh-pages pushen
Write-Host "Pushe zu gh-pages..." -ForegroundColor Cyan
git push origin gh-pages:gh-pages --force

# 7. Aufräumen: Den temporären Build-Commit auf Main rückgängig machen
Write-Host "Bereine Main-Branch..." -ForegroundColor Cyan
git reset --soft HEAD~1
git restore --staged .

Write-Host "-------------------------------------------" -ForegroundColor Green
Write-Host "Deployment erfolgreich: $timestamp" -ForegroundColor Green
Write-Host "-------------------------------------------" -ForegroundColor Green

# ================================================
# SENTINEL — Script de déploiement automatique
# Double-cliquer pour déployer vers GitHub
# ================================================

$repoPath = "C:\Users\OussamaElHamali\Desktop\sentinel-cas-ops"
$downloadsPath = "$env:USERPROFILE\Downloads"

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host "   SENTINEL — Déploiement GitHub" -ForegroundColor Yellow  
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""

# Aller dans le repo
Set-Location $repoPath

# Chercher le dernier fichier sentinel dans Downloads
$files = Get-ChildItem "$downloadsPath\sentinel*.html" | Sort-Object LastWriteTime -Descending

if ($files.Count -eq 0) {
    Write-Host "❌ Aucun fichier sentinel*.html trouvé dans Downloads!" -ForegroundColor Red
    Write-Host "   Télécharge le fichier depuis Claude d'abord." -ForegroundColor Red
    Read-Host "Appuie sur Entrée pour fermer"
    exit
}

$latest = $files[0]
Write-Host "✅ Fichier trouvé : $($latest.Name)" -ForegroundColor Green
Write-Host "   Modifié le : $($latest.LastWriteTime)" -ForegroundColor Gray

# Copier vers index.html
Copy-Item $latest.FullName -Destination ".\index.html" -Force
Write-Host "✅ Copié vers index.html" -ForegroundColor Green

# Git
Write-Host ""
Write-Host "📤 Push vers GitHub..." -ForegroundColor Cyan

git add .
git commit -m "SENTINEL update - $((Get-Date).ToString('dd/MM/yyyy HH:mm'))"
git push

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "   ✅ DÉPLOYÉ !" -ForegroundColor Green
Write-Host "   Attends 2 min puis rafraîchis le site" -ForegroundColor Green
Write-Host "   Ctrl+Shift+R sur le navigateur" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Read-Host "Appuie sur Entrée pour fermer"

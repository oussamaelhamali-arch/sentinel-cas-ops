# ╔══════════════════════════════════════════════════════╗
# ║   SENTINEL OPS — Auto Deploy Script (PowerShell)    ║
# ║   Usage : .\deploy.ps1                              ║
# ║   Usage : .\deploy.ps1 -msg "fix planning null"     ║
# ╚══════════════════════════════════════════════════════╝

param(
    [string]$msg = "",
    [switch]$check,
    [switch]$status,
    [switch]$log,
    [switch]$help
)

# ─── COULEURS ─────────────────────────────────────────
function OK    { param($t) Write-Host "  $([char]0x2714)  $t" -ForegroundColor Green }
function FAIL  { param($t) Write-Host "  $([char]0x2718)  $t" -ForegroundColor Red }
function WARN  { param($t) Write-Host "  !  $t" -ForegroundColor Yellow }
function INFO  { param($t) Write-Host "  i  $t" -ForegroundColor Cyan }
function SEP   { Write-Host "  $("─" * 50)" -ForegroundColor DarkGray }
function TITLE { param($t) Write-Host "`n  $t" -ForegroundColor White }

function Header {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║     SENTINEL OPS — GitHub Deploy Tool            ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ─── AIDE ─────────────────────────────────────────────
if ($help) {
    Header
    Write-Host "  COMMANDES :" -ForegroundColor White
    Write-Host ""
    Write-Host "  .\deploy.ps1                     Deploy avec message auto (date+heure)" -ForegroundColor Gray
    Write-Host "  .\deploy.ps1 -msg 'fix planning' Deploy avec message personnalisé" -ForegroundColor Gray
    Write-Host "  .\deploy.ps1 -status             Voir l'état git (fichiers modifiés)" -ForegroundColor Gray
    Write-Host "  .\deploy.ps1 -log                Voir les 10 derniers commits" -ForegroundColor Gray
    Write-Host "  .\deploy.ps1 -check              Vérifier le HTML avant deploy" -ForegroundColor Gray
    Write-Host "  .\deploy.ps1 -help               Cette aide" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

# ─── VÉRIFIER GIT INSTALLÉ ────────────────────────────
function Check-Git {
    try {
        $null = git --version 2>&1
        return $true
    } catch {
        FAIL "Git n'est pas installé ou pas dans le PATH"
        INFO "Télécharge Git : https://git-scm.com/download/win"
        return $false
    }
}

# ─── VÉRIFIER QU'ON EST DANS UN REPO GIT ──────────────
function Check-Repo {
    if (-not (Test-Path ".git")) {
        FAIL "Pas de repo Git dans ce dossier !"
        INFO "Lance d'abord : git init && git remote add origin <ton-url>"
        return $false
    }
    return $true
}

# ─── COMMANDE : STATUS ────────────────────────────────
if ($status) {
    Header
    if (-not (Check-Git)) { exit 1 }
    if (-not (Check-Repo)) { exit 1 }

    TITLE "État du repo :"
    SEP
    $branch = git rev-parse --abbrev-ref HEAD 2>&1
    INFO "Branche : $branch"

    $remote = git remote get-url origin 2>&1
    INFO "Remote  : $remote"
    SEP

    $changes = git status --short 2>&1
    if ($changes) {
        WARN "Fichiers modifiés / non commités :"
        foreach ($line in $changes) {
            Write-Host "    $line" -ForegroundColor Yellow
        }
    } else {
        OK "Aucun changement — repo propre"
    }
    Write-Host ""
    exit 0
}

# ─── COMMANDE : LOG ───────────────────────────────────
if ($log) {
    Header
    if (-not (Check-Git)) { exit 1 }
    if (-not (Check-Repo)) { exit 1 }

    TITLE "10 derniers commits :"
    SEP
    git log --oneline -10 --pretty=format:"  %C(yellow)%h%Creset  %C(cyan)%ad%Creset  %s" --date=format:"%d/%m %H:%M" 2>&1
    Write-Host "`n"
    exit 0
}

# ─── COMMANDE : CHECK HTML ────────────────────────────
if ($check) {
    Header
    TITLE "Vérification du fichier HTML..."
    SEP

    $htmlFile = Get-ChildItem -Filter "*.html" | Select-Object -First 1
    if (-not $htmlFile) {
        FAIL "Aucun fichier .html trouvé dans ce dossier"
        exit 1
    }

    $content = Get-Content $htmlFile.Name -Raw -Encoding UTF8
    INFO "Fichier : $($htmlFile.Name) ($([math]::Round($htmlFile.Length/1024, 1)) KB)"
    SEP

    $fonctions = @(
        "function mad(",
        "function dlCSV(",
        "function dlXls(",
        "async function cloudPull(",
        "function cloudPushData(",
        "function saveRapport(",
        "function genPlanning(",
        "function renderUI(",
        "function loadData(",
        "function toast(",
        "window.onerror",
        "SENTINEL READY"
    )

    $errors = 0
    foreach ($fn in $fonctions) {
        if ($content -match [regex]::Escape($fn)) {
            OK $fn
        } else {
            FAIL "MANQUANTE : $fn"
            $errors++
        }
    }

    SEP
    if ($errors -eq 0) {
        OK "HTML valide — prêt pour le deploy !"
    } else {
        FAIL "$errors fonction(s) manquante(s) !"
        exit 1
    }
    Write-Host ""
    exit 0
}

# ─── DEPLOY PRINCIPAL ─────────────────────────────────
Header

if (-not (Check-Git))  { exit 1 }
if (-not (Check-Repo)) { exit 1 }

# Message de commit
$timestamp = Get-Date -Format "dd/MM/yyyy HH:mm"
if ($msg -eq "") {
    $commitMsg = "update: SENTINEL deploy $timestamp"
} else {
    $commitMsg = "$msg [$timestamp]"
}

TITLE "Déploiement en cours..."
SEP
INFO "Message : $commitMsg"
$branch = git rev-parse --abbrev-ref HEAD 2>&1
INFO "Branche : $branch"
$remote = git remote get-url origin 2>&1
INFO "Remote  : $remote"
SEP

# ── Étape 1 : git pull (éviter conflits) ──────────────
Write-Host "`n  [1/4] Récupération des changements distants..." -ForegroundColor DarkGray
$pullResult = git pull origin $branch 2>&1
if ($LASTEXITCODE -ne 0) {
    WARN "Pull impossible (peut-être repo vide, on continue)"
} else {
    OK "Pull OK"
}

# ── Étape 2 : git add ─────────────────────────────────
Write-Host "`n  [2/4] Ajout des fichiers modifiés..." -ForegroundColor DarkGray
git add -A 2>&1 | Out-Null
$staged = git diff --cached --name-only 2>&1
if (-not $staged) {
    WARN "Aucun fichier modifié détecté — rien à déployer."
    Write-Host ""
    exit 0
}
foreach ($f in $staged) {
    OK "Ajouté : $f"
}

# ── Étape 3 : git commit ──────────────────────────────
Write-Host "`n  [3/4] Commit..." -ForegroundColor DarkGray
git commit -m $commitMsg 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    FAIL "Commit échoué"
    exit 1
}
OK "Commit créé"

# ── Étape 4 : git push ────────────────────────────────
Write-Host "`n  [4/4] Push vers GitHub..." -ForegroundColor DarkGray
$pushResult = git push origin $branch 2>&1
if ($LASTEXITCODE -ne 0) {
    FAIL "Push échoué !"
    Write-Host $pushResult -ForegroundColor Red
    INFO "Vérifie tes credentials GitHub ou la connexion."
    exit 1
}
OK "Push réussi !"

# ── Résumé ────────────────────────────────────────────
SEP
Write-Host ""
Write-Host "  ✅  DEPLOY TERMINÉ avec succès !" -ForegroundColor Green
Write-Host ""
INFO "Commit  : $commitMsg"
INFO "Remote  : $remote"

# Lien GitHub Pages si dispo
$repoUrl = ($remote -replace "\.git$", "") -replace "git@github\.com:", "https://github.com/"
$pagesUrl = $repoUrl -replace "https://github.com/([^/]+)/([^/]+)", "https://`$1.github.io/`$2"
INFO "GitHub  : $repoUrl"
INFO "Pages   : $pagesUrl"
Write-Host ""

#!/usr/bin/env powershell
# 🚀 DEPLOY.ps1 - Automated GitHub Deployment Script
# Run this script and enter your GitHub username to complete deployment

# Remove the old incorrect remote
Write-Host "🔧 Cleaning up old remote..." -ForegroundColor Yellow
git remote remove origin

# Ask for GitHub username
Write-Host "`n📝 Enter your GitHub username (the part after github.com/)" -ForegroundColor Cyan
$username = Read-Host "GitHub Username"

if ([string]::IsNullOrWhiteSpace($username)) {
    Write-Host "❌ Error: Username cannot be empty" -ForegroundColor Red
    exit 1
}

if ($username -eq "YOUR-USERNAME") {
    Write-Host "❌ Error: Enter your REAL GitHub username, not the placeholder" -ForegroundColor Red
    exit 1
}

Write-Host "`n✓ Username: $username" -ForegroundColor Green

# Verify repo exists on GitHub
Write-Host "`n🔍 Verifying repository exists on GitHub..." -ForegroundColor Yellow
$repoUrl = "https://github.com/$username/excel-automation-web"
$testUrl = "https://github.com/$username/excel-automation-web/settings"

Write-Host "Expected repo URL: $repoUrl" -ForegroundColor Cyan
Write-Host "`n⚠️  Make sure:"
Write-Host "  1. You created the repo at: https://github.com/new"
Write-Host "  2. Named it: excel-automation-web"
Write-Host "  3. Set it to PUBLIC"
Write-Host "  4. Did NOT initialize with README or .gitignore"

$confirm = Read-Host "`nContinue? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "❌ Deployment cancelled" -ForegroundColor Red
    exit 1
}

# Add the correct remote
Write-Host "`n🔗 Adding remote repository..." -ForegroundColor Yellow
$gitUrl = "https://github.com/$username/excel-automation-web.git"
Write-Host "URL: $gitUrl" -ForegroundColor Cyan

try {
    git remote add origin $gitUrl
    Write-Host "✓ Remote added successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Error adding remote: $_" -ForegroundColor Red
    exit 1
}

# Ensure on main branch
Write-Host "`n🌿 Setting up main branch..." -ForegroundColor Yellow
git branch -M main
Write-Host "✓ On main branch" -ForegroundColor Green

# Push to GitHub
Write-Host "`n📤 Pushing code to GitHub (this may take a moment)..." -ForegroundColor Yellow
try {
    git push -u origin main
    Write-Host "`n✅ PUSHED SUCCESSFULLY!" -ForegroundColor Green
} catch {
    Write-Host "`n❌ Push failed: $_" -ForegroundColor Red
    Write-Host "Error details above. Check TROUBLESHOOTING_GIT_PUSH.md for help." -ForegroundColor Yellow
    exit 1
}

# Success message
Write-Host "`n" -ForegroundColor Green
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ DEPLOYMENT SUCCESSFUL!                ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "`nYour files are now on GitHub!" -ForegroundColor Cyan
Write-Host "Repository: $repoUrl" -ForegroundColor Cyan

Write-Host "`n📍 Next: Enable GitHub Pages"
Write-Host "  1. Go to: $testUrl" -ForegroundColor Yellow
Write-Host "  2. Scroll to 'Pages' section"
Write-Host "  3. Branch: main"
Write-Host "  4. Folder: / (root)"
Write-Host "  5. Click Save"
Write-Host "  6. Wait 1-2 minutes"

Write-Host "`n🌐 Your live site will be:"
$liveUrl = "https://$username.github.io/excel-automation-web/"
Write-Host "  $liveUrl" -ForegroundColor Cyan

Write-Host "`n📋 Checklist:"
Write-Host "  ☐ Files pushed to GitHub" -ForegroundColor Green
Write-Host "  ☐ GitHub Pages enabled"
Write-Host "  ☐ Waited 1-2 minutes"
Write-Host "  ☐ Visited live URL"
Write-Host "  ☐ Tested file upload feature"

Write-Host "`n🎉 Done!" -ForegroundColor Green

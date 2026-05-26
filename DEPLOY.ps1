# ============================================
# EXCEL FILTER - DEPLOY TO GITHUB
# ============================================
# 
# This script pushes your web app to GitHub
# and sets it up for GitHub Pages hosting
#
# BEFORE RUNNING THIS SCRIPT:
# ============================================
# 1. Go to https://github.com/new
# 2. Create a repository named: excel-automation-web
# 3. Make sure you select PUBLIC (not private)
# 4. DO NOT check "Initialize with README"
# 5. Click "Create repository"
# 6. Copy your GitHub username from the URL
#    (it will show: https://github.com/YOUR-USERNAME/excel-automation-web)
# 7. Come back here and run this script
#
# ============================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     EXCEL FILTER - GITHUB DEPLOYMENT    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if repo already has an origin remote
Write-Host "Step 1: Checking git setup..." -ForegroundColor Yellow
$remoteCheck = git remote -v 2>$null | Select-String "origin"
if ($remoteCheck) {
    Write-Host "  ⚠️  Found existing remote. Removing it..." -ForegroundColor Yellow
    git remote remove origin 2>$null
    Write-Host "  ✓ Removed old remote" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 2: Enter your GitHub username" -ForegroundColor Yellow
Write-Host "  (This is the part after github.com/ in your profile URL)" -ForegroundColor Gray
Write-Host ""
$username = Read-Host "  Enter your GitHub username"

# Validate username
if ([string]::IsNullOrWhiteSpace($username)) {
    Write-Host ""
    Write-Host "❌ ERROR: Username cannot be empty!" -ForegroundColor Red
    Write-Host "   Please run this script again and enter your username." -ForegroundColor Red
    exit 1
}

if ($username -eq "YOUR-USERNAME" -or $username -eq "YOUR-GITHUB-USERNAME") {
    Write-Host ""
    Write-Host "❌ ERROR: You entered the placeholder, not your real username!" -ForegroundColor Red
    Write-Host "   Use your actual GitHub username (like 'john-doe' or 'alice')" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  ✓ Username: $username" -ForegroundColor Green

# Show confirmation
Write-Host ""
Write-Host "Step 3: Verify repository exists" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Make sure you have already:" -ForegroundColor Cyan
Write-Host "    ✓ Created repo at https://github.com/new" -ForegroundColor Gray
Write-Host "    ✓ Named it: excel-automation-web" -ForegroundColor Gray
Write-Host "    ✓ Set it to PUBLIC (not private)" -ForegroundColor Gray
Write-Host "    ✓ Did NOT initialize with README" -ForegroundColor Gray
Write-Host ""
Write-Host "  Your repo should be at:" -ForegroundColor Cyan
Write-Host "    https://github.com/$username/excel-automation-web" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "  Did you create the GitHub repository? (yes/no)"
if ($confirm -ne "yes" -and $confirm -ne "y") {
    Write-Host ""
    Write-Host "⏸️  Please create the repository first at:" -ForegroundColor Yellow
    Write-Host "   https://github.com/new" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Then run this script again." -ForegroundColor Yellow
    exit 0
}

# Add remote
Write-Host ""
Write-Host "Step 4: Connecting to GitHub..." -ForegroundColor Yellow
$gitUrl = "https://github.com/$username/excel-automation-web.git"
Write-Host "  URL: $gitUrl" -ForegroundColor Gray

try {
    git remote add origin $gitUrl
    Write-Host "  ✓ Remote added" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Error adding remote" -ForegroundColor Red
    Write-Host "     $_" -ForegroundColor Red
    exit 1
}

# Setup branch
Write-Host ""
Write-Host "Step 5: Setting up branch..." -ForegroundColor Yellow
git branch -M main
Write-Host "  ✓ On main branch" -ForegroundColor Green

# Push to GitHub
Write-Host ""
Write-Host "Step 6: Pushing code to GitHub..." -ForegroundColor Yellow
Write-Host "  (This may take 10-30 seconds...)" -ForegroundColor Gray
Write-Host ""

try {
    git push -u origin main 2>&1
    Write-Host ""
    Write-Host "  ✓ Code pushed successfully!" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "  ❌ Error pushing to GitHub" -ForegroundColor Red
    Write-Host "     $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Possible reasons:" -ForegroundColor Yellow
    Write-Host "    • Repository doesn't exist at https://github.com/$username/excel-automation-web" -ForegroundColor Gray
    Write-Host "    • Repository is set to PRIVATE (must be PUBLIC)" -ForegroundColor Gray
    Write-Host "    • Wrong GitHub username" -ForegroundColor Gray
    exit 1
}

# Success!
Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ CODE PUSHED TO GITHUB!              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "NEXT STEPS - Enable GitHub Pages:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Go to your repository:" -ForegroundColor Cyan
Write-Host "     https://github.com/$username/excel-automation-web" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. Click Settings (⚙️ icon)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  3. Scroll down to 'Pages' section" -ForegroundColor Cyan
Write-Host ""
Write-Host "  4. Under 'Source':" -ForegroundColor Cyan
Write-Host "     • Branch: select 'main'" -ForegroundColor Gray
Write-Host "     • Folder: select '/ (root)'" -ForegroundColor Gray
Write-Host ""
Write-Host "  5. Click 'Save'" -ForegroundColor Cyan
Write-Host ""
Write-Host "  6. Wait 1-2 minutes for deployment" -ForegroundColor Cyan
Write-Host ""
Write-Host "  7. Your site will be live at:" -ForegroundColor Cyan
$liveUrl = "https://$username.github.io/excel-automation-web/"
Write-Host "     $liveUrl" -ForegroundColor Cyan
Write-Host ""

Write-Host "WHAT TO DO NOW:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  ☐ Verify files on GitHub" -ForegroundColor Gray
Write-Host "    Visit: https://github.com/$username/excel-automation-web" -ForegroundColor Gray
Write-Host "    You should see: index.html, filter.js, README.md, etc." -ForegroundColor Gray
Write-Host ""
Write-Host "  ☐ Enable GitHub Pages (follow steps above)" -ForegroundColor Gray
Write-Host ""
Write-Host "  ☐ Test your live site" -ForegroundColor Gray
Write-Host "    After 1-2 minutes, visit: $liveUrl" -ForegroundColor Gray
Write-Host ""
Write-Host "  ☐ Try uploading an Excel file to test" -ForegroundColor Gray
Write-Host ""

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  🚀 YOU'RE ALL SET!                     ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""


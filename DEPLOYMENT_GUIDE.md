# 🚀 Deployment Guide - Excel Production Filter Web Version

This guide will help you push this project to GitHub and enable GitHub Pages hosting.

## 📋 Prerequisites

- GitHub account (free at github.com)
- Git installed on your computer
- Command line/PowerShell access

## 🔧 Step-by-Step Setup

### 1. Create a New Repository on GitHub

1. Go to https://github.com/new
2. Enter Repository Name: `excel-automation-web` (or your preferred name)
3. Add Description: "Web-based Excel production data filter with unified filtering"
4. Choose Public (so it can be hosted on GitHub Pages)
5. Click "Create repository"

### 2. Get Your Repository URL

After creating, you'll see a page with:
```
https://github.com/YOUR-USERNAME/excel-automation-web.git
```
Copy this URL.

### 3. Push to GitHub

Open PowerShell in `C:\Users\Suriya.nagappan\excel-automation-web` and run:

```powershell
# Add remote repository
git remote add origin https://github.com/YOUR-USERNAME/excel-automation-web.git

# Rename branch to main (GitHub Pages requirement)
git branch -M main

# Push to GitHub
git push -u origin main
```

Replace `YOUR-USERNAME` with your actual GitHub username.

### 4. Enable GitHub Pages

1. Go to your repository on GitHub
2. Click Settings (gear icon)
3. Scroll to "GitHub Pages" section
4. Under "Source", select:
   - Branch: `main`
   - Folder: `/ (root)`
5. Click Save

### 5. Get Your Live URL

After a few seconds (up to 1 minute), your site will be live at:

```
https://YOUR-USERNAME.github.io/excel-automation-web/
```

## ✅ Verify It Works

1. Wait 1-2 minutes for GitHub Pages to build
2. Visit `https://YOUR-USERNAME.github.io/excel-automation-web/`
3. You should see the Excel Production Filter web app
4. Try uploading a test file

## 🔄 Making Updates

After you make changes locally:

```powershell
# Stage changes
git add .

# Commit
git commit -m "your change description"

# Push to GitHub
git push
```

GitHub Pages will automatically update within seconds!

## 📱 Share Your App

Your live URL is:
```
https://YOUR-USERNAME.github.io/excel-automation-web/
```

You can share this link with anyone - they can use the filter app directly from the browser!

## 🔒 Repository Settings

For a public app like this, these settings are recommended:

1. **GitHub Pages Settings**:
   - Source: Deploy from branch
   - Branch: main / (root)
   - Enforce HTTPS: Enable

2. **Repository Settings**:
   - Visibility: Public
   - Issues: Enable (for bug reports)
   - Discussions: Optional

## 🆘 Troubleshooting

**"GitHub Pages not showing"**
- Wait 1-2 minutes, then refresh
- Check Settings → Pages shows green checkmark
- Verify branch is set to "main"

**"404 Not Found"**
- Check your URL includes your username and repo name
- Verify files (index.html, filter.js) are in root directory
- Try opening index.html directly

**"Changes not updating"**
- Clear browser cache (Ctrl+Shift+Delete)
- Wait 30 seconds for GitHub Pages to rebuild
- Check git push was successful (`git log` should show your commit)

## 📊 Current Repository Structure

```
excel-automation-web/
├── index.html          # Main web app UI
├── filter.js           # Unified filter logic
├── README_WEB.md       # Web version documentation
├── README.md           # Original documentation
├── FilterMacro.bas     # VBA macro (reference)
├── .gitignore          # Git ignore rules
├── .git/               # Git repository (local only)
└── [other docs]        # Original documentation files
```

## 🎯 What's Live

Once deployed, users can:

1. ✅ Upload Excel files directly to their browser
2. ✅ Apply unified filters (Production Status + Hold Status + Date Range)
3. ✅ Preview results before downloading
4. ✅ Download filtered data as a new Excel file
5. ✅ No data leaves their browser (all processing local)

## 🆔 GitHub Pages URL Format

The URL follows this pattern:
```
https://[GITHUB-USERNAME].github.io/[REPOSITORY-NAME]/
```

For example:
- If your username is `john-doe` and repo is `excel-automation-web`
- Your live URL is: `https://john-doe.github.io/excel-automation-web/`

## 📝 Example Push Commands

```powershell
# One-time setup
cd "C:\Users\Suriya.nagappan\excel-automation-web"
git remote add origin https://github.com/YOUR-USERNAME/excel-automation-web.git
git branch -M main
git push -u origin main

# Future updates
git add .
git commit -m "Update description here"
git push

# View commit history
git log --oneline
```

## ✨ Next Steps

1. Create the GitHub repository
2. Run the push commands above
3. Enable GitHub Pages
4. Share the live URL: `https://YOUR-USERNAME.github.io/excel-automation-web/`
5. Start using the web app!

---

**Need help?** Check the GitHub Pages documentation: https://pages.github.com/

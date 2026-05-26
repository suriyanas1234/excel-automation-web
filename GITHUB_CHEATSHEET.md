# 🎯 GitHub Deployment Cheat Sheet

## ❌ Error You Got
```
Repository not found
```

## ✅ What's Wrong
`YOUR-USERNAME` is a **placeholder** - you must replace it with your real GitHub username

---

## 🚀 Quick Fix (3 Steps)

### Step 1️⃣ Create Repo
**Go here**: https://github.com/new
- Name: `excel-automation-web`
- Make it **PUBLIC**
- Click Create

### Step 2️⃣ Get Your URL
After creating, GitHub shows:
```
https://github.com/YOUR-GITHUB-USERNAME/excel-automation-web.git
```

Copy your full URL (it will have your real username, not "YOUR-USERNAME")

### Step 3️⃣ Run This Command
Open PowerShell and paste:
```powershell
cd "C:\Users\Suriya.nagappan\excel-automation-web"
git remote add origin [PASTE-YOUR-URL-HERE]
git branch -M main
git push -u origin main
```

**Example** (if your GitHub username is `alice`):
```powershell
cd "C:\Users\Suriya.nagappan\excel-automation-web"
git remote add origin https://github.com/alice/excel-automation-web.git
git branch -M main
git push -u origin main
```

---

## 📋 Checklist

- [ ] Created GitHub account? (free)
- [ ] Logged into GitHub? 
- [ ] Created `excel-automation-web` repo?
- [ ] Set it to PUBLIC?
- [ ] Copied the full URL from GitHub?
- [ ] Replaced [PASTE-YOUR-URL-HERE] with your actual URL?
- [ ] Ran the PowerShell commands?

---

## ✨ Success = Files Appear on GitHub

Visit: `https://github.com/YOUR-USERNAME/excel-automation-web`

You should see:
- index.html ✓
- filter.js ✓
- All markdown files ✓

---

## 🌐 Enable GitHub Pages

1. Go to your repo on GitHub
2. Click **Settings** ⚙️
3. Find **Pages**
4. Branch: `main`
5. Folder: `/` (root)
6. Click **Save**

**Your live site**: `https://YOUR-USERNAME.github.io/excel-automation-web/`

---

## 🔍 Troubleshooting

**Still says "Repository not found"?**
- [ ] Did you create the repo on GitHub first?
- [ ] Is your username correct (not "YOUR-USERNAME")?
- [ ] Is the repo set to PUBLIC?
- [ ] Did you copy the exact URL from GitHub?

**See TROUBLESHOOTING_GIT_PUSH.md for more help**

---

**That's it! After 1-2 minutes, your site will be live! 🎉**

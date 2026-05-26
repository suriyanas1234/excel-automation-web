# Excel Production Filter

A simple web app to filter production Excel files.

## What It Does

1. **Upload** - Drag-drop or click to upload your Excel file
2. **Auto-Filter** - Automatically filters based on production rules
3. **Download** - Download the filtered file with results

## Filter Rules

**Keeps rows where:**
- ProductionStatus = "Released" AND no WOHoldDescription, OR
- ProductionStatus is blank AND CurrentDepartment = "MATL ISSUE EXT" AND no WOHoldDescription

**Removes rows where:**
- WOHoldDescription has any value, OR
- ProductionStatus doesn't match the rules above

## Features

- Drag-drop file upload
- Auto-processes on upload
- Shows filtered row count
- Downloads as Excel file
- Works in any browser
- All processing happens locally (no server)
- Supports .xlsx, .xls, .csv

## How to Deploy

1. Create GitHub repo: https://github.com/new
   - Name: `excel-automation-web`
   - Make it **PUBLIC**

2. Deploy:
   ```powershell
   cd "C:\Users\Suriya.nagappan\excel-automation-web"
   .\DEPLOY.ps1
   ```

3. Enable GitHub Pages in Settings:
   - Pages → Branch: main, Folder: /

4. Visit: `https://YOUR-USERNAME.github.io/excel-automation-web/`

## Files

- `index.html` - Web app interface
- `filter.js` - Filter logic
- `DEPLOY.ps1` - Automated deployment script
- `FilterMacro.bas` - Original Excel macro

## Privacy

- No server uploads
- No tracking
- All processing in your browser
- Safe for sensitive data

---

**Version:** 1.0  
**Status:** Ready to Deploy

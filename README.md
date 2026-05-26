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

- **Drag-drop file upload** - Simple, intuitive interface
- **Auto-processes on upload** - Instant filtering
- **Shows filtered row count** - Original, filtered, and removed row counts
- **Downloads as Excel file** - Fully formatted with:
  - ✅ White fill and Arial 12pt bold text
  - ✅ Borders on all cells
  - ✅ Past dates highlighted in YELLOW
  - ✅ Page breaks inserted for each new day
  - ✅ Sorted by DockDate (today through +7 days, plus all past dates)
- **Works in any browser** - No installation needed
- **All processing happens locally** - No server uploads, no tracking
- **Supports .xlsx, .xls, .csv** - Works with all Excel formats

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
- `ProductionCleanupMacro.bas` - **NEW** Comprehensive cleanup macro with formatting, filtering, and page breaks

## Excel Macro (ProductionCleanupMacro.bas)

Complete Excel macro that cleans and organizes production data:

**What it does:**
- Formats: White fill, Arial 12pt bold, borders on all cells
- Columns: Keeps only 43 required columns
- Filters: By ProductionStatus, Department, WOHoldDescription, and DockDate
- Sorting: Organizes by DockDate (today ± 7 days + past dates)
- Highlights: Past-due dates in yellow
- Page breaks: One per day for printing/organizing
- Error handling: Validates headers, graceful fallbacks

**How to use:**
1. Open your Excel file
2. Press `Alt+F11` → File → Import File → select `ProductionCleanupMacro.bas`
3. Press `Alt+F8` → Select `CleanAndOrganizeWorksheet` → Click Run
4. Follow the on-screen messages

## Privacy

- No server uploads
- No tracking
- All processing in your browser
- Safe for sensitive data

---

**Version:** 1.0  
**Status:** Ready to Deploy

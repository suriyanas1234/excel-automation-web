# Excel Production Filter - Simple Web Version

A simple web application to filter production Excel files.

## 🚀 How It Works

1. **Upload** your Excel file (drag & drop or click)
2. **Auto-filter** applies instantly
3. **Download** the processed file

That's it!

## 🎯 What Gets Filtered

**KEPT Rows:**
- ProductionStatus = "Released" AND WOHoldDescription is blank, OR
- ProductionStatus is blank AND CurrentDepartment = "MATL ISSUE EXT" AND WOHoldDescription is blank

**REMOVED Rows:**
- WOHoldDescription is not blank
- ProductionStatus is not "Released" or blank
- If blank ProductionStatus, then CurrentDepartment ≠ "MATL ISSUE EXT"

## ✨ Features

- ✅ Drag & drop file upload
- ✅ Automatic filtering on upload
- ✅ Shows how many rows were filtered
- ✅ Download as Excel file with timestamp
- ✅ Works in any browser
- ✅ All processing happens locally (no server)
- ✅ No options or configuration needed

## 🌐 Use It

Visit: `https://YOUR-USERNAME.github.io/excel-automation-web/`

## 💻 Supported Formats

- .xlsx (Excel 2007+)
- .xls (Excel 97-2003)
- .csv (Comma-separated values)

## 🔒 Privacy

- ✓ No data sent to any server
- ✓ All processing happens in your browser
- ✓ Files never leave your computer
- ✓ Safe for sensitive data

---

**Version**: 1.0  
**Status**: Simple & Ready  
**Last Updated**: May 26, 2026


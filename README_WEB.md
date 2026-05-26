# Excel Production Filter - Web Version

A modern web application to filter and process production Excel files with a single unified filter.

## 🚀 Features

- **Single Unified Filter**: Combines Production Status, Hold Status, and Date Range filtering
- **File Upload**: Drag & drop or click to upload Excel files (.xlsx, .xls, .csv)
- **Live Preview**: See filtered results with a 10-row preview table
- **Download Results**: Export filtered data as a new Excel file with timestamp
- **No Backend Required**: All processing happens in your browser
- **Responsive Design**: Works on desktop and mobile devices

## 📋 What It Does

The unified filter keeps rows that meet ALL of these criteria:
1. **Hold Status**: Row has no WOHoldDescription (blank) OR has a hold description (based on selection)
2. **Production Status**: Matches selected status (Released, In Progress, etc.)
3. **Date Range**: DockDate or RecommitDate falls within today through the selected date
4. **Department**: If specified, CurrentDepartment contains the search term

## 🎯 How to Use

1. **Upload**: Click or drag-drop your Excel file
2. **Configure Filters**:
   - Select Production Status (optional)
   - Choose Hold Status preference
   - Set date range
   - Enter department filter (optional)
3. **Process**: Click "Process File" to apply filters
4. **Review**: Check the preview table
5. **Download**: Click "Download Result" to get the filtered Excel file

## 📊 Filter Options

- **Production Status**: Any, Released, In Progress, On Hold, or blank
- **Hold Status**: Any, No Hold (Blank), or On Hold (Has Description)
- **Date Range**: From today through your selected date
- **Department**: Optional - enter department name to filter

## 🔧 Comparison: Macro vs Web Version

### Excel Macro (FilterMacro.bas)
- ✓ 7-step complex filtering process
- ✓ Multi-column reordering (47 columns)
- ✓ Advanced formatting and highlighting
- ✓ Page breaks for printing
- ✓ Runs directly in Excel
- ✗ Requires VBA knowledge to modify

### Web Version (index.html + filter.js)
- ✓ Single unified filter (easier to understand)
- ✓ Works in any modern browser
- ✓ No Excel installation required
- ✓ Instant file upload and processing
- ✓ Real-time preview
- ✓ Download filtered data anytime
- ✗ Simpler formatting (focuses on data filtering)

**Key Difference**: The web version simplifies the macro's 7-step process into ONE unified filter that considers Production Status, Hold Status, and Date Range together.

## 🌐 Hosting

This application is hosted on GitHub Pages:
**[Live URL will be available after deployment]**

## 💻 Local Development

1. Clone the repository
2. Open `index.html` in a web browser
3. No build process or dependencies needed!

## 📦 Technical Stack

- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Data Processing**: XLSX.js library for Excel file handling
- **Hosting**: GitHub Pages (static files)

## 🔒 Privacy

- ✓ All data processing happens in your browser
- ✓ No files are uploaded to any server
- ✓ No tracking or analytics
- ✓ Safe to use with sensitive data

## 📄 Files

- `index.html` - Main application UI
- `filter.js` - Filtering logic and file processing
- `README.md` - Documentation (this file)

## 🐛 Troubleshooting

**File won't upload**
- Ensure file is in .xlsx, .xls, or .csv format
- Check file size (should be < 10MB)
- Try a different browser

**No rows after filtering**
- Check your filter criteria are not too restrictive
- Verify column headers match expected names (e.g., "DockDate", "ProductionStatus")
- Try "Any Status" and "Any Hold Status" for less restrictive filtering

**Downloaded file is empty**
- Ensure at least 1 row passed the filters
- Check the preview table shows data before downloading

## 📞 Support

For issues or feature requests, please open an issue on GitHub.

## 📝 License

MIT License - Feel free to use and modify

---

**Version**: 1.0  
**Last Updated**: May 26, 2026  
**Status**: Production Ready

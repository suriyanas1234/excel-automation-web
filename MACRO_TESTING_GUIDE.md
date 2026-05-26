# Testing the ProductionCleanupMacro

## How to Test the Macro

### Quick Test Setup:

1. **Create a test Excel file** with sample data:
   - Header row with all required columns (at minimum: DockDate, ProductionStatus, WOHoldDescription, CurrentDepartment)
   - Add test rows with various scenarios:
     - Row 1: ProductionStatus = "Released", past DockDate, blank WOHoldDescription → KEEP & HIGHLIGHT YELLOW
     - Row 2: ProductionStatus = blank, CurrentDepartment = "MATL ISSUE EXT", today's date → KEEP
     - Row 3: ProductionStatus = "Released", future date (+3 days), blank WOHoldDescription → KEEP
     - Row 4: ProductionStatus = blank, CurrentDepartment = "OTHER", today's date → DELETE (doesn't match filter)
     - Row 5: ProductionStatus = "Released", past date, WOHoldDescription = "On Hold" → DELETE (has hold description)

### Expected Results:

**After running CleanAndOrganizeWorksheet macro:**

1. ✅ **Columns**: Only 43 required columns kept (all others deleted)
2. ✅ **Rows**: Only rows matching filter criteria remain
3. ✅ **Formatting**: 
   - All cells: White fill, Arial 12pt, bold text, black borders
   - Past-due dates: Yellow fill with bold text
4. ✅ **Sorting**: Rows organized by DockDate (ascending - oldest to newest)
5. ✅ **Page Breaks**: One page break before each new date

### Import Instructions:

1. Open Excel
2. Press Alt+F11 to open VBA Editor
3. File → Import File → select ProductionCleanupMacro.bas
4. Close editor
5. Press Alt+F8
6. Select "CleanAndOrganizeWorksheet"
7. Click Run

### What You'll See:

- Message showing process starting
- Progress through each step
- Message showing completion with results

### Troubleshooting:

**No highlighting appearing:**
- Check that your dates are in proper Excel date format
- Make sure DockDate column exists and is named exactly "DockDate"

**Page breaks not showing:**
- View → Page Break Preview to see page breaks
- Print Preview also shows where page breaks occur

**Sorting not working:**
- Verify DockDate column is recognized (column name must be exact match)
- Check that dates are actual date values, not text

**Columns not deleted:**
- If direct deletion fails, macro automatically creates a new "Cleaned" sheet
- Check for new sheet with cleaned data

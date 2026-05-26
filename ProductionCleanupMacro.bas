Attribute VB_Name = "ProductionCleanup"
Option Explicit

' ============================================================
'  PRODUCTION DATA CLEANUP AND ORGANIZATION
'  Complete macro with formatting, filtering, and page breaks
'
'  How to use:
'    1. Open your workbook in Excel
'    2. Press Alt+F11 → File → Import File → select this .bas
'    3. Press Alt+F8 → Run "CleanAndOrganizeWorksheet"
' ============================================================

Sub CleanAndOrganizeWorksheet()
    On Error GoTo ErrorHandler
    
    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual
    Application.EnableEvents = False
    
    Dim ws As Worksheet
    Set ws = ActiveSheet
    
    MsgBox "Starting Production Cleanup..." & vbCrLf & vbCrLf & _
           "Process:" & vbCrLf & _
           "1. Verify headers" & vbCrLf & _
           "2. Keep only required columns" & vbCrLf & _
           "3. Filter by ProductionStatus & Department" & vbCrLf & _
           "4. Remove rows with WOHoldDescription" & vbCrLf & _
           "5. Filter by DockDate (today ± 7 days + past)" & vbCrLf & _
           "6. Sort by DockDate" & vbCrLf & _
           "7. Format all cells" & vbCrLf & _
           "8. Highlight past dates in yellow" & vbCrLf & _
           "9. Insert page breaks by day", _
           vbInformation, "Starting Process"
    
    ' Check for all required headers first
    Dim missingHeaders As String
    missingHeaders = VerifyAllRequiredHeaders(ws)
    If missingHeaders <> "" Then
        Application.ScreenUpdating = True
        Application.Calculation = xlCalculationAutomatic
        Application.EnableEvents = True
        MsgBox "ERROR - Missing required headers:" & vbCrLf & vbCrLf & missingHeaders, _
               vbCritical, "Missing Headers"
        Exit Sub
    End If
    
    ' Execute all cleanup steps in order
    Call Step1_KeepRequiredColumnsOnly(ws)
    Call Step2_FilterByProductionStatus(ws)
    Call Step3_RemoveHoldRows(ws)
    Call Step4_FilterByDockDate(ws)
    Call Step5_SortByDockDate(ws)
    Call Step6_FormatUsedRange(ws)
    Call Step7_HighlightPastDockDates(ws)
    Call Step8_InsertPageBreaksByDay(ws)
    
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    Application.EnableEvents = True
    
    MsgBox "✓ Cleanup complete!" & vbCrLf & vbCrLf & _
           "• Only required columns kept" & vbCrLf & _
           "• Data filtered by status & hold" & vbCrLf & _
           "• Sorted by DockDate" & vbCrLf & _
           "• Past dates highlighted in yellow" & vbCrLf & _
           "• Page breaks inserted by day", _
           vbInformation, "Process Complete"
    
    Exit Sub
ErrorHandler:
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    Application.EnableEvents = True
    MsgBox "Error: " & Err.Description, vbCritical, "Error"
End Sub

' ============================================================
' STEP 0: Verify all required headers exist
' ============================================================
Function VerifyAllRequiredHeaders(ws As Worksheet) As String
    Dim requiredHeaders As Variant
    requiredHeaders = Array( _
        "WONumber", "PriorityCode", "SoldTo", "PartNumber", _
        "CustomerPartNumber", "Revision", "OraclePartNumber", _
        "WOScheduleDate", "SalesOrderQuantity", "ReservedQty", _
        "CurrentDepartment", "NextProcess", "BoardsQty", "Up", _
        "BoardsWIP", "BoardsRej", "PanelsWIP", "DockDate", _
        "OrderValue", "SOChecklist", "Hours", "RecommitDate", _
        "Eng_HoldTags_Last_Reason", "PanelSubCore", "PanelSize", _
        "LAYERS", "BoardWidth", "BoardHeight", _
        "DateInDepartment_Local", "ProductionStatus", _
        "WOOnHoldCode", "WOHoldDescription", "SOOnHoldCode", _
        "SOHoldDescription", "StepNum", "MaxStep", _
        "PercentComplete", "SalesOrder", "RevisionType", _
        "OracleLineItem", "PONumber", "TurnTime", "BasePrice", _
        "OpenQty", "PremiumPrice", "RemakeSlant", _
        "Eng_HoldTags_Count")
    
    Dim headerRow As Range
    Set headerRow = ws.Rows(1)
    
    Dim missing As String
    Dim i As Long
    Dim found As Boolean
    Dim col As Long
    
    missing = ""
    
    For i = LBound(requiredHeaders) To UBound(requiredHeaders)
        found = False
        For col = 1 To headerRow.Columns.Count
            If Trim(headerRow.Cells(1, col).Value) = requiredHeaders(i) Then
                found = True
                Exit For
            End If
        Next col
        If Not found Then
            missing = missing & requiredHeaders(i) & vbCrLf
        End If
    Next i
    
    VerifyAllRequiredHeaders = missing
End Function

' ============================================================
' STEP 1: Keep only required columns
' ============================================================
Sub Step1_KeepRequiredColumnsOnly(ws As Worksheet)
    On Error GoTo ErrorHandler
    
    Dim requiredHeaders As Variant
    requiredHeaders = Array( _
        "WONumber", "PriorityCode", "SoldTo", "PartNumber", _
        "CustomerPartNumber", "Revision", "OraclePartNumber", _
        "WOScheduleDate", "SalesOrderQuantity", "ReservedQty", _
        "CurrentDepartment", "NextProcess", "BoardsQty", "Up", _
        "BoardsWIP", "BoardsRej", "PanelsWIP", "DockDate", _
        "OrderValue", "SOChecklist", "Hours", "RecommitDate", _
        "Eng_HoldTags_Last_Reason", "PanelSubCore", "PanelSize", _
        "LAYERS", "BoardWidth", "BoardHeight", _
        "DateInDepartment_Local", "ProductionStatus", _
        "WOOnHoldCode", "WOHoldDescription", "SOOnHoldCode", _
        "SOHoldDescription", "StepNum", "MaxStep", _
        "PercentComplete", "SalesOrder", "RevisionType", _
        "OracleLineItem", "PONumber", "TurnTime", "BasePrice", _
        "OpenQty", "PremiumPrice", "RemakeSlant", _
        "Eng_HoldTags_Count")
    
    Dim headerRow As Range
    Set headerRow = ws.Rows(1)
    
    Dim col As Long
    Dim found As Boolean
    Dim i As Long
    Dim columnsToDelete As Collection
    Set columnsToDelete = New Collection
    
    ' Identify columns to delete (not in required list)
    For col = headerRow.Columns.Count Down To 1
        found = False
        Dim headerValue As String
        headerValue = Trim(headerRow.Cells(1, col).Value)
        
        For i = LBound(requiredHeaders) To UBound(requiredHeaders)
            If headerValue = requiredHeaders(i) Then
                found = True
                Exit For
            End If
        Next i
        
        If Not found And headerValue <> "" Then
            columnsToDelete.Add col
        End If
    Next col
    
    ' Delete identified columns (from right to left to avoid index shifting)
    Dim deleteCol As Variant
    For Each deleteCol In columnsToDelete
        On Error Resume Next
        ws.Columns(deleteCol).Delete
        On Error GoTo ErrorHandler
    Next deleteCol
    
    Exit Sub
ErrorHandler:
    ' If column deletion fails, copy to new sheet instead
    Call CopyRequiredColumnsToNewSheet(ws, requiredHeaders)
End Sub

Sub CopyRequiredColumnsToNewSheet(ws As Worksheet, requiredHeaders As Variant)
    Dim newWs As Worksheet
    Dim col As Long
    Dim newCol As Long
    Dim lastRow As Long
    Dim i As Long
    Dim found As Boolean
    Dim headerValue As String
    
    ' Create new worksheet
    On Error Resume Next
    Application.DisplayAlerts = False
    ws.Parent.Worksheets("Cleaned").Delete
    Application.DisplayAlerts = True
    On Error GoTo 0
    
    Set newWs = ws.Parent.Sheets.Add
    newWs.Name = "Cleaned"
    
    ' Copy header row with only required columns
    newCol = 1
    For col = 1 To ws.Rows(1).Columns.Count
        headerValue = Trim(ws.Rows(1).Cells(1, col).Value)
        found = False
        
        For i = LBound(requiredHeaders) To UBound(requiredHeaders)
            If headerValue = requiredHeaders(i) Then
                found = True
                Exit For
            End If
        Next i
        
        If found Then
            newWs.Cells(1, newCol).Value = headerValue
            newCol = newCol + 1
        End If
    Next col
    
    ' Copy data rows
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    newCol = 1
    
    For col = 1 To ws.Rows(1).Columns.Count
        headerValue = Trim(ws.Rows(1).Cells(1, col).Value)
        found = False
        
        For i = LBound(requiredHeaders) To UBound(requiredHeaders)
            If headerValue = requiredHeaders(i) Then
                found = True
                Exit For
            End If
        Next i
        
        If found Then
            ws.Range(ws.Cells(2, col), ws.Cells(lastRow, col)).Copy
            newWs.Cells(2, newCol).PasteSpecial xlPasteValues
            newCol = newCol + 1
        End If
    Next col
    
    ' Delete original sheet and rename new one
    Application.DisplayAlerts = False
    ws.Delete
    newWs.Name = ws.Name
    Application.DisplayAlerts = True
End Sub

' ============================================================
' STEP 2: Filter by ProductionStatus
' ============================================================
Sub Step2_FilterByProductionStatus(ws As Worksheet)
    On Error GoTo ErrorHandler
    
    Dim lastRow As Long
    Dim row As Long
    Dim prodStatus As String
    Dim department As String
    Dim prodCol As Long
    Dim deptCol As Long
    
    prodCol = FindColumnByHeader(ws, "ProductionStatus")
    deptCol = FindColumnByHeader(ws, "CurrentDepartment")
    
    If prodCol = 0 Or deptCol = 0 Then Exit Sub
    
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    
    ' Delete from bottom to top to avoid row shifting issues
    For row = lastRow Down To 2
        prodStatus = Trim(ws.Cells(row, prodCol).Value)
        department = Trim(ws.Cells(row, deptCol).Value)
        
        Dim keepRow As Boolean
        keepRow = False
        
        ' Keep if ProductionStatus = "Released"
        If prodStatus = "Released" Then
            keepRow = True
        ' Keep if ProductionStatus is blank AND Department = "MATL ISSUE EXT"
        ElseIf prodStatus = "" And department = "MATL ISSUE EXT" Then
            keepRow = True
        End If
        
        If Not keepRow Then
            On Error Resume Next
            ws.Rows(row).Delete
            On Error GoTo ErrorHandler
        End If
    Next row
    
    Exit Sub
ErrorHandler:
    ' Continue on error
End Sub

' ============================================================
' STEP 3: Remove rows with WOHoldDescription
' ============================================================
Sub Step3_RemoveHoldRows(ws As Worksheet)
    On Error GoTo ErrorHandler
    
    Dim lastRow As Long
    Dim row As Long
    Dim holdDesc As String
    Dim holdCol As Long
    
    holdCol = FindColumnByHeader(ws, "WOHoldDescription")
    If holdCol = 0 Then Exit Sub
    
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    
    ' Delete from bottom to top
    For row = lastRow Down To 2
        holdDesc = Trim(ws.Cells(row, holdCol).Value)
        If holdDesc <> "" Then
            On Error Resume Next
            ws.Rows(row).Delete
            On Error GoTo ErrorHandler
        End If
    Next row
    
    Exit Sub
ErrorHandler:
    ' Continue on error
End Sub

' ============================================================
' STEP 4: Filter by DockDate
' ============================================================
Sub Step4_FilterByDockDate(ws As Worksheet)
    On Error GoTo ErrorHandler
    
    Dim lastRow As Long
    Dim row As Long
    Dim dockDate As Variant
    Dim dockCol As Long
    
    dockCol = FindColumnByHeader(ws, "DockDate")
    If dockCol = 0 Then Exit Sub
    
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    Dim cutoffDate As Date
    cutoffDate = DateAdd("d", 7, Date)
    
    ' Delete from bottom to top
    For row = lastRow Down To 2
        dockDate = ws.Cells(row, dockCol).Value
        
        ' Keep if: today to next 7 days, OR earlier than today
        If IsDate(dockDate) Then
            If CLng(dockDate) > CLng(cutoffDate) Then
                ' Delete if more than 7 days in future
                On Error Resume Next
                ws.Rows(row).Delete
                On Error GoTo ErrorHandler
            End If
        Else
            ' Keep rows with non-date values
        End If
    Next row
    
    Exit Sub
ErrorHandler:
    ' Continue on error
End Sub

' ============================================================
' STEP 5: Sort by DockDate
' ============================================================
Sub Step5_SortByDockDate(ws As Worksheet)
    On Error GoTo ErrorHandler
    
    Dim lastRow As Long
    Dim dockCol As Long
    Dim dataRange As Range
    
    dockCol = FindColumnByHeader(ws, "DockDate")
    If dockCol = 0 Then Exit Sub
    
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    If lastRow < 2 Then Exit Sub
    
    Set dataRange = ws.Range(ws.Cells(1, 1), ws.Cells(lastRow, ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column))
    
    ws.Sort.SortFields.Clear
    With ws.Sort
        .SetRange dataRange
        .SortFields.Add Key:=ws.Columns(dockCol), SortOn:=xlSortOnValues, Order:=xlAscending
        .Header = xlYes
        .Apply
    End With
    
    Exit Sub
ErrorHandler:
    ' Continue on error
End Sub

' ============================================================
' STEP 6: Format all cells
' ============================================================
Sub Step6_FormatUsedRange(ws As Worksheet)
    On Error GoTo ErrorHandler
    
    Dim usedRange As Range
    Set usedRange = ws.UsedRange
    
    ' Apply white fill
    usedRange.Interior.Color = RGB(255, 255, 255)
    
    ' Set font to Arial, size 12, bold
    With usedRange.Font
        .Name = "Arial"
        .Size = 12
        .Bold = True
    End With
    
    ' Apply borders to every cell
    With usedRange.Borders
        .LineStyle = xlContinuous
        .Color = RGB(0, 0, 0)
        .Weight = xlThin
    End With
    
    Exit Sub
ErrorHandler:
    ' Continue on error
End Sub

' ============================================================
' STEP 7: Highlight past DockDates in yellow
' ============================================================
Sub Step7_HighlightPastDockDates(ws As Worksheet)
    On Error GoTo ErrorHandler
    
    Dim lastRow As Long
    Dim row As Long
    Dim dockDate As Variant
    Dim dockCol As Long
    
    dockCol = FindColumnByHeader(ws, "DockDate")
    If dockCol = 0 Then Exit Sub
    
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    
    For row = 2 To lastRow
        dockDate = ws.Cells(row, dockCol).Value
        
        If IsDate(dockDate) Then
            If CLng(dockDate) < CLng(Date) Then
                ' Highlight entire row in yellow
                ws.Rows(row).Interior.Color = RGB(255, 255, 0)
                ws.Rows(row).Font.Bold = True
            End If
        End If
    Next row
    
    Exit Sub
ErrorHandler:
    ' Continue on error
End Sub

' ============================================================
' STEP 8: Insert page breaks by day
' ============================================================
Sub Step8_InsertPageBreaksByDay(ws As Worksheet)
    On Error GoTo ErrorHandler
    
    Dim lastRow As Long
    Dim row As Long
    Dim currentDate As Date
    Dim previousDate As Date
    Dim dockCol As Long
    Dim dockValue As Variant
    
    dockCol = FindColumnByHeader(ws, "DockDate")
    If dockCol = 0 Then Exit Sub
    
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    If lastRow < 3 Then Exit Sub
    
    ' Remove existing page breaks
    ws.PageSetup.PrintArea = ""
    ws.HPageBreaks.Delete
    
    previousDate = CLng(ws.Cells(2, dockCol).Value)
    
    ' Insert page break before each new date (from bottom to top)
    For row = lastRow Down To 3
        dockValue = ws.Cells(row, dockCol).Value
        
        If IsDate(dockValue) Then
            currentDate = CLng(dockValue)
            If currentDate <> previousDate Then
                ws.HPageBreaks.Add Before:=ws.Rows(row)
                previousDate = currentDate
            End If
        End If
    Next row
    
    Exit Sub
ErrorHandler:
    ' Continue on error
End Sub

' ============================================================
' UTILITY: Find column number by header name
' ============================================================
Function FindColumnByHeader(ws As Worksheet, headerName As String) As Long
    Dim col As Long
    Dim headerRow As Range
    Set headerRow = ws.Rows(1)
    
    For col = 1 To headerRow.Columns.Count
        If Trim(headerRow.Cells(1, col).Value) = headerName Then
            FindColumnByHeader = col
            Exit Function
        End If
    Next col
    
    FindColumnByHeader = 0
End Function

Option Explicit

' ============================================================
'  PRODUCTION AUTOMATION
'  How to use:
'    1. Open your workbook in Excel
'    2. Press Alt+F11 ? File ? Import File ? select this .bas
'    3. Press Alt+F8 ? Run "RunProductionAutomation"
' ============================================================

Sub Auto_Open()
    EnsureProductionAutomationButton
End Sub

Sub RunProductionAutomation()
    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual
    Application.EnableEvents = False

    Dim sourceWs As Worksheet
    Set sourceWs = ActiveSheet

    ' Step 0: Check for all required headers on source sheet
    Dim missingHeaders As String
    missingHeaders = CheckAllHeaders(sourceWs)
    If missingHeaders <> "" Then
        Application.ScreenUpdating = True
        Application.Calculation = xlCalculationAutomatic
        Application.EnableEvents = True
        MsgBox "ERROR: Missing required headers:" & vbCrLf & vbCrLf & missingHeaders, vbCritical, "Missing Headers"
        Exit Sub
    End If

    ' Create a copy of the raw data sheet to process
    Dim ws As Worksheet
    sourceWs.Copy After:=sourceWs
    Set ws = ActiveSheet
    
    ' Give it a clean name
    On Error Resume Next
    ws.name = "Production Report (" & Format(Now, "hh-mm-ss") & ")"
    On Error GoTo 0

    MsgBox "Starting Production Automation." & vbCrLf & _
           "Processing on new sheet: " & ws.name & vbCrLf & _
           "Steps: Column filter ? Status filter ? Hold filter ? Date filter ? Sort ? Format ? Page breaks", _
           vbInformation, "Production Automation"

    Call Step1_KeepRequiredColumns(ws)
    Call Step2_FilterProductionStatus(ws)
    Call Step3_FilterWOHoldDescription(ws)
    Call Step4_FilterAndSortByDockDate(ws)
    Call Step5_FormatAllCells(ws)
    Call Step6_HighlightPastDates(ws)
    Call Step7_InsertPageBreaks(ws)

    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    Application.EnableEvents = True

    EnsureProductionAutomationButton

    MsgBox "Done! Automation complete.", vbInformation, "Production Automation"
End Sub

' ============================================================
'  STEP 1 ï¿½ Keep only required columns, delete everything else
' ============================================================
Sub Step1_KeepRequiredColumns(ws As Worksheet)
    Dim allReq(50) As String
    allReq(1) = "WONumber"
    allReq(2) = "PriorityCode"
    allReq(3) = "SoldTo"
    allReq(4) = "PartNumber"
    allReq(5) = "CustomerPartNumber"
    allReq(6) = "Revision"
    allReq(7) = "OraclePartNumber"
    allReq(8) = "WOScheduleDate"
    allReq(9) = "SalesOrderQuantity"
    allReq(10) = "ReservedQty"
    allReq(11) = "CurrentDepartment"
    allReq(12) = "NextProcess"
    allReq(13) = "BoardsQty"
    allReq(14) = "Up"
    allReq(15) = "BoardsWIP"
    allReq(16) = "BoardsRej"
    allReq(17) = "PanelsWIP"
    allReq(18) = "DockDate"
    allReq(19) = "OrderValue"
    allReq(20) = "SOChecklist"
    allReq(21) = "Hours"
    allReq(22) = "RecommitDate"
    allReq(23) = "Eng_HoldTags_Last_Reason"
    allReq(24) = "PanelSubCore"
    allReq(25) = "PanelSize"
    allReq(26) = "LAYERS"
    allReq(27) = "BoardWidth"
    allReq(28) = "BoardHeight"
    allReq(29) = "DateInDepartment_Local"
    allReq(30) = "ProductionStatus"
    allReq(31) = "WOOnHoldCode"
    allReq(32) = "WOHoldDescription"
    allReq(33) = "SOOnHoldCode"
    allReq(34) = "SOHoldDescription"
    allReq(35) = "StepNum"
    allReq(36) = "MaxStep"
    allReq(37) = "PercentComplete"
    allReq(38) = "SalesOrder"
    allReq(39) = "RevisionType"
    allReq(40) = "OracleLineItem"
    allReq(41) = "PONumber"
    allReq(42) = "TurnTime"
    allReq(43) = "BasePrice"
    allReq(44) = "OpenQty"
    allReq(45) = "PremiumPrice"
    allReq(46) = "RemakeSlant"
    allReq(47) = "Eng_HoldTags_Count"

    Dim lastCol As Long
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column

    ' Delete columns from right to left to avoid index shifting
    ' Only keep columns that are in allReq
    Dim c As Long, i As Integer
    For c = lastCol To 1 Step -1
        Dim hdr As String
        hdr = Trim(ws.Cells(1, c).value)
        Dim keep As Boolean
        keep = False
        For i = 1 To 47
            If LCase(hdr) = LCase(allReq(i)) Then
                keep = True
                Exit For
            End If
        Next i
        If Not keep Then
            ws.Columns(c).Delete
        End If
    Next c

    ' Reorder remaining columns to match allReq order
    Dim targetCol As Long
    targetCol = 1
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    For i = 1 To 47
        For c = targetCol To lastCol
            If LCase(Trim(ws.Cells(1, c).value)) = LCase(allReq(i)) Then
                If c <> targetCol Then
                    ws.Columns(c).Cut
                    ws.Columns(targetCol).Insert Shift:=xlToRight
                End If
                targetCol = targetCol + 1
                Exit For
            End If
        Next c
    Next i
End Sub

' ============================================================
'  STEP 2 ï¿½ ProductionStatus filter:
'    Keep if: ProductionStatus is blank OR ProductionStatus = "Released"
'    If ProductionStatus is blank, CurrentDepartment must be "MATL ISSUE EXT"
' ============================================================
Sub Step2_FilterProductionStatus(ws As Worksheet)
    Dim psCol As Long, cdCol As Long
    psCol = FindColumn(ws, "ProductionStatus")
    cdCol = FindColumn(ws, "CurrentDepartment")
    If psCol = 0 Then Exit Sub

    Dim lastRow As Long
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row

    Dim r As Long
    For r = lastRow To 2 Step -1
        Dim psVal As String
        psVal = Trim(ws.Cells(r, psCol).value)
        
        Dim keepRow As Boolean
        keepRow = False
        
        If psVal = "" Then
            ' ProductionStatus is blank ï¿½ check CurrentDepartment
            If cdCol > 0 Then
                Dim cdVal As String
                cdVal = Trim(ws.Cells(r, cdCol).value)
                If UCase(cdVal) = "MATL ISSUE EXT" Then
                    keepRow = True
                End If
            End If
        ElseIf UCase(psVal) = "RELEASED" Then
            ' ProductionStatus is "Released" ï¿½ keep
            keepRow = True
        End If
        
        If Not keepRow Then
            ws.Rows(r).Delete
        End If
    Next r
End Sub

' ============================================================
'  STEP 3 ï¿½ WOHoldDescription: keep blank cells only
' ============================================================
Sub Step3_FilterWOHoldDescription(ws As Worksheet)
    Dim whdCol As Long
    whdCol = FindColumn(ws, "WOHoldDescription")
    If whdCol = 0 Then Exit Sub

    Dim lastRow As Long
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row

    Dim r As Long
    For r = lastRow To 2 Step -1
        If Trim(ws.Cells(r, whdCol).value) <> "" Then
            ws.Rows(r).Delete
        End If
    Next r
End Sub

' ============================================================
'  STEP 4 ï¿½ Filter today?+7 days by effective date, sort
'           Past dock dates: use RecommitDate as effective date
' ============================================================
Sub Step4_FilterAndSortByDockDate(ws As Worksheet)
    Dim dockCol As Long, recommitCol As Long, priorityCol As Long
    dockCol = FindColumn(ws, "DockDate")
    recommitCol = FindColumn(ws, "RecommitDate")
    priorityCol = FindColumn(ws, "PriorityCode")
    If dockCol = 0 Then Exit Sub

    Dim today As Date
    today = Date
    Dim endDate As Date
    endDate = today + 7

    Dim lastRow As Long, lastCol As Long
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column

    Dim wb As Workbook
    Set wb = ws.Parent

    ' Remove any previous temp sheets
    On Error Resume Next
    Application.DisplayAlerts = False
    wb.Worksheets("__tmp_sort").Delete
    wb.Worksheets("__tmp_sort2").Delete
    Application.DisplayAlerts = True
    On Error GoTo 0

    ' Create temp sheet to collect kept rows
    Dim tmp As Worksheet, tmp2 As Worksheet
    Set tmp = wb.Worksheets.Add(After:=wb.Worksheets(wb.Worksheets.Count))
    tmp.name = "__tmp_sort"

    ' Copy header
    ws.Range(ws.Cells(1, 1), ws.Cells(1, lastCol)).Copy Destination:=tmp.Cells(1, 1)

    Dim r As Long, tr As Long
    tr = 2
    Dim dockVal As Variant, rcVal As Variant, effDate As Variant

    ' Collect rows we want to keep into tmp and store an effDate in column lastCol+1
    For r = 2 To lastRow
        dockVal = ws.Cells(r, dockCol).value
        If IsDate(dockVal) Then
            Dim dockDate As Date
            dockDate = CDate(dockVal)

            If dockDate < today And recommitCol > 0 Then
                rcVal = ws.Cells(r, recommitCol).value
                If IsDate(rcVal) Then
                    effDate = CDate(rcVal)
                Else
                    effDate = dockDate
                End If
            Else
                effDate = dockDate
            End If

            ' Keep logic: if future dock, only keep when effDate within [today,endDate]
            If dockDate >= today Then
                If IsDate(effDate) Then
                    If effDate >= today And effDate <= endDate Then
                        ws.Range(ws.Cells(r, 1), ws.Cells(r, lastCol)).Copy Destination:=tmp.Cells(tr, 1)
                        tmp.Cells(tr, lastCol + 1).value = effDate
                        tr = tr + 1
                    End If
                End If
            Else
                ' Past dock dates always kept
                ws.Range(ws.Cells(r, 1), ws.Cells(r, lastCol)).Copy Destination:=tmp.Cells(tr, 1)
                tmp.Cells(tr, lastCol + 1).value = effDate
                tr = tr + 1
            End If
        Else
            ' skip rows without DockDate
        End If
    Next r

    Dim lastTmpRow As Long
    lastTmpRow = tmp.Cells(tmp.Rows.Count, 1).End(xlUp).Row
    If lastTmpRow < 2 Then
        ' Nothing to keep
        Application.DisplayAlerts = False
        tmp.Delete
        Application.DisplayAlerts = True
        Exit Sub
    End If

    ' Create tmp2 and copy header
    Set tmp2 = wb.Worksheets.Add(After:=wb.Worksheets(wb.Worksheets.Count))
    tmp2.name = "__tmp_sort2"
    tmp.Range(tmp.Cells(1, 1), tmp.Cells(1, lastCol)).Copy Destination:=tmp2.Cells(1, 1)

    Dim firstOthersRow As Long
    tr = 2

    ' Copy upcoming rows first (effDate between today and endDate)
    For r = 2 To lastTmpRow
        If IsDate(tmp.Cells(r, lastCol + 1).value) Then
            If tmp.Cells(r, lastCol + 1).value >= today And tmp.Cells(r, lastCol + 1).value <= endDate Then
                tmp.Range(tmp.Cells(r, 1), tmp.Cells(r, lastCol)).Copy Destination:=tmp2.Cells(tr, 1)
                tmp2.Cells(tr, lastCol + 1).value = tmp.Cells(r, lastCol + 1).value
                tr = tr + 1
            End If
        End If
    Next r

    firstOthersRow = tr

    ' Copy other rows
    For r = 2 To lastTmpRow
        If Not (IsDate(tmp.Cells(r, lastCol + 1).value) And tmp.Cells(r, lastCol + 1).value >= today And tmp.Cells(r, lastCol + 1).value <= endDate) Then
            tmp.Range(tmp.Cells(r, 1), tmp.Cells(r, lastCol)).Copy Destination:=tmp2.Cells(tr, 1)
            tmp2.Cells(tr, lastCol + 1).value = tmp.Cells(r, lastCol + 1).value
            tr = tr + 1
        End If
    Next r

    Dim lastTmp2Row As Long
    lastTmp2Row = tmp2.Cells(tmp2.Rows.Count, 1).End(xlUp).Row

    ' Sort upcoming block (if any) by effDate asc, then PriorityCode asc, then RecommitDate asc
    If firstOthersRow > 2 Then
        With tmp2.Sort
            .SortFields.Clear
            .SortFields.Add key:=tmp2.Columns(lastCol + 1), SortOn:=xlSortOnValues, Order:=xlAscending
            If priorityCol > 0 Then .SortFields.Add key:=tmp2.Columns(priorityCol), SortOn:=xlSortOnValues, Order:=xlAscending
            If recommitCol > 0 Then .SortFields.Add key:=tmp2.Columns(recommitCol), SortOn:=xlSortOnValues, Order:=xlAscending
            .SetRange tmp2.Range(tmp2.Cells(2, 1), tmp2.Cells(firstOthersRow - 1, lastCol + 1))
            .Header = xlNo
            .Apply
        End With
    End If

    ' Sort others block by PriorityCode asc, RecommitDate asc, effDate asc
    If firstOthersRow <= lastTmp2Row Then
        With tmp2.Sort
            .SortFields.Clear
            If priorityCol > 0 Then .SortFields.Add key:=tmp2.Columns(priorityCol), SortOn:=xlSortOnValues, Order:=xlAscending
            If recommitCol > 0 Then .SortFields.Add key:=tmp2.Columns(recommitCol), SortOn:=xlSortOnValues, Order:=xlAscending
            .SortFields.Add key:=tmp2.Columns(lastCol + 1), SortOn:=xlSortOnValues, Order:=xlAscending
            .SetRange tmp2.Range(tmp2.Cells(firstOthersRow, 1), tmp2.Cells(lastTmp2Row, lastCol + 1))
            .Header = xlNo
            .Apply
        End With
    End If

    ' Clear original rows and paste sorted data back (excluding helper column)
    ws.Range(ws.Cells(2, 1), ws.Cells(ws.Rows.Count, 1)).EntireRow.Delete
    tmp2.Range(tmp2.Cells(2, 1), tmp2.Cells(lastTmp2Row, lastCol)).Copy Destination:=ws.Cells(2, 1)

    ' Clean up temp sheets
    Application.DisplayAlerts = False
    tmp.Delete
    tmp2.Delete
    Application.DisplayAlerts = True
End Sub

' ============================================================
'  STEP 5 ï¿½ Format ALL cells: white, Arial 12 Bold, all borders
' ============================================================
Sub Step5_FormatAllCells(ws As Worksheet)
    Dim lastRow As Long, lastCol As Long
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    Dim cdCol As Long
    cdCol = FindColumn(ws, "CurrentDepartment")

    Dim rng As Range
    Set rng = ws.Range(ws.Cells(1, 1), ws.Cells(lastRow, lastCol))

    With rng
        ' Font
        .Font.name = "Arial"
        .Font.Size = 12
        .Font.Bold = True
        .Font.Color = RGB(0, 0, 0)

        ' Fill
        .Interior.Color = RGB(255, 255, 255)

        ' Borders ï¿½ all four sides of each cell
        .Borders(xlEdgeLeft).LineStyle = xlContinuous
        .Borders(xlEdgeRight).LineStyle = xlContinuous
        .Borders(xlEdgeTop).LineStyle = xlContinuous
        .Borders(xlEdgeBottom).LineStyle = xlContinuous
        .Borders(xlInsideVertical).LineStyle = xlContinuous
        .Borders(xlInsideHorizontal).LineStyle = xlContinuous

        .Borders(xlEdgeLeft).Weight = xlThin
        .Borders(xlEdgeRight).Weight = xlThin
        .Borders(xlEdgeTop).Weight = xlThin
        .Borders(xlEdgeBottom).Weight = xlThin
        .Borders(xlInsideVertical).Weight = xlThin
        .Borders(xlInsideHorizontal).Weight = xlThin

        ' Alignment
        .HorizontalAlignment = xlLeft
        .VerticalAlignment = xlCenter
    End With

    ' Color each data row based on CurrentDepartment
    Dim r As Long
    For r = 2 To lastRow
        If cdCol > 0 Then
            ws.Range(ws.Cells(r, 1), ws.Cells(r, lastCol)).Font.Color = _
                GetDepartmentTextColor(ws.Cells(r, cdCol).value)
        Else
            ws.Range(ws.Cells(r, 1), ws.Cells(r, lastCol)).Font.Color = RGB(255, 0, 0)
        End If
    Next r

    ' Auto-fit columns (cap at 40 chars wide)
    Dim c As Long
    For c = 1 To lastCol
        ws.Columns(c).AutoFit
        If ws.Columns(c).ColumnWidth > 40 Then ws.Columns(c).ColumnWidth = 40
    Next c
End Sub

' ============================================================
'  STEP 6 ï¿½ Highlight rows with past DockDate in yellow
' ============================================================
Sub Step6_HighlightPastDates(ws As Worksheet)
    Dim dockCol As Long
    dockCol = FindColumn(ws, "DockDate")
    If dockCol = 0 Then Exit Sub

    Dim lastRow As Long, lastCol As Long
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column

    Dim today As Date
    today = Date

    Dim r As Long
    For r = 2 To lastRow
        Dim v As Variant
        v = ws.Cells(r, dockCol).value
        If IsDate(v) Then
            If CDate(v) < today Then
                ws.Range(ws.Cells(r, 1), ws.Cells(r, lastCol)).Interior.Color = RGB(255, 255, 0)
            End If
        End If
    Next r
End Sub

' ============================================================
'  STEP 7 ï¿½ Page break before each new effective-date day
'           Past rows group by RecommitDate; future by DockDate
' ============================================================
Sub Step7_InsertPageBreaks(ws As Worksheet)
    ws.ResetAllPageBreaks

    Dim dockCol As Long, recommitCol As Long
    dockCol = FindColumn(ws, "DockDate")
    recommitCol = FindColumn(ws, "RecommitDate")
    If dockCol = 0 Then Exit Sub

    Dim lastRow As Long
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row

    Dim today As Date
    today = Date

    Dim currentDay As String
    currentDay = ""

    Dim r As Long
    For r = 2 To lastRow
        Dim dv As Variant
        dv = ws.Cells(r, dockCol).value

        Dim effDay As String
        effDay = ""

        If IsDate(dv) Then
            If CDate(dv) < today And recommitCol > 0 Then
                Dim rv As Variant
                rv = ws.Cells(r, recommitCol).value
                If IsDate(rv) Then
                    effDay = Format(CDate(rv), "YYYY-MM-DD")
                Else
                    effDay = Format(CDate(dv), "YYYY-MM-DD")
                End If
            Else
                effDay = Format(CDate(dv), "YYYY-MM-DD")
            End If
        End If

        If effDay <> "" And effDay <> currentDay Then
            If currentDay <> "" Then
                ws.HPageBreaks.Add Before:=ws.Rows(r)
            End If
            currentDay = effDay
        End If
    Next r

    ' Repeat header row on every printed page
    ws.PageSetup.PrintTitleRows = "$1:$1"
End Sub

' ============================================================
'  HELPER ï¿½ Find column index by header name (case-insensitive)
'           Returns 0 if not found
' ============================================================
Function FindColumn(ws As Worksheet, colName As String) As Long
    Dim lastCol As Long
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    Dim c As Long
    For c = 1 To lastCol
        If LCase(Trim(ws.Cells(1, c).value)) = LCase(colName) Then
            FindColumn = c
            Exit Function
        End If
    Next c
    FindColumn = 0
End Function

' ============================================================
'  HELPER ï¿½ Check if all required headers exist
'           Returns empty string if all found, otherwise
'           returns list of missing headers
' ============================================================
Function CheckAllHeaders(ws As Worksheet) As String
    Dim allReq(50) As String
    allReq(1) = "WONumber"
    allReq(2) = "PriorityCode"
    allReq(3) = "SoldTo"
    allReq(4) = "PartNumber"
    allReq(5) = "CustomerPartNumber"
    allReq(6) = "Revision"
    allReq(7) = "OraclePartNumber"
    allReq(8) = "WOScheduleDate"
    allReq(9) = "SalesOrderQuantity"
    allReq(10) = "ReservedQty"
    allReq(11) = "CurrentDepartment"
    allReq(12) = "NextProcess"
    allReq(13) = "BoardsQty"
    allReq(14) = "Up"
    allReq(15) = "BoardsWIP"
    allReq(16) = "BoardsRej"
    allReq(17) = "PanelsWIP"
    allReq(18) = "DockDate"
    allReq(19) = "OrderValue"
    allReq(20) = "SOChecklist"
    allReq(21) = "Hours"
    allReq(22) = "RecommitDate"
    allReq(23) = "Eng_HoldTags_Last_Reason"
    allReq(24) = "PanelSubCore"
    allReq(25) = "PanelSize"
    allReq(26) = "LAYERS"
    allReq(27) = "BoardWidth"
    allReq(28) = "BoardHeight"
    allReq(29) = "DateInDepartment_Local"
    allReq(30) = "ProductionStatus"
    allReq(31) = "WOOnHoldCode"
    allReq(32) = "WOHoldDescription"
    allReq(33) = "SOOnHoldCode"
    allReq(34) = "SOHoldDescription"
    allReq(35) = "StepNum"
    allReq(36) = "MaxStep"
    allReq(37) = "PercentComplete"
    allReq(38) = "SalesOrder"
    allReq(39) = "RevisionType"
    allReq(40) = "OracleLineItem"
    allReq(41) = "PONumber"
    allReq(42) = "TurnTime"
    allReq(43) = "BasePrice"
    allReq(44) = "OpenQty"
    allReq(45) = "PremiumPrice"
    allReq(46) = "RemakeSlant"
    allReq(47) = "Eng_HoldTags_Count"

    Dim missing As String
    missing = ""
    Dim i As Integer
    For i = 1 To 47
        If FindColumn(ws, allReq(i)) = 0 Then
            missing = missing & allReq(i) & vbCrLf
        End If
    Next i
    
    CheckAllHeaders = missing
End Function

' ============================================================
'  HELPER ï¿½ Department text color for whole row
'           Blue for listed production departments,
'           black for final/test/ship departments,
'           red for anything else
' ============================================================
Function GetDepartmentTextColor(deptValue As Variant) As Long
    Dim dept As String
    dept = NormalizeDepartment(deptValue)

    Select Case dept
        Case "inkjet", "legend bake", "sm pumice", "sm coat", "sm img", _
             "sm dev", "sm bake", "uv bump", "enipig", "enig"
            GetDepartmentTextColor = RGB(0, 0, 255)
        Case "electrical test", "rout", "bevil", "final clean", _
             "final insp", "final qa", "pack and ship"
            GetDepartmentTextColor = RGB(0, 0, 0)
        Case Else
            GetDepartmentTextColor = RGB(255, 0, 0)
    End Select
End Function

Function NormalizeDepartment(deptValue As Variant) As String
    Dim dept As String
    dept = LCase(Trim(CStr(deptValue)))

    Do While Len(dept) > 0 And (Right$(dept, 1) = "}" Or Right$(dept, 1) = " ")
        dept = Left$(dept, Len(dept) - 1)
    Loop

    Do While InStr(dept, "  ") > 0
        dept = Replace(dept, "  ", " ")
    Loop

    NormalizeDepartment = Trim(dept)
End Function

' ============================================================
'  HELPER ï¿½ Add a worksheet button that runs the macro
' ============================================================
Sub EnsureProductionAutomationButton()
    Dim ws As Worksheet
    If TypeName(ActiveSheet) = "Worksheet" Then
        Set ws = ActiveSheet
    Else
        Set ws = ThisWorkbook.Worksheets(1)
    End If

    Dim btnName As String
    btnName = "btnRunProductionAutomation"

    On Error Resume Next
    ws.Shapes(btnName).Delete
    On Error GoTo 0

    Dim btn As Shape
    Set btn = ws.Shapes.AddShape(msoShapeRoundedRectangle, 10, 10, 180, 32)
    btn.name = btnName
    btn.OnAction = "'" & ThisWorkbook.name & "'!RunProductionAutomation"
    btn.TextFrame.Characters.Text = "Run Production Automation"
    btn.TextFrame.Characters.Font.name = "Arial"
    btn.TextFrame.Characters.Font.Size = 11
    btn.TextFrame.Characters.Font.Bold = True
    btn.TextFrame.Characters.Font.Color = RGB(255, 255, 255)
    btn.TextFrame.HorizontalAlignment = xlHAlignCenter
    btn.TextFrame.VerticalAlignment = xlVAlignCenter
    btn.Fill.ForeColor.RGB = RGB(102, 126, 234)
    btn.Line.ForeColor.RGB = RGB(102, 126, 234)
End Sub



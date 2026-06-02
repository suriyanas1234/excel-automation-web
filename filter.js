document.addEventListener('DOMContentLoaded', function () {

  // ── State ──────────────────────────────────────────────────────────────────
  let originalData = null;
  let filteredData = null;
  let fileName = '';

  const REQUIRED_COLS = [
    'WONumber','PriorityCode','SoldTo','PartNumber','CustomerPartNumber',
    'Revision','OraclePartNumber','WOScheduleDate','SalesOrderQuantity',
    'ReservedQty','CurrentDepartment','NextProcess','BoardsQty','Up',
    'BoardsWIP','BoardsRej','PanelsWIP','DockDate','OrderValue','SOChecklist',
    'Hours','RecommitDate','Eng_HoldTags_Last_Reason','PanelSubCore','PanelSize',
    'LAYERS','BoardWidth','BoardHeight','DateInDepartment_Local','ProductionStatus',
    'WOOnHoldCode','WOHoldDescription','SOOnHoldCode','SOHoldDescription',
    'StepNum','MaxStep','PercentComplete','SalesOrder','RevisionType',
    'OracleLineItem','PONumber','TurnTime','BasePrice','OpenQty','PremiumPrice',
    'RemakeSlant','Eng_HoldTags_Count'
  ];

  // ── DOM refs ───────────────────────────────────────────────────────────────
  const fileInput      = document.getElementById('fileInput');
  const fileLabel      = document.querySelector('.file-label');
  const statusDiv      = document.getElementById('status');
  const downloadBtn    = document.getElementById('downloadBtn');
  const resetBtn       = document.getElementById('resetBtn');
  const resultsSection = document.getElementById('resultsSection');

  // ── Event listeners ────────────────────────────────────────────────────────
  fileInput.addEventListener('change', handleFileSelect);
  fileLabel.addEventListener('dragover', handleDragOver);
  fileLabel.addEventListener('drop', handleDrop);
  downloadBtn.addEventListener('click', downloadFile);
  resetBtn.addEventListener('click', resetAll);

  // ── Drag-and-drop ──────────────────────────────────────────────────────────
  function handleDragOver(e) {
    e.preventDefault(); e.stopPropagation();
    fileLabel.style.background = '#efefff';
  }
  function handleDrop(e) {
    e.preventDefault(); e.stopPropagation();
    fileLabel.style.background = '#f5f5f5';
    if (e.dataTransfer.files.length > 0) {
      fileInput.files = e.dataTransfer.files;
      handleFileSelect();
    }
  }

  // ── File read ──────────────────────────────────────────────────────────────
  function handleFileSelect() {
    const file = fileInput.files[0];
    if (!file) return;
    fileName = file.name.replace(/\.[^/.]+$/, '');
    document.querySelector('.file-name').textContent = `Selected: ${file.name}`;

    const reader = new FileReader();
    reader.onload = function (e) {
      try {
        const wb   = XLSX.read(e.target.result, { type: 'array', cellDates: true });
        const ws   = wb.Sheets[wb.SheetNames[0]];
        originalData = XLSX.utils.sheet_to_json(ws, { raw: false, dateNF: 'yyyy-mm-dd' });
        processFile();
      } catch (err) {
        showStatus(`❌ Error reading file: ${err.message}`, 'error');
        downloadBtn.disabled = true;
      }
    };
    reader.readAsArrayBuffer(file);
  }

  // ── Main pipeline ──────────────────────────────────────────────────────────
  function processFile() {
    if (!originalData || originalData.length === 0) {
      showStatus('❌ No data to process', 'error'); return;
    }

    // 1. Validate headers
    const missing = validateHeaders(originalData[0]);
    if (missing.length > 0) {
      showStatus(`❌ Missing required columns: ${missing.join(', ')}`, 'error');
      downloadBtn.disabled = true;
      return;
    }

    try {
      // 2. Keep only required columns (in order)
      let data = keepRequiredColumns(originalData);

      // 3. Filter rows
      data = filterRows(data);

      // 4. Sort + date window + effective-date alignment
      data = sortAndFilterByDate(data);

      filteredData = data;

      displayResults(originalData.length, filteredData.length);
      showStatus(`✅ Done! ${filteredData.length} rows ready to download.`, 'success');
      downloadBtn.disabled = false;
      resultsSection.classList.add('show');
    } catch (err) {
      showStatus(`❌ Error processing: ${err.message}`, 'error');
      downloadBtn.disabled = true;
    }
  }

  // ── 1. Header validation ───────────────────────────────────────────────────
  function validateHeaders(sampleRow) {
    const existingKeys = Object.keys(sampleRow).map(k => k.trim().toLowerCase());
    return REQUIRED_COLS.filter(
      col => !existingKeys.includes(col.trim().toLowerCase())
    );
  }

  // ── 2. Keep only required columns, in declared order ──────────────────────
  function keepRequiredColumns(data) {
    // Build a case-insensitive map from required name -> actual key in data
    const firstRow   = data[0];
    const actualKeys = Object.keys(firstRow);
    const colMap     = {};

    REQUIRED_COLS.forEach(req => {
      const match = actualKeys.find(
        k => k.trim().toLowerCase() === req.trim().toLowerCase()
      );
      if (match) colMap[req] = match;
    });

    return data.map(row => {
      const out = {};
      REQUIRED_COLS.forEach(req => {
        if (colMap[req] !== undefined) out[req] = row[colMap[req]] ?? '';
      });
      return out;
    });
  }

  // ── 3. Row filtering ───────────────────────────────────────────────────────
  //   Keep when ALL of:
  //     (a) WOHoldDescription is blank
  //     (b) ProductionStatus = "Released"
  //         OR ProductionStatus is blank AND CurrentDepartment = "MATL ISSUE EXT"
  function filterRows(data) {
    return data.filter(row => {
      const whd = val(row, 'WOHoldDescription');
      if (whd !== '') return false;

      const ps = val(row, 'ProductionStatus');
      if (ps === 'released') return true;

      if (ps === '') {
        return val(row, 'CurrentDepartment') === 'matl issue ext';
      }
      return false;
    });
  }

  // ── 4. Date sort + window ──────────────────────────────────────────────────
  //   - For each row compute effectiveDate:
  //       past DockDate + valid RecommitDate → use RecommitDate
  //       otherwise → use DockDate
  //   - Keep: past dock dates (always) + effective dates within today→today+7
  //   - Sort Logic (from FilterMacro.bas Step 4):
  //       Split into two blocks:
  //       1. "Upcoming": effectiveDate between today and today+7
  //          Sort by: effectiveDate ASC, PriorityCode ASC, RecommitDate ASC
  //       2. "Others": (Past rows not in upcoming window)
  //          Sort by: PriorityCode ASC, RecommitDate ASC, effectiveDate ASC
  function sortAndFilterByDate(data) {
    const today   = startOfDay(new Date());
    const endDate = new Date(today); endDate.setDate(endDate.getDate() + 7);

    // Attach effective date and dock date for logic
    data = data.map(row => {
      const dd  = parseDate(row['DockDate']);
      const rc  = parseDate(row['RecommitDate']);
      let eff;
      if (dd && dd < today && rc) {
        eff = rc;          // align past row to its recommit date
      } else {
        eff = dd;
      }
      return { ...row, _eff: eff, _dock: dd };
    });

    // Filter: keep past dock dates always; future must be within window
    data = data.filter(row => {
      if (!row._dock) return false;
      if (row._dock < today) return true;          // past → always keep
      const eff = row._eff || row._dock;
      return eff >= today && eff <= endDate;        // future → must be in window
    });

    // Split into blocks for separate sorting
    const upcoming = [];
    const others   = [];

    data.forEach(row => {
      const eff = row._eff;
      if (eff && eff >= today && eff <= endDate) {
        upcoming.push(row);
      } else {
        others.push(row);
      }
    });

    // Helper to compare values (handles numbers/dates/strings)
    // Mimics Excel ASC sort: blanks/nulls go to the END
    const cmp = (a, b) => {
      const aBlank = a === null || a === undefined || String(a).trim() === '';
      const bBlank = b === null || b === undefined || String(b).trim() === '';
      if (aBlank && bBlank) return 0;
      if (aBlank) return 1;
      if (bBlank) return -1;

      if (a instanceof Date && b instanceof Date) return a - b;

      // Try numeric comparison if both look like numbers
      const numA = parseFloat(a);
      const numB = parseFloat(b);
      if (!isNaN(numA) && !isNaN(numB) && !isNaN(a) && !isNaN(b)) {
        return numA - numB;
      }

      const sA = String(a).toLowerCase();
      const sB = String(b).toLowerCase();
      if (sA < sB) return -1;
      if (sA > sB) return 1;
      return 0;
    };

    // Sort Upcoming: eff ASC, PriorityCode ASC, RecommitDate ASC
    upcoming.sort((a, b) => {
      return cmp(a._eff, b._eff) || 
             cmp(a['PriorityCode'], b['PriorityCode']) || 
             cmp(parseDate(a['RecommitDate']), parseDate(b['RecommitDate']));
    });

    // Sort Others: PriorityCode ASC, RecommitDate ASC, eff ASC
    others.sort((a, b) => {
      return cmp(a['PriorityCode'], b['PriorityCode']) || 
             cmp(parseDate(a['RecommitDate']), parseDate(b['RecommitDate'])) || 
             cmp(a._eff, b._eff);
    });

    // Combine blocks
    const sortedData = [...upcoming, ...others];

    // Remove helper fields
    return sortedData.map(({ _eff, _dock, ...rest }) => rest);
  }

  // ── Download ───────────────────────────────────────────────────────────────
  function downloadFile() {
    if (!filteredData || filteredData.length === 0) {
      showStatus('❌ No data to download', 'error'); return;
    }

    try {
      const today     = startOfDay(new Date());
      const wb        = XLSX.utils.book_new();
      const wsData    = buildFormattedSheet(filteredData, today);
      XLSX.utils.book_append_sheet(wb, wsData, 'Production Report');

      const ts  = formatDateKey(today);
      const out = `${fileName}_filtered_${ts}.xlsx`;
      XLSX.writeFile(wb, out);
      showStatus(`✅ Downloaded: ${out}`, 'success');
    } catch (err) {
      showStatus(`❌ Error downloading: ${err.message}`, 'error');
    }
  }

  // ── Build styled worksheet ─────────────────────────────────────────────────
  function buildFormattedSheet(data, today) {
    const ws = XLSX.utils.json_to_sheet(data, { header: REQUIRED_COLS });

    const nRows = data.length + 1;   // +1 for header
    const nCols = REQUIRED_COLS.length;

    // Column widths
    ws['!cols'] = REQUIRED_COLS.map(h => ({
      wch: Math.min(40, Math.max(h.length + 2, 12))
    }));

    // Row heights (18pt for all rows)
    ws['!rows'] = Array.from({ length: nRows }, () => ({ hpt: 18 }));

    // Identify DockDate column index (0-based)
    const dockColIdx     = REQUIRED_COLS.indexOf('DockDate');
    const recommitColIdx = REQUIRED_COLS.indexOf('RecommitDate');

    // Styles
    const baseFont    = { name: 'Arial', sz: 12, bold: true, color: { rgb: '000000' } };
    const whiteFill   = { patternType: 'solid', fgColor: { rgb: 'FFFFFF' } };
    const yellowFill  = { patternType: 'solid', fgColor: { rgb: 'FFFF00' } };
    const thinBorder  = { style: 'thin', color: { rgb: '000000' } };
    const allBorders  = { top: thinBorder, bottom: thinBorder, left: thinBorder, right: thinBorder };
    const blueText    = { rgb: '0000FF' };
    const blackText   = { rgb: '000000' };
    const redText     = { rgb: 'FF0000' };

    // Page breaks (row indices, 0-based from data, so +1 for header offset)
    const rowBreaks = [];
    let currentDayKey = null;

    for (let r = 0; r < data.length; r++) {
      const row      = data[r];
      const dockVal  = row['DockDate'];
      const rcVal    = row['RecommitDate'];
      const dockDate = parseDate(dockVal);
      const rcDate   = parseDate(rcVal);

      // Effective day key for page-break grouping
      let effDate;
      if (dockDate && dockDate < today && rcDate) {
        effDate = rcDate;
      } else {
        effDate = dockDate;
      }
      const dayKey = effDate ? formatDateKey(effDate) : null;

      if (dayKey && dayKey !== currentDayKey) {
        if (currentDayKey !== null) rowBreaks.push(r + 1); // +1 for header row
        currentDayKey = dayKey;
      }

      const isPast = dockDate && dockDate < today;
      const fill   = isPast ? yellowFill : whiteFill;
      const font   = { ...baseFont, color: getDepartmentTextColor(row['CurrentDepartment'], blueText, blackText, redText) };

      // Apply style to every cell in this row
      for (let c = 0; c < nCols; c++) {
        const addr = XLSX.utils.encode_cell({ r: r + 1, c });
        if (!ws[addr]) ws[addr] = { v: '', t: 's' };
        ws[addr].s = {
          font:      font,
          fill:      fill,
          border:    allBorders,
          alignment: { horizontal: 'left', vertical: 'center' }
        };
      }
    }

    // Header row styling
    for (let c = 0; c < nCols; c++) {
      const addr = XLSX.utils.encode_cell({ r: 0, c });
      if (!ws[addr]) ws[addr] = { v: REQUIRED_COLS[c], t: 's' };
      ws[addr].s = {
        font:      baseFont,
        fill:      whiteFill,
        border:    allBorders,
        alignment: { horizontal: 'left', vertical: 'center' }
      };
    }

    // Page breaks
    if (rowBreaks.length > 0) {
      ws['!rowbreaks'] = rowBreaks.map(r => ({ r }));
    }

    // Print settings
    ws['!pageSetup'] = {
      orientation: 'landscape',
      fitToPage: true,
      fitToWidth: 1,
      printTitlesRow: '1:1'
    };

    return ws;
  }

  // ── Display stats ──────────────────────────────────────────────────────────
  function displayResults(origLen, filtLen) {
    document.getElementById('originalRows').textContent = origLen;
    document.getElementById('filteredRows').textContent = filtLen;
    document.getElementById('removedRows').textContent  = origLen - filtLen;
  }

  // ── Reset ──────────────────────────────────────────────────────────────────
  function resetAll() {
    originalData = null; filteredData = null; fileName = '';
    fileInput.value = '';
    fileLabel.style.background = '#f5f5f5';
    document.querySelector('.file-name').textContent = 'Supported: .xlsx, .xls, .csv';
    statusDiv.textContent = '';
    statusDiv.className = 'status';
    resultsSection.classList.remove('show');
    downloadBtn.disabled = true;
    showStatus('🔄 Ready for new file', 'info');
  }

  function showStatus(msg, type) {
    statusDiv.textContent = msg;
    statusDiv.className   = `status ${type}`;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  function val(row, col) {
    return String(row[col] ?? '').trim().toLowerCase();
  }

  function parseDate(v) {
    if (!v) return null;
    // Already a JS Date
    if (v instanceof Date) return isNaN(v) ? null : startOfDay(v);
    // String like "2025-07-31" or "07/31/2025"
    const d = new Date(v);
    return isNaN(d) ? null : startOfDay(d);
  }

  function startOfDay(d) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate());
  }

  function formatDateKey(d) {
    return d.getFullYear() + '-' +
      String(d.getMonth() + 1).padStart(2, '0') + '-' +
      String(d.getDate()).padStart(2, '0');
  }

  function getDepartmentTextColor(value, blueText, blackText, redText) {
    const department = normalizeDepartment(value);

    const blueDepartments = new Set([
      'inkjet',
      'legend bake',
      'sm pumice',
      'sm coat',
      'sm img',
      'sm dev',
      'sm bake',
      'uv bump',
      'enipig',
      'enig'
    ]);

    const blackDepartments = new Set([
      'electrical test',
      'rout',
      'bevil',
      'final clean',
      'final insp',
      'final qa',
      'pack and ship'
    ]);

    if (blueDepartments.has(department)) return blueText;
    if (blackDepartments.has(department)) return blackText;
    return redText;
  }

  function normalizeDepartment(value) {
    return String(value ?? '')
      .trim()
      .toLowerCase()
      .replace(/[}\s]+$/g, '')
      .replace(/\s+/g, ' ');
  }

});
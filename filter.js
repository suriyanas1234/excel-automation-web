// Global state
let workbook = null;
let originalData = null;
let filteredData = null;
let fileName = '';

// DOM Elements
const fileInput = document.getElementById('fileInput');
const fileLabel = document.querySelector('.file-label');
const statusDiv = document.getElementById('status');
const processBtn = document.getElementById('processBtn');
const downloadBtn = document.getElementById('downloadBtn');
const resetBtn = document.getElementById('resetBtn');
const resultsSection = document.getElementById('resultsSection');

// Filters
const productionStatusSelect = document.getElementById('productionStatus');
const holdStatusSelect = document.getElementById('holdStatus');
const dateRangeInput = document.getElementById('dateRange');
const departmentInput = document.getElementById('department');

// Event Listeners
fileInput.addEventListener('change', handleFileSelect);
fileLabel.addEventListener('dragover', handleDragOver);
fileLabel.addEventListener('drop', handleDrop);
processBtn.addEventListener('click', processFile);
downloadBtn.addEventListener('click', downloadFile);
resetBtn.addEventListener('click', resetAll);

// Drag and drop handlers
function handleDragOver(e) {
    e.preventDefault();
    e.stopPropagation();
    fileLabel.style.background = '#efefff';
}

function handleDrop(e) {
    e.preventDefault();
    e.stopPropagation();
    fileLabel.style.background = '#f5f5f5';
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        fileInput.files = files;
        handleFileSelect();
    }
}

function handleFileSelect() {
    const file = fileInput.files[0];
    if (!file) return;

    fileName = file.name.replace(/\.[^/.]+$/, '');
    const fileNameDisplay = document.querySelector('.file-name');
    fileNameDisplay.textContent = `Selected: ${file.name}`;

    const reader = new FileReader();
    reader.onload = function(e) {
        try {
            workbook = XLSX.read(e.target.result, { type: 'array' });
            const sheetName = workbook.SheetNames[0];
            const worksheet = workbook.Sheets[sheetName];
            originalData = XLSX.utils.sheet_to_json(worksheet);

            showStatus(`✅ File loaded successfully! ${originalData.length} rows found.`, 'info');
            processBtn.disabled = false;
            resultsSection.classList.remove('show');
            downloadBtn.disabled = true;
        } catch (error) {
            showStatus(`❌ Error reading file: ${error.message}`, 'error');
            processBtn.disabled = true;
        }
    };
    reader.readAsArrayBuffer(file);
}

function processFile() {
    if (!originalData || originalData.length === 0) {
        showStatus('❌ No data to process', 'error');
        return;
    }

    try {
        const filters = getFilterSettings();
        filteredData = applyUnifiedFilter(originalData, filters);

        displayResults(originalData, filteredData);
        showStatus(`✅ Filter applied! ${filteredData.length} rows remaining.`, 'success');
        downloadBtn.disabled = false;
        resultsSection.classList.add('show');
    } catch (error) {
        showStatus(`❌ Error processing file: ${error.message}`, 'error');
    }
}

function getFilterSettings() {
    return {
        productionStatus: productionStatusSelect.value,
        holdStatus: holdStatusSelect.value,
        dateRange: dateRangeInput.value,
        department: departmentInput.value.trim()
    };
}

function applyUnifiedFilter(data, filters) {
    return data.filter(row => {
        // Step 1: Filter by Hold Status
        const holdDescription = getColumnValue(row, 'WOHoldDescription');
        if (filters.holdStatus === 'blank' && holdDescription) return false;
        if (filters.holdStatus === 'held' && !holdDescription) return false;

        // Step 2: Filter by Production Status
        if (filters.productionStatus && filters.productionStatus !== '') {
            const prodStatus = getColumnValue(row, 'ProductionStatus');
            if (prodStatus !== filters.productionStatus) {
                // Special case: if looking for "Released" but status is blank, check department
                if (filters.productionStatus === 'Released' && prodStatus === '') {
                    if (filters.department && filters.department !== '') {
                        const dept = getColumnValue(row, 'CurrentDepartment');
                        if (dept !== filters.department) return false;
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            }
        }

        // Step 3: Filter by Department (if specified)
        if (filters.department && filters.department !== '') {
            const dept = getColumnValue(row, 'CurrentDepartment');
            if (dept && !dept.includes(filters.department)) return false;
        }

        // Step 4: Filter by Date Range
        if (filters.dateRange) {
            const dockDate = getColumnValue(row, 'DockDate');
            const recommitDate = getColumnValue(row, 'RecommitDate');
            const effectiveDate = recommitDate || dockDate;

            if (effectiveDate) {
                const dateObj = parseDate(effectiveDate);
                const rangeDate = new Date(filters.dateRange);
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                rangeDate.setHours(0, 0, 0, 0);

                // Keep dates from today through the selected date
                if (dateObj < today || dateObj > rangeDate) {
                    return false;
                }
            }
        }

        return true;
    });
}

function getColumnValue(row, columnName) {
    // Try exact match first
    if (row[columnName] !== undefined) {
        return row[columnName];
    }

    // Try case-insensitive match
    for (const key in row) {
        if (key.toLowerCase() === columnName.toLowerCase()) {
            return row[key];
        }
    }

    return '';
}

function parseDate(dateStr) {
    if (!dateStr) return null;

    // Handle Excel date serial numbers
    if (typeof dateStr === 'number') {
        return new Date((dateStr - 25569) * 86400 * 1000);
    }

    // Handle string dates
    const date = new Date(dateStr);
    if (!isNaN(date.getTime())) {
        return date;
    }

    return null;
}

function displayResults(original, filtered) {
    // Update stats
    document.getElementById('originalRows').textContent = original.length;
    document.getElementById('filteredRows').textContent = filtered.length;
    document.getElementById('removedRows').textContent = original.length - filtered.length;
    document.getElementById('keptColumns').textContent = Object.keys(filtered[0] || {}).length;

    // Display preview table
    const headers = Object.keys(filtered[0] || {});
    const tableHead = document.querySelector('#previewTable thead');
    const tableBody = document.querySelector('#previewTable tbody');

    tableHead.innerHTML = '';
    tableBody.innerHTML = '';

    // Create header row
    const headerRow = document.createElement('tr');
    headers.forEach(header => {
        const th = document.createElement('th');
        th.textContent = header;
        headerRow.appendChild(th);
    });
    tableHead.appendChild(headerRow);

    // Create data rows (max 10)
    const maxRows = Math.min(10, filtered.length);
    for (let i = 0; i < maxRows; i++) {
        const row = filtered[i];
        const tr = document.createElement('tr');
        headers.forEach(header => {
            const td = document.createElement('td');
            let value = row[header];
            if (value === null || value === undefined) {
                value = '';
            }
            td.textContent = String(value).substring(0, 50);
            tr.appendChild(td);
        });
        tableBody.appendChild(tr);
    }

    // Add indication if more rows exist
    if (filtered.length > 10) {
        const tr = document.createElement('tr');
        const td = document.createElement('td');
        td.colSpan = headers.length;
        td.style.textAlign = 'center';
        td.style.color = '#999';
        td.style.fontStyle = 'italic';
        td.textContent = `... and ${filtered.length - 10} more rows (download to see all)`;
        tr.appendChild(td);
        tableBody.appendChild(tr);
    }
}

function downloadFile() {
    if (!filteredData || filteredData.length === 0) {
        showStatus('❌ No data to download', 'error');
        return;
    }

    try {
        const worksheet = XLSX.utils.json_to_sheet(filteredData);
        const workbookNew = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(workbookNew, worksheet, 'Filtered Data');

        // Auto-fit columns
        const colWidths = Object.keys(filteredData[0] || {}).map(key => ({
            wch: Math.min(40, Math.max(key.length + 2, 12))
        }));
        worksheet['!cols'] = colWidths;

        const timestamp = new Date().toISOString().slice(0, 10);
        const outputFileName = `${fileName}_filtered_${timestamp}.xlsx`;

        XLSX.writeFile(workbookNew, outputFileName);
        showStatus(`✅ File downloaded as ${outputFileName}`, 'success');
    } catch (error) {
        showStatus(`❌ Error downloading file: ${error.message}`, 'error');
    }
}

function resetAll() {
    workbook = null;
    originalData = null;
    filteredData = null;
    fileName = '';

    fileInput.value = '';
    fileLabel.style.background = '#f5f5f5';
    document.querySelector('.file-name').textContent = 'Supported: .xlsx, .xls, .csv';
    productionStatusSelect.value = '';
    holdStatusSelect.value = 'any';
    dateRangeInput.value = '';
    departmentInput.value = '';

    statusDiv.textContent = '';
    statusDiv.className = 'status';
    resultsSection.classList.remove('show');
    processBtn.disabled = true;
    downloadBtn.disabled = true;

    showStatus('🔄 All fields reset', 'info');
}

function showStatus(message, type) {
    statusDiv.textContent = message;
    statusDiv.className = `status ${type}`;
    if (type === 'success') {
        setTimeout(() => {
            statusDiv.className = 'status';
        }, 5000);
    }
}

// Set default date to 7 days from today
window.addEventListener('DOMContentLoaded', function() {
    const today = new Date();
    const sevenDaysLater = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000);
    dateRangeInput.value = sevenDaysLater.toISOString().split('T')[0];
});

// Wait for DOM to be ready before initializing
document.addEventListener('DOMContentLoaded', function() {
    // Global state
    let originalData = null;
    let filteredData = null;
    let fileName = '';

    // DOM Elements
    const fileInput = document.getElementById('fileInput');
    const fileLabel = document.querySelector('.file-label');
    const statusDiv = document.getElementById('status');
    const downloadBtn = document.getElementById('downloadBtn');
    const resetBtn = document.getElementById('resetBtn');
    const resultsSection = document.getElementById('resultsSection');

    // Event Listeners
    fileInput.addEventListener('change', handleFileSelect);
    fileLabel.addEventListener('dragover', handleDragOver);
    fileLabel.addEventListener('drop', handleDrop);
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
                const workbook = XLSX.read(e.target.result, { type: 'array' });
                const sheetName = workbook.SheetNames[0];
                const worksheet = workbook.Sheets[sheetName];
                originalData = XLSX.utils.sheet_to_json(worksheet);

                // Auto-process immediately
                processFile();
            } catch (error) {
                showStatus(`❌ Error reading file: ${error.message}`, 'error');
                downloadBtn.disabled = true;
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
            filteredData = applyFilter(originalData);

            displayResults(originalData, filteredData);
            showStatus(`✅ Filtered! ${filteredData.length} rows ready to download.`, 'success');
            downloadBtn.disabled = false;
            resultsSection.classList.add('show');
        } catch (error) {
            showStatus(`❌ Error processing file: ${error.message}`, 'error');
            downloadBtn.disabled = true;
        }
    }

    function applyFilter(data) {
        return data.filter(row => {
            // Keep rows where WOHoldDescription is blank
            const holdDescription = getColumnValue(row, 'WOHoldDescription');
            if (holdDescription) return false;

            // Keep rows where ProductionStatus = "Released"
            const prodStatus = getColumnValue(row, 'ProductionStatus');
            if (prodStatus === 'Released') return true;

            // Keep rows where ProductionStatus is blank AND CurrentDepartment = "MATL ISSUE EXT"
            if (prodStatus === '' || prodStatus === null) {
                const dept = getColumnValue(row, 'CurrentDepartment');
                if (dept === 'MATL ISSUE EXT') return true;
            }

            return false;
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

    function displayResults(original, filtered) {
        // Update stats
        document.getElementById('originalRows').textContent = original.length;
        document.getElementById('filteredRows').textContent = filtered.length;
        document.getElementById('removedRows').textContent = original.length - filtered.length;
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
            showStatus(`✅ Downloaded: ${outputFileName}`, 'success');
        } catch (error) {
            showStatus(`❌ Error downloading: ${error.message}`, 'error');
        }
    }

    function resetAll() {
        originalData = null;
        filteredData = null;
        fileName = '';

        fileInput.value = '';
        fileLabel.style.background = '#f5f5f5';
        document.querySelector('.file-name').textContent = 'Supported: .xlsx, .xls, .csv';

        statusDiv.textContent = '';
        statusDiv.className = 'status';
        resultsSection.classList.remove('show');
        downloadBtn.disabled = true;

        showStatus('🔄 Ready for new file', 'info');
    }

    function showStatus(message, type) {
        statusDiv.textContent = message;
        statusDiv.className = `status ${type}`;
    }
});

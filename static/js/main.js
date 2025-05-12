document.addEventListener('DOMContentLoaded', function() {
    const dropZone = document.getElementById('drop-zone');
    const fileInput = document.getElementById('file-input');
    const uploadStatus = document.getElementById('upload-status');
    const errorMessage = document.getElementById('error-message');
    const errorText = document.getElementById('error-text');

    // Handle drag and drop events
    dropZone.addEventListener('dragover', (e) => {
        e.preventDefault();
        dropZone.classList.add('border-blue-500');
    });

    dropZone.addEventListener('dragleave', () => {
        dropZone.classList.remove('border-blue-500');
    });

    dropZone.addEventListener('drop', (e) => {
        e.preventDefault();
        dropZone.classList.remove('border-blue-500');
        const files = e.dataTransfer.files;
        if (files.length > 0) {
            handleFile(files[0]);
        }
    });

    // Handle file input change
    fileInput.addEventListener('change', (e) => {
        if (e.target.files.length > 0) {
            handleFile(e.target.files[0]);
        }
    });

    // Handle browse button click
    dropZone.querySelector('button').addEventListener('click', () => {
        fileInput.click();
    });

    function handleFile(file) {
        if (!file.name.endsWith('.docx')) {
            showError('Please upload a .docx file');
            return;
        }

        const formData = new FormData();
        formData.append('file', file);

        uploadStatus.classList.remove('hidden');
        errorMessage.classList.add('hidden');

        fetch('/process-nda', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            uploadStatus.classList.add('hidden');
            if (data.error) {
                showError(data.error);
            } else {
                displayResults(data);
            }
        })
        .catch(error => {
            uploadStatus.classList.add('hidden');
            showError('An error occurred while processing your document');
            console.error('Error:', error);
        });
    }

    function showError(message) {
        errorText.textContent = message;
        errorMessage.classList.remove('hidden');
    }

    function displayResults(data) {
        // Create results container if it doesn't exist
        let resultsContainer = document.getElementById('results-container');
        if (!resultsContainer) {
            resultsContainer = document.createElement('div');
            resultsContainer.id = 'results-container';
            resultsContainer.className = 'mt-8 bg-white rounded-lg shadow-lg p-6';
            document.querySelector('.max-w-2xl').appendChild(resultsContainer);
        }

        // Display changes
        const changesHtml = data.changes.map(change => `
            <div class="mb-4 p-4 border-l-4 border-blue-500 bg-gray-50">
                <div class="text-red-600 line-through mb-2">${change.original_text}</div>
                <div class="text-green-600 font-semibold mb-2">${change.new_text}</div>
                <div class="text-gray-600 italic">${change.reason}</div>
            </div>
        `).join('');

        resultsContainer.innerHTML = `
            <h2 class="text-2xl font-bold text-gray-800 mb-4">Suggested Changes</h2>
            <div class="space-y-4">
                ${changesHtml}
            </div>
            <div class="mt-6">
                <a href="/download/${data.filename}" class="inline-block px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors">
                    Download Redlined Document
                </a>
            </div>
        `;
    }
}); 
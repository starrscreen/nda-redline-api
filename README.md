# NDA Redline API

A Flask-based web application for analyzing, processing, and redlining Non-Disclosure Agreements (NDAs) using OpenAI's GPT models.

## Features

- Upload and process DOCX files
- AI-powered analysis of NDA content
- Automatic suggestion of legal improvements
- Professional redlining with tracked changes
- Clean user interface for reviewing changes
- Download processed documents with redlines

## Technology Stack

- **Backend**: Flask (Python)
- **AI**: OpenAI GPT-4
- **Document Processing**: python-docx, XML Power Tools
- **Frontend**: HTML, CSS, JavaScript, Tailwind CSS
- **Cloud Services**: AWS SES (for email)

## Installation

### Prerequisites

- Python 3.7+
- OpenAI API key

### Setup

1. Clone the repository:

   ```
   git clone <repository-url>
   cd nda-redline-api
   ```

2. Create and activate a virtual environment:

   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:

   ```
   pip install -r requirements.txt
   ```

4. Set up your environment variables:

   ```
   export OPENAI_API_KEY=your_openai_api_key
   ```

5. Run the application:

   ```
   python application.py
   ```

6. Access the web interface at `http://localhost:5001`

## Usage

1. Upload an NDA document (DOCX format) through the web interface
2. The system will analyze the document and suggest improvements
3. Review the suggested changes
4. Download the redlined document with all changes highlighted

## Project Structure

- `application.py`: Main Flask application with routes and OpenAI integration
- `advanced_redliner.py`: Document processing and redlining engine
- `document_processor.py`: Python-based document processing utilities
- `redlines.py`: XML Power Tools integration for professional redlining
- `templates/`: HTML templates for the web interface
- `static/`: CSS and JavaScript files
- `documents/`: Sample documents and guidelines

## License

[MIT License](LICENSE)

## Acknowledgements

- OpenAI for providing GPT models
- Python-DOCX for document processing capabilities

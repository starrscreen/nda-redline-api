# NDA Redline API

A Flask-based web application for analyzing, processing, and redlining Non-Disclosure Agreements (NDAs) using OpenAI's GPT models. The service automatically suggests improvements to NDAs based on a comprehensive checklist and provides professional redlining with tracked changes.

## Features

- Upload and process DOCX files
- AI-powered analysis of NDA content using GPT-4
- Automatic suggestion of legal improvements based on comprehensive checklist
- Professional redlining with tracked changes
- Clean user interface for reviewing changes
- Download processed documents with redlines
- Automated deployment with AWS SAM
- Ngrok tunnel for secure external access

## Technology Stack

- **Backend**: Flask (Python)
- **AI**: OpenAI GPT-4
- **Document Processing**: python-docx, XML Power Tools
- **Frontend**: HTML, CSS, JavaScript, Tailwind CSS
- **Cloud Services**: AWS SES (for email)
- **Deployment**: AWS SAM, Ngrok

## Installation

### Prerequisites

- Python 3.7+
- OpenAI API key
- AWS SAM CLI (for deployment)
- Ngrok account (for secure tunneling)

### Setup

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd nda-redline-api
   ```

2. Create and activate a virtual environment:

   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

4. Set up your environment variables:

   ```bash
   export OPENAI_API_KEY=your_openai_api_key
   ```

5. Start the service:

   ```bash
   bash start_nda_api.sh
   ```

6. Access the web interface at `http://localhost:8000`

## Usage

1. Upload an NDA document (DOCX format) through the web interface
2. The system will analyze the document and suggest improvements based on the checklist
3. Review the suggested changes
4. Download the redlined document with all changes highlighted

## Project Structure

- `application.py`: Main Flask application with routes and OpenAI integration
- `advanced_redliner.py`: Document processing and redlining engine
- `nda_checklist.txt`: Comprehensive checklist for NDA improvements
- `templates/`: HTML templates for the web interface
- `static/`: CSS and JavaScript files
- `documents/`: Sample documents and guidelines
- `logs/`: Application and service logs
- `nda_api_control.sh`: Service control script
- `start_nda_api.sh`: Service startup script

## Deployment

The application can be deployed using AWS SAM:

1. Build the SAM application:

   ```bash
   sam build
   ```

2. Deploy to AWS:
   ```bash
   sam deploy --guided
   ```

## Service Management

Use the control script to manage the service:

```bash
./nda_api_control.sh [command]
```

Available commands:

- `start`: Start the service
- `stop`: Stop the service
- `restart`: Restart the service
- `status`: Check service status
- `url`: Get the public URL

## License

[MIT License](LICENSE)

## Acknowledgements

- OpenAI for providing GPT models
- Python-DOCX for document processing capabilities
- AWS SAM for deployment infrastructure
- Ngrok for secure tunneling

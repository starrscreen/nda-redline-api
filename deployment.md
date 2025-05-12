# Deployment Options for NDA Redline API

## Option 1: PythonAnywhere (Simplest)

[PythonAnywhere](https://www.pythonanywhere.com/) is a cloud platform specifically designed for Python web applications.

1. Create a free or paid account
2. Upload your code (via Git or direct upload)
3. Set up a virtual environment with your dependencies
4. Configure a WSGI file pointing to your application
5. Set the OPENAI_API_KEY environment variable

Pros:

- No server management needed
- Free tier available for testing
- Specifically designed for Python apps
- Web-based console access

## Option 2: Render.com

[Render](https://render.com/) offers simple deployment for web services.

1. Create an account
2. Connect your Git repository
3. Select Python as the environment
4. Set the build command: `pip install -r requirements.txt`
5. Set the start command: `gunicorn application:application`
6. Add environment variables (OPENAI_API_KEY)

Pros:

- Free tier available
- Automatic deployments from Git
- SSL included

## Option 3: Local Server with Nginx and Gunicorn

If you have a spare computer or small server, you can run it locally:

1. Install the application on your server
2. Install Gunicorn: `pip install gunicorn`
3. Run with: `gunicorn --bind 0.0.0.0:8000 application:application`
4. (Optional) Add Nginx as a reverse proxy for SSL

```bash
# Example systemd service file for always-on operation
[Unit]
Description=NDA Redline API
After=network.target

[Service]
User=yourusername
WorkingDirectory=/path/to/nda-redline-api
Environment="PATH=/path/to/nda-redline-api/venv/bin"
Environment="OPENAI_API_KEY=your_api_key"
ExecStart=/path/to/nda-redline-api/venv/bin/gunicorn --workers 1 --bind 0.0.0.0:8000 application:application

[Install]
WantedBy=multi-user.target
```

Pros:

- Full control
- No monthly costs (beyond server electricity)
- Can be used on a local network without internet

## Quick Deploy Commands

For the local option, here are the exact steps:

```bash
# Install production dependencies
pip install gunicorn

# Test run with Gunicorn
gunicorn --bind 0.0.0.0:8000 application:application

# Access via http://your-server-ip:8000
```

For all options, make sure your OpenAI API key is properly set either as an environment variable or in a .env file.

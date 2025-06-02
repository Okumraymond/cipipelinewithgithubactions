# Base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ src/
COPY tests/ tests/

# Expose port
EXPOSE 5000

# Command to run the application
CMD ["python", "src/app.py"]

FROM python:3.8

# Set the working directory
WORKDIR /trusted_host_app

# Copy the application code into the container
COPY . .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 5000 for Flask app
EXPOSE 5000

# Run the application
CMD ["python", "trusted_host.py"]

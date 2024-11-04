FROM python:3.8

# Set the working directory
WORKDIR /proxy_app

# Install dependencies
RUN apt-get update && apt-get install -y iputils-ping

# Copy the application code into the container
COPY . .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 5000 for the Flask app to listen on
EXPOSE 5000

# Run the app
CMD ["python", "proxy.py"]

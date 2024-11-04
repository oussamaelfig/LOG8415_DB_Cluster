FROM python:3.8

# Set the working directory
WORKDIR /gatekeeper_app

# Copy the current directory contents into the container at /proxy_app
COPY . .

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 5000 for the Flask app to listen on
EXPOSE 5000

# Run the app
CMD ["python", "gatekeeper.py"]

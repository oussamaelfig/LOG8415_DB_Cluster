import re
from datetime import datetime

# Function to calculate metrics
def analyze_benchmark_log(log_file):
    with open(log_file, 'r') as file:
        lines = file.readlines()
    
    timestamps = []
    response_times = []
    start_time = None
    end_time = None

    for line in lines:
        # Extract the timestamp from the log line
        match = re.search(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3})', line)
        if match:
            timestamp = datetime.strptime(match.group(1), "%Y-%m-%d %H:%M:%S,%f")
            timestamps.append(timestamp)
            if not start_time:
                start_time = timestamp
            end_time = timestamp
    
    # Calculate response times between successive timestamps
    for i in range(1, len(timestamps)):
        response_time = (timestamps[i] - timestamps[i-1]).total_seconds() * 1000  # ms
        response_times.append(response_time)
    
    # Calculate metrics
    total_requests = len(response_times)
    total_time = (end_time - start_time).total_seconds()
    throughput = total_requests / total_time if total_time > 0 else 0
    avg_response_time = sum(response_times) / len(response_times) if response_times else 0

    # Output metrics
    print(f"Total Requests: {total_requests}")
    print(f"Total Time: {total_time:.2f} seconds")
    print(f"Throughput: {throughput:.2f} requests/second")
    print(f"Average Response Time: {avg_response_time:.2f} ms")

# Analyze the log file
log_file = "benchmark_log.txt"
analyze_benchmark_log(log_file)

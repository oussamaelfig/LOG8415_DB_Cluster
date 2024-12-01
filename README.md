# Distributed MySQL Cluster with Proxy and Gatekeeper

## Overview
This project demonstrates the deployment of a distributed MySQL cluster on AWS using Python and Boto3. The architecture includes a **MySQL manager**, **worker nodes**, a **Proxy for load balancing**, and a **Gatekeeper** for added security. The project automates the setup process, configures replication, and benchmarks the system for performance analysis.

## Features
- **MySQL Manager and Workers**: Configured for GTID-based replication to enable a distributed database system.
- **Proxy Pattern**: Handles read and write requests, balancing the load across worker nodes.
- **Gatekeeper Pattern**: Adds a security layer for request validation and forwarding.
- **FastAPI Integration**: Enables REST API endpoints for database interaction.
- **Benchmarking**: Simulates 4000 HTTP requests and logs performance metrics.

## Architecture
1. **Manager Instance**: Central node for managing database writes and replication.
2. **Worker Instances**: Nodes for handling database reads with data synchronized from the manager.
3. **Proxy**: Routes requests to the appropriate nodes based on request type or performance.
4. **Gatekeeper**: Validates and securely forwards traffic to the Proxy.

## Prerequisites
- AWS account with access to EC2, VPC, and S3.
- Python 3.x installed locally.
- `boto3` and `botocore` libraries.
- IAM user with required permissions for AWS resource management.

## Setup Instructions
1. Clone the repository:
   ```bash
   git clone <repository_url>
   cd <repository_directory>
   ```
2. Install Python dependencies:
   ```bash
   pip install boto3 botocore requests paramiko
   ```
3. Run the script:
   ```bash
   python main_script.py
   ```
4. Wait for the instances to deploy and benchmark results to be logged in `benchmark_log.txt`.

## Benchmarking Results
The benchmarking process measures:
- **Throughput**: Requests per second handled by the system.
- **Average Response Time**: Time taken to handle requests.
Results are logged in `benchmark_log.txt` and can be analyzed further.

## Key Files
- `main_script.py`: Automates the setup of the cluster and benchmarking.
- `benchmark_log.txt`: Logs benchmarking results.

## Acknowledgments
This project was developed as part of the **LOG8415 - Advanced Concepts in Cloud Computing** course at **Polytechnique Montréal**.
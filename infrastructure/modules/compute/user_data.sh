#!/bin/bash
# User data script for GPU instances running vLLM with Phi-3 mini
set -e

# Log all output
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting user data script at $(date)"

# Update system packages
apt-get update -y

# Install Python and pip if not present
apt-get install -y python3-pip python3-venv

# Create virtual environment for vLLM
python3 -m venv /opt/vllm-env
source /opt/vllm-env/bin/activate

# Install vLLM
pip install --upgrade pip
pip install vllm

# Install huggingface-cli for model download
pip install huggingface_hub

# Download Phi-3 mini model
echo "Downloading Phi-3 mini model..."
huggingface-cli download microsoft/Phi-3-mini-4k-instruct --local-dir /opt/models/phi-3-mini

# Create systemd service for vLLM
cat > /etc/systemd/system/vllm.service << 'EOF'
[Unit]
Description=vLLM Inference Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt
Environment="PATH=/opt/vllm-env/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=/opt/vllm-env/bin/python -m vllm.entrypoints.openai.api_server \
  --model microsoft/Phi-3-mini-4k-instruct \
  --host 0.0.0.0 \
  --port 8000 \
  --gpu-memory-utilization 0.9 \
  --max-model-len 4096
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start vLLM service
systemctl daemon-reload
systemctl enable vllm
systemctl start vllm

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/user-data"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "LLMInference",
    "metrics_collected": {
      "nvidia_gpu": {
        "measurement": [
          "utilization_gpu",
          "utilization_memory",
          "memory_total",
          "memory_used",
          "memory_free"
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "User data script completed at $(date)"

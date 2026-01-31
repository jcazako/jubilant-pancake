# LLM Inference Service on AWS

A production-ready infrastructure for deploying LLM inference workloads on AWS GPU instances, built with OpenTofu. This project demonstrates proficiency in GPU deployment, monitoring, and cost tracking.

## Skills Demonstrated

### 🖥️ Basic GPU Deployment
- **GPU Instance Configuration**: Deploys `g5.xlarge` instances with NVIDIA A10G GPUs optimized for ML inference
- **Deep Learning AMI**: Pre-configured with CUDA drivers and ML frameworks
- **vLLM Integration**: High-performance inference server for serving Phi-3 mini model
- **Auto Scaling**: Dynamic scaling based on GPU utilization (scale up at 70%, down at 30%)
- **High Availability**: Multi-AZ deployment with Application Load Balancer

### 📊 Monitoring
- **CloudWatch Metrics**: GPU utilization, latency (p50, p95, p99), throughput tracking
- **CloudWatch Alarms**: Automated alerts for p99 latency > 5s and high error rates
- **CloudWatch Dashboard**: Real-time visualization of all key metrics
- **Centralized Logging**: vLLM logs with 30-day retention
- **Health Checks**: Automated instance health monitoring via ALB

### 💰 Cost Tracking
- **Infracost Integration**: PR-based cost estimation before deployment
- **Dashboard Cost Widget**: Real-time estimated cost visualization
- **Right-sizing Variables**: Configurable instance types and scaling limits
- **Environment Separation**: Different configurations for dev/prod cost optimization

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           AWS Cloud                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│  │  CloudFront  │    │ API Gateway  │    │    CloudWatch        │  │
│  │  (Demo UI)   │    │  + WAF       │    │  Dashboard/Alarms    │  │
│  └──────┬───────┘    └──────┬───────┘    └──────────────────────┘  │
│         │                   │                                       │
│         │            ┌──────▼───────┐                               │
│         │            │     ALB      │                               │
│         │            │  (HTTPS)     │                               │
│         │            └──────┬───────┘                               │
│         │                   │                                       │
│         │     ┌─────────────┼─────────────┐                         │
│         │     │             │             │                         │
│         │  ┌──▼───┐     ┌───▼──┐     ┌───▼──┐                      │
│         │  │ GPU  │     │ GPU  │     │ GPU  │  Auto Scaling Group  │
│         │  │ g5.x │     │ g5.x │     │ g5.x │  (1-4 instances)     │
│         │  │ vLLM │     │ vLLM │     │ vLLM │                      │
│         │  └──────┘     └──────┘     └──────┘                      │
│         │                                                           │
│  ┌──────▼───────┐                                                   │
│  │  S3 Bucket   │                                                   │
│  │  (Static)    │                                                   │
│  └──────────────┘                                                   │
└─────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
infrastructure/
├── main.tf              # Root module orchestration
├── variables.tf         # Input variables with validation
├── outputs.tf           # Output values
├── versions.tf          # Provider versions
├── backend.tf           # S3 remote state configuration
├── environments/
│   ├── dev.tfvars       # Development environment config
│   └── prod.tfvars      # Production environment config
└── modules/
    ├── networking/      # VPC, subnets, security groups
    ├── compute/         # GPU instances, ASG, IAM
    ├── load_balancer/   # ALB, target groups, health checks
    ├── api_gateway/     # HTTP API, WAF, rate limiting
    ├── monitoring/      # CloudWatch dashboard, alarms, logs
    └── demo/            # S3 + CloudFront demo interface
```

## Quick Start

### Prerequisites
- [OpenTofu](https://opentofu.org/) >= 1.6.0
- AWS CLI configured with appropriate credentials
- ACM certificate for HTTPS

### Deploy

```bash
# Initialize OpenTofu
cd infrastructure
tofu init

# Plan deployment (dev environment)
tofu plan -var-file=environments/dev.tfvars

# Apply infrastructure
tofu apply -var-file=environments/dev.tfvars
```

### Configuration

Key variables in `variables.tf`:

| Variable | Description | Default |
|----------|-------------|---------|
| `instance_type` | GPU instance type | `g5.xlarge` |
| `min_instances` | Minimum ASG capacity | `1` |
| `max_instances` | Maximum ASG capacity | `4` |
| `scale_up_threshold` | GPU % to trigger scale up | `70` |
| `scale_down_threshold` | GPU % to trigger scale down | `30` |
| `rate_limit_per_ip` | API requests per minute per IP | `100` |

## Monitoring Dashboard

The CloudWatch dashboard includes:
- **Latency Metrics**: p50, p95, p99 response times
- **Throughput**: Requests per second
- **GPU Utilization**: Real-time GPU usage across instances
- **Instance Count**: Current ASG capacity
- **Estimated Cost**: Running cost based on instance hours

## Cost Optimization

- **Dev Environment**: Single instance, lower scaling limits
- **Prod Environment**: Multi-instance with aggressive scaling
- **Infracost CI**: Automatic cost estimation on pull requests
- **Spot Instances**: (Optional) Can be configured for non-critical workloads

## Security

- Private subnets for GPU instances
- ALB in public subnets with HTTPS only
- WAF with IP-based rate limiting
- Security groups with least-privilege access
- Optional API key authentication

## License

MIT

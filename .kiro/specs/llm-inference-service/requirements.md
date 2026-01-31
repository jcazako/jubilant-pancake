# Requirements Document

## Introduction

This document defines the requirements for deploying a basic LLM inference service on AWS using OpenTofu. The service will host Phi-3 mini using vLLM, with auto-scaling, monitoring, a rate-limited REST API, and a public demo interface.

## Glossary

- **Inference_Service**: The containerized application running vLLM that serves model predictions
- **API_Gateway**: AWS API Gateway providing the REST API endpoint with rate limiting
- **Auto_Scaler**: AWS Auto Scaling component that adjusts GPU instance count based on utilization
- **Monitoring_System**: CloudWatch-based monitoring for latency, throughput, and cost metrics
- **Load_Balancer**: Application Load Balancer distributing traffic to inference instances
- **Demo_Interface**: Static web page hosted on S3/CloudFront for public demonstration
- **Cost_Forecast**: Estimated infrastructure costs calculated before deployment
- **OpenTofu**: Open-source infrastructure-as-code tool (Terraform fork) for provisioning AWS resources

## Requirements

### Requirement 1: Model Deployment

**User Story:** As a developer, I want to deploy a small open-source LLM on GPU instances, so that I can serve inference requests efficiently.

#### Acceptance Criteria

1. THE Inference_Service SHALL deploy Phi-3 mini model using vLLM runtime
2. WHEN the Inference_Service starts, THE Inference_Service SHALL load the model into GPU memory and become ready to serve requests within 5 minutes
3. THE Inference_Service SHALL run on AWS GPU instances (g4dn or g5 family)
4. WHEN a health check is performed, THE Inference_Service SHALL respond with status indicating model readiness

### Requirement 2: Infrastructure as Code

**User Story:** As a DevOps engineer, I want all infrastructure defined in OpenTofu, so that I can version control and reproducibly deploy the service.

#### Acceptance Criteria

1. THE OpenTofu_Configuration SHALL define all AWS resources required for the inference service
2. THE OpenTofu_Configuration SHALL use modular structure separating networking, compute, and monitoring concerns
3. WHEN OpenTofu apply is executed, THE OpenTofu_Configuration SHALL create a fully functional inference service
4. THE OpenTofu_Configuration SHALL support multiple environments through variable configuration
5. THE OpenTofu_Configuration SHALL store state remotely in S3 with DynamoDB locking

### Requirement 3: Auto-Scaling

**User Story:** As an operations engineer, I want the service to automatically scale based on GPU utilization, so that I can handle varying load while optimizing costs.

#### Acceptance Criteria

1. WHEN GPU utilization exceeds 70% for 3 minutes, THE Auto_Scaler SHALL add additional inference instances
2. WHEN GPU utilization falls below 30% for 10 minutes, THE Auto_Scaler SHALL remove excess inference instances
3. THE Auto_Scaler SHALL maintain a minimum of 1 running instance at all times
4. THE Auto_Scaler SHALL enforce a maximum instance limit configurable via OpenTofu variables
5. WHILE scaling operations occur, THE Load_Balancer SHALL continue routing traffic to healthy instances

### Requirement 4: Monitoring and Observability

**User Story:** As an operations engineer, I want comprehensive monitoring of latency, throughput, and costs, so that I can ensure service health and optimize spending.

#### Acceptance Criteria

1. THE Monitoring_System SHALL track request latency (p50, p95, p99) via CloudWatch metrics
2. THE Monitoring_System SHALL track throughput (requests per second) via CloudWatch metrics
3. THE Monitoring_System SHALL track estimated costs based on instance runtime and request volume
4. WHEN latency p99 exceeds 5 seconds, THE Monitoring_System SHALL trigger a CloudWatch alarm
5. THE Monitoring_System SHALL provide a CloudWatch dashboard displaying all key metrics
6. THE Monitoring_System SHALL retain metrics for 30 days

### Requirement 5: REST API with Rate Limiting

**User Story:** As a developer, I want a simple REST API with rate limiting, so that I can integrate the inference service into applications while preventing abuse.

#### Acceptance Criteria

1. THE API_Gateway SHALL expose a POST endpoint for inference requests at /v1/completions
2. THE API_Gateway SHALL expose a GET endpoint for health checks at /health
3. WHEN a client IP address exceeds 100 requests per minute, THE API_Gateway SHALL return HTTP 429 status
4. THE API_Gateway SHALL enforce rate limiting based on client IP address
5. THE API_Gateway SHALL optionally support API key authentication for inference requests
6. WHEN API key authentication is enabled and an invalid API key is provided, THE API_Gateway SHALL return HTTP 401 status
7. THE API_Gateway SHALL forward valid requests to the Load_Balancer

### Requirement 6: Networking and Security

**User Story:** As a security engineer, I want the inference service deployed in a secure VPC configuration, so that I can protect the service from unauthorized access.

#### Acceptance Criteria

1. THE OpenTofu_Configuration SHALL create a VPC with public and private subnets across multiple availability zones
2. THE Inference_Service SHALL run in private subnets without direct internet access
3. THE Load_Balancer SHALL be deployed in public subnets
4. THE OpenTofu_Configuration SHALL configure security groups allowing only necessary traffic
5. WHEN traffic arrives from outside the VPC, THE Security_Groups SHALL only permit HTTPS on port 443

### Requirement 7: Error Handling and Resilience

**User Story:** As a developer, I want the service to handle errors gracefully, so that clients receive meaningful error responses.

#### Acceptance Criteria

1. IF the Inference_Service is unavailable, THEN THE Load_Balancer SHALL return HTTP 503 with a retry-after header
2. IF a request times out after 30 seconds, THEN THE API_Gateway SHALL return HTTP 504 status
3. WHEN an inference request contains invalid input, THE Inference_Service SHALL return HTTP 400 with error details
4. THE Load_Balancer SHALL perform health checks every 30 seconds and remove unhealthy instances from rotation

### Requirement 8: Infrastructure Cost Forecasting

**User Story:** As a budget owner, I want to see estimated infrastructure costs before deployment, so that I can plan and approve spending.

#### Acceptance Criteria

1. THE OpenTofu_Configuration SHALL output estimated monthly costs based on configured resources
2. WHEN running OpenTofu plan, THE CI_Pipeline SHALL display cost estimates in PR comments using Infracost
3. THE Cost_Forecast SHALL include estimates for GPU instances, data transfer, API Gateway requests, and CloudWatch
4. THE Cost_Forecast SHALL show cost breakdown by resource type

### Requirement 9: Public Demo Interface

**User Story:** As a visitor, I want a simple web interface to try the LLM, so that I can see what the service can do without writing code.

#### Acceptance Criteria

1. THE Demo_Interface SHALL provide a web page accessible at the root URL (/)
2. THE Demo_Interface SHALL include a text input field for prompts and a submit button
3. WHEN a user submits a prompt, THE Demo_Interface SHALL display the model's response
4. THE Demo_Interface SHALL be served from an S3 bucket with CloudFront distribution
5. THE Demo_Interface SHALL include CORS headers allowing browser requests to the API

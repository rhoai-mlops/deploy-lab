# ML500 MLOps Enablement Lab Deployment

This repository contains the necessary components for instructors to deploy a complete MLOps enablement lab environment on OpenShift using OpenShift AI (RHOAI). This setup is designed for training purposes and **is not intended for student use**.

## Overview

The deployment sets up a comprehensive MLOps environment including:

- Red Hat OpenShift AI (RHOAI) for ML workspaces
- Source control using Gitea
- Model Registry for ML model management
- Feature Store (Feast) for feature management
- MinIO for object storage
- Monitoring and logging infrastructure
- User workspace configuration

## Prerequisites

- OpenShift 4.x cluster with cluster-admin access
- Helm 3.x installed
- `helm` CLI tool configured with cluster access
- Sufficient cluster resources for running the workloads

## Repository Structure

```
.
├── operators/          # OpenShift operator installations
├── student-content/    # Student workspace configurations
├── toolings/          # MLOps tools and monitoring setup
├── Containerfile      # Container build definition
└── install.sh         # Installation script
```

## Components Installed

### Operators
- OpenShift AI Operator
- GitOps Operator
- Service Mesh Operator
- Serverless Operator
- User Workload Monitoring
- Logging Operator
- Advanced Cluster Security

### Tools and Services
- Data Science Projects
- Data Science Pipeline Architecture
- MinIO Object Storage
  - Preconfigured buckets: pipeline, models, data, data-cache
- Model Registry with MySQL backend
- Feast Feature Store
- Gitea Source Control
- Monitoring and Logging Stack

## Deployment Instructions

### Configuration

1. Update the cluster domain in `student-content/values.yaml`:
   ```yaml
   cluster_domain: apps.your-cluster-domain.com
   ```

2. Set the number of attendees:
   ```yaml
   attendees: <number_of_students>
   ```

### Installation Methods

The installation script handles:
- Identity management setup
- Operator installations
- Component deployments
- User workspace configurations

```bash
./install.sh
```

## Post-Installation

After successful deployment:
1. The environment will be available at `https://console-openshift-console.apps.<cluster_domain>`
2. Each student will have their own Data Science Project
3. Access credentials will be created for each configured attendee

## Support

For issues or questions, please open a GitHub issue in this repository.

## Contributing

If you'd like to contribute to this project, please submit a pull request with your proposed changes.

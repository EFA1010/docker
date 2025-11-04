
# Blue-Green Deployment on Multiple Nodes

This directory contains a complete blue-green deployment setup optimized for multi-node Kubernetes clusters.

## 🚀 Quick Start

### Option 1: Deploy on Current Cluster
```bash
cd blue-green-deployment
./deploy-all.sh
```

### Option 2: Set Up Multi-Node Cluster First
```bash
cd blue-green-deployment

# For Minikube (3 nodes)
./setup-multinode.sh minikube

# For Kind (4 nodes)
./setup-multinode.sh kind

# Then deploy
./deploy-all.sh
```

## 📁 Files Overview

| File | Description |
|------|-------------|
| [`blue-deployment.yaml`](blue-deployment.yaml) | Blue version deployment with topology spread constraints |
| [`green-deployment.yaml`](green-deployment.yaml) | Green version deployment with topology spread constraints |
| [`blue-green-service.yaml`](blue-green-service.yaml) | Services for traffic routing and direct access |
| [`blue-green-hpa.yaml`](blue-green-hpa.yaml) | Horizontal Pod Autoscaler for both versions |
| [`redis-simple.yaml`](redis-simple.yaml) | Redis dependency |
| [`switch-traffic.sh`](switch-traffic.sh) | Script to switch traffic between versions |
| [`deploy-all.sh`](deploy-all.sh) | Complete deployment automation |
| [`setup-multinode.sh`](setup-multinode.sh) | Multi-node cluster setup |

## 🎯 Multi-Node Features

### Topology Spread Constraints
Both deployments use `topologySpreadConstraints` to ensure even distribution:

```yaml
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: DoNotSchedule
  labelSelector:
    matchLabels:
      app: guestbook
      version: blue  # or green
```

This ensures:
- ✅ Pods are distributed across different nodes
- ✅ Maximum difference of 1 pod per node
- ✅ High availability and fault tolerance

### Resource Management
- **CPU**: 100m requests, 500m limits
- **Memory**: 128Mi requests, 512Mi limits
- **Replicas**: 3 per version (configurable via HPA)


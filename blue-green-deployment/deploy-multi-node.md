# Blue-Green Deployment on Multiple Nodes

## Current Setup Analysis

Your blue-green deployment scripts are already well-configured for multi-node deployment with:

- ✅ **Topology Spread Constraints**: Both blue and green deployments use `topologySpreadConstraints` with `kubernetes.io/hostname` to distribute pods across nodes
- ✅ **Resource Management**: Proper CPU/memory requests and limits
- ✅ **Health Checks**: Liveness and readiness probes configured
- ✅ **HPA**: Horizontal Pod Autoscaler for both versions
- ✅ **Traffic Switching**: Script to switch between blue and green versions

## Multi-Node Deployment Options

### Option 1: Multi-Node Minikube (Recommended for Testing)

Start a multi-node Minikube cluster:

```bash
# Delete existing single-node cluster
minikube delete

# Start multi-node cluster
minikube start --nodes 3 --cpus 2 --memory 4096

# Verify nodes
kubectl get nodes
```

### Option 2: Kind Multi-Node Cluster

Create a Kind cluster with multiple nodes:

```bash
# Create kind-config.yaml
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF

# Create cluster
kind create cluster --config kind-config.yaml --name multi-node

# Verify nodes
kubectl get nodes
```

### Option 3: Production Cluster (EKS, GKE, AKS)

For production environments, use managed Kubernetes services with multiple worker nodes.

## Deployment Steps

### 1. Verify Multi-Node Setup

```bash
kubectl get nodes -o wide
```

### 2. Deploy Redis (Required Dependency)

```bash
kubectl apply -f blue-green-deployment/redis-simple.yaml
```

### 3. Deploy Blue Version

```bash
kubectl apply -f blue-green-deployment/blue-deployment.yaml
```

### 4. Deploy Green Version

```bash
kubectl apply -f blue-green-deployment/green-deployment.yaml
```

### 5. Deploy Services

```bash
kubectl apply -f blue-green-deployment/blue-green-service.yaml
```

### 6. Deploy HPA (Optional)

```bash
kubectl apply -f blue-green-deployment/blue-green-hpa.yaml
```

### 7. Verify Pod Distribution

```bash
# Check pod distribution across nodes
kubectl get pods -l app=guestbook -o wide

# Check deployment status
./blue-green-deployment/switch-traffic.sh status
```

## Traffic Switching

Use the provided script to switch between versions:

```bash
# Switch to blue version
./blue-green-deployment/switch-traffic.sh blue

# Switch to green version
./blue-green-deployment/switch-traffic.sh green

# Check current status
./blue-green-deployment/switch-traffic.sh status
```

## Monitoring Pod Distribution

Your deployments use `topologySpreadConstraints` with:
- `maxSkew: 1`: Maximum difference in pod count between nodes
- `topologyKey: kubernetes.io/hostname`: Distribute across different nodes
- `whenUnsatisfiable: DoNotSchedule`: Prevent scheduling if constraint can't be met

This ensures even distribution across available nodes.

## Troubleshooting

### Pods Not Distributing Across Nodes

1. Check node labels:
```bash
kubectl get nodes --show-labels
```

2. Check pod scheduling events:
```bash
kubectl describe pods -l app=guestbook
```

3. Verify topology spread constraints:
```bash
kubectl get pods -l app=guestbook -o yaml | grep -A 10 topologySpreadConstraints
```

### Insufficient Nodes

If you have fewer nodes than replicas, some pods may remain pending. Either:
- Reduce replica count
- Add more nodes
- Change `whenUnsatisfiable` to `ScheduleAnyway`
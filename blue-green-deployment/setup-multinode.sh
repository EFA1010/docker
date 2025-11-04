#!/bin/bash

# Multi-Node Cluster Setup Script
# This script helps you set up a multi-node cluster for blue-green deployment

set -e

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

function setup_minikube_multinode() {
    log "Setting up multi-node Minikube cluster..."
    
    # Check if minikube is running
    if minikube status >/dev/null 2>&1; then
        log "Stopping existing Minikube cluster..."
        minikube stop
        minikube delete
    fi
    
    log "Starting 3-node Minikube cluster..."
    minikube start --nodes 2 --cpus 2 --memory 1096 --driver=docker
    
    log "Enabling metrics-server addon..."
    minikube addons enable metrics-server
    
    log "Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    log "✅ Multi-node Minikube cluster is ready!"
    kubectl get nodes -o wide
}

function setup_kind_multinode() {
    log "Setting up multi-node Kind cluster..."
    
    # Create kind config
    cat <<EOF > /tmp/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF

    # Check if cluster exists
    if kind get clusters | grep -q "multi-node"; then
        log "Deleting existing Kind cluster..."
        kind delete cluster --name multi-node
    fi
    
    log "Creating 4-node Kind cluster..."
    kind create cluster --config /tmp/kind-config.yaml --name multi-node
    
    log "Installing metrics-server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch metrics-server for Kind
    kubectl patch deployment metrics-server -n kube-system --type='json' \
        -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
    
    log "Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    log "✅ Multi-node Kind cluster is ready!"
    kubectl get nodes -o wide
}

function check_current_cluster() {
    log "Checking current cluster setup..."
    
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log "❌ No Kubernetes cluster found. Please set up a cluster first."
        return 1
    fi
    
    NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
    log "Current cluster has $NODE_COUNT nodes"
    
    if [ "$NODE_COUNT" -eq 1 ]; then
        log "⚠️  Single-node cluster detected. Consider setting up multi-node for better testing."
        return 1
    else
        log "✅ Multi-node cluster detected"
        kubectl get nodes -o wide
        return 0
    fi
}

function show_help() {
    echo "Multi-Node Cluster Setup"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  minikube  - Set up 3-node Minikube cluster"
    echo "  kind      - Set up 4-node Kind cluster"
    echo "  check     - Check current cluster setup"
    echo "  help      - Show this help message"
    echo ""
    echo "After setting up the cluster, run:"
    echo "  ./deploy-all.sh"
}

# Main logic
case "${1:-check}" in
    "minikube")
        setup_minikube_multinode
        ;;
    "kind")
        setup_kind_multinode
        ;;
    "check")
        if check_current_cluster; then
            log "Ready to deploy blue-green setup!"
            echo "Run: ./deploy-all.sh"
        else
            log "Set up a multi-node cluster first:"
            echo "  ./setup-multinode.sh minikube"
            echo "  ./setup-multinode.sh kind"
        fi
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
#!/bin/bash

# Blue-Green Multi-Node Deployment Script
# This script deploys the complete blue-green setup and verifies multi-node distribution

set -e

NAMESPACE=${NAMESPACE:-default}
WAIT_TIMEOUT=300

function log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

function check_nodes() {
    log "Checking cluster nodes..."
    NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
    log "Found $NODE_COUNT nodes in the cluster"
    
    if [ "$NODE_COUNT" -eq 1 ]; then
        log "⚠️  WARNING: Only 1 node detected. For true multi-node deployment:"
        log "   - Use: minikube start --nodes 3"
        log "   - Or create a multi-node Kind/cloud cluster"
        log "   - Continuing with single-node deployment..."
    else
        log "✅ Multi-node cluster detected ($NODE_COUNT nodes)"
    fi
    
    kubectl get nodes -o wide
}

function deploy_redis() {
    log "Deploying Redis..."
    if kubectl get deployment redis-simple -n $NAMESPACE >/dev/null 2>&1; then
        log "Redis already exists, skipping..."
    else
        kubectl apply -f redis-simple.yaml -n $NAMESPACE
        log "Waiting for Redis to be ready..."
        kubectl wait --for=condition=available --timeout=${WAIT_TIMEOUT}s deployment/redis-simple -n $NAMESPACE
    fi
}

function deploy_blue_green() {
    log "Deploying Blue version..."
    kubectl apply -f blue-deployment.yaml -n $NAMESPACE
    
    log "Deploying Green version..."
    kubectl apply -f green-deployment.yaml -n $NAMESPACE
    
    log "Deploying Services..."
    kubectl apply -f blue-green-service.yaml -n $NAMESPACE
    
    log "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=${WAIT_TIMEOUT}s deployment/guestbook-blue -n $NAMESPACE
    kubectl wait --for=condition=available --timeout=${WAIT_TIMEOUT}s deployment/guestbook-green -n $NAMESPACE
}

function deploy_hpa() {
    log "Deploying HPA (if metrics-server is available)..."
    if kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
        kubectl apply -f blue-green-hpa.yaml -n $NAMESPACE
        log "✅ HPA deployed"
    else
        log "⚠️  Metrics-server not found, skipping HPA deployment"
        log "   To enable HPA: minikube addons enable metrics-server"
    fi
}

function verify_distribution() {
    log "Verifying pod distribution across nodes..."
    echo ""
    echo "=== Pod Distribution ==="
    kubectl get pods -l app=guestbook -o wide -n $NAMESPACE
    
    echo ""
    echo "=== Blue Pods by Node ==="
    kubectl get pods -l app=guestbook,version=blue -o wide -n $NAMESPACE | awk 'NR>1 {print $7}' | sort | uniq -c
    
    echo ""
    echo "=== Green Pods by Node ==="
    kubectl get pods -l app=guestbook,version=green -o wide -n $NAMESPACE | awk 'NR>1 {print $7}' | sort | uniq -c
}

function show_status() {
    log "Deployment Status:"
    ./switch-traffic.sh status
    
    echo ""
    log "Service Endpoints:"
    kubectl get services -l app=guestbook -n $NAMESPACE
    
    echo ""
    log "To test the deployment:"
    echo "  kubectl port-forward service/guestbook-bluegreen 8080:3030"
    echo "  curl http://localhost:8080"
    
    echo ""
    log "To switch traffic:"
    echo "  ./switch-traffic.sh blue   # Switch to blue version"
    echo "  ./switch-traffic.sh green  # Switch to green version"
}

function cleanup() {
    log "Cleaning up previous deployments..."
    kubectl delete deployment guestbook-blue guestbook-green -n $NAMESPACE --ignore-not-found=true
    kubectl delete service guestbook-bluegreen guestbook-blue-direct guestbook-green-direct -n $NAMESPACE --ignore-not-found=true
    kubectl delete hpa guestbook-blue-hpa guestbook-green-hpa -n $NAMESPACE --ignore-not-found=true
    sleep 5
}

function main() {
    log "Starting Blue-Green Multi-Node Deployment"
    
    # Change to script directory
    cd "$(dirname "$0")"
    
    case "${1:-deploy}" in
        "deploy")
            check_nodes
            deploy_redis
            deploy_blue_green
            deploy_hpa
            sleep 10  # Wait for pods to be scheduled
            verify_distribution
            show_status
            ;;
        "clean")
            cleanup
            ;;
        "status")
            verify_distribution
            show_status
            ;;
        "redeploy")
            cleanup
            check_nodes
            deploy_redis
            deploy_blue_green
            deploy_hpa
            sleep 10
            verify_distribution
            show_status
            ;;
        *)
            echo "Usage: $0 [deploy|clean|status|redeploy]"
            echo ""
            echo "Commands:"
            echo "  deploy    - Deploy blue-green setup (default)"
            echo "  clean     - Clean up deployments"
            echo "  status    - Show current status and distribution"
            echo "  redeploy  - Clean and redeploy everything"
            exit 1
            ;;
    esac
    
    log "✅ Blue-Green deployment completed successfully!"
}

main "$@"
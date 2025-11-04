#!/bin/bash

# Blue-Green Deployment Traffic Switch Script
# Usage: ./switch-traffic.sh [blue|green|status]

set -e

NAMESPACE=${NAMESPACE:-default}
SERVICE_NAME="guestbook-bluegreen"

function show_status() {
    echo "=== Blue-Green Deployment Status ==="
    
    # Check current service selector
    CURRENT_VERSION=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "Service not found")
    echo "Current active version: $CURRENT_VERSION"
    
    # Check deployments
    echo ""
    echo "Deployment Status:"
    kubectl get deployments -l app=guestbook -n $NAMESPACE 2>/dev/null || echo "No guestbook deployments found"
    
    # Check pods
    echo ""
    echo "Pod Status:"
    kubectl get pods -l app=guestbook -n $NAMESPACE 2>/dev/null || echo "No guestbook pods found"
    
    # Check services
    echo ""
    echo "Service Status:"
    kubectl get services -l app=guestbook -n $NAMESPACE 2>/dev/null || echo "No guestbook services found"
}

function switch_to_blue() {
    echo "Switching traffic to BLUE version..."
    kubectl patch service $SERVICE_NAME -n $NAMESPACE -p '{"spec":{"selector":{"app":"guestbook","version":"blue"}}}'
    echo "✅ Traffic switched to BLUE version"
    
    # Verify the switch
    sleep 2
    CURRENT_VERSION=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
    echo "Current active version: $CURRENT_VERSION"
}

function switch_to_green() {
    echo "Switching traffic to GREEN version..."
    kubectl patch service $SERVICE_NAME -n $NAMESPACE -p '{"spec":{"selector":{"app":"guestbook","version":"green"}}}'
    echo "✅ Traffic switched to GREEN version"
    
    # Verify the switch
    sleep 2
    CURRENT_VERSION=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
    echo "Current active version: $CURRENT_VERSION"
}

function show_help() {
    echo "Blue-Green Deployment Manager"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  blue     - Switch traffic to blue version"
    echo "  green    - Switch traffic to green version"
    echo "  status   - Show current deployment status"
    echo "  help     - Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  NAMESPACE - Kubernetes namespace (default: default)"
}

# Main logic
case "${1:-status}" in
    "blue")
        switch_to_blue
        ;;
    "green")
        switch_to_green
        ;;
    "status")
        show_status
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
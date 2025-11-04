#!/bin/bash

# Chaos Engineering Experiments for Guestbook Blue-Green Deployment
# This script manages chaos experiments to test system resilience

set -e

NAMESPACE="default"
CHAOS_NAMESPACE="chaos-mesh"

echo "🔥 Chaos Engineering for Guestbook Blue-Green Deployment"
echo "========================================================"

# Function to check if Chaos Mesh is ready
check_chaos_mesh() {
    echo "📋 Checking Chaos Mesh installation..."
    kubectl get pods -n ${CHAOS_NAMESPACE} | grep -E "(chaos-controller|chaos-daemon)" || {
        echo "❌ Chaos Mesh is not properly installed"
        exit 1
    }
    echo "✅ Chaos Mesh is running"
}

# Function to show current pod status
show_pod_status() {
    echo "📊 Current Guestbook Pod Status:"
    echo "================================"
    kubectl get pods -l app=guestbook -n ${NAMESPACE} -o wide
    echo ""
}

# Function to apply chaos experiments
apply_chaos_experiments() {
    echo "🚀 Applying Chaos Experiments..."
    kubectl apply -f chaos-pod-kill-experiment.yaml
    echo "✅ Chaos experiments applied"
    echo ""
}

# Function to list active chaos experiments
list_experiments() {
    echo "📋 Active Chaos Experiments:"
    echo "============================"
    kubectl get podchaos,schedule -n ${NAMESPACE}
    echo ""
}

# Function to run a one-time pod kill experiment
run_immediate_experiment() {
    echo "💥 Running immediate pod-kill experiment..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: guestbook-immediate-kill
  namespace: ${NAMESPACE}
spec:
  action: pod-kill
  mode: one
  duration: "10s"
  selector:
    namespaces:
      - ${NAMESPACE}
    labelSelectors:
      "app": "guestbook"
EOF
    
    echo "✅ Immediate experiment started"
    echo "⏱️  Waiting 15 seconds to observe impact..."
    sleep 15
    
    echo "📊 Pod status after experiment:"
    show_pod_status
    
    # Clean up immediate experiment
    kubectl delete podchaos guestbook-immediate-kill -n ${NAMESPACE} --ignore-not-found=true
}

# Function to monitor system recovery
monitor_recovery() {
    echo "🔍 Monitoring System Recovery..."
    echo "==============================="
    
    for i in {1..10}; do
        echo "📊 Check $i/10 - $(date)"
        kubectl get pods -l app=guestbook -n ${NAMESPACE} --no-headers | while read line; do
            pod_name=$(echo $line | awk '{print $1}')
            status=$(echo $line | awk '{print $3}')
            ready=$(echo $line | awk '{print $2}')
            restarts=$(echo $line | awk '{print $4}')
            echo "  Pod: $pod_name | Status: $status | Ready: $ready | Restarts: $restarts"
        done
        echo ""
        sleep 30
    done
}

# Function to clean up experiments
cleanup_experiments() {
    echo "🧹 Cleaning up chaos experiments..."
    kubectl delete podchaos --all -n ${NAMESPACE} --ignore-not-found=true
    kubectl delete schedule --all -n ${NAMESPACE} --ignore-not-found=true
    echo "✅ Cleanup completed"
}

# Function to show metrics impact
show_metrics_impact() {
    echo "📈 Metrics Impact Analysis:"
    echo "=========================="
    echo "🔗 Access Grafana dashboard at: http://localhost:3001"
    echo "📊 Monitor the following panels:"
    echo "   - Pod Availability by Version"
    echo "   - Pod Restart Count"
    echo "   - Resource Utilization"
    echo "   - Application Health Overview"
    echo ""
    echo "🚨 Expected alerts to trigger:"
    echo "   - GuestbookPodNotReady"
    echo "   - GuestbookHighRestartRate"
    echo "   - GuestbookLowAvailability (if enough pods are killed)"
    echo ""
}

# Main menu
case "${1:-menu}" in
    "check")
        check_chaos_mesh
        ;;
    "status")
        show_pod_status
        ;;
    "apply")
        check_chaos_mesh
        apply_chaos_experiments
        list_experiments
        ;;
    "immediate")
        check_chaos_mesh
        show_pod_status
        run_immediate_experiment
        ;;
    "monitor")
        monitor_recovery
        ;;
    "list")
        list_experiments
        ;;
    "cleanup")
        cleanup_experiments
        ;;
    "metrics")
        show_metrics_impact
        ;;
    "full-test")
        echo "🎯 Running Full Chaos Engineering Test"
        echo "======================================"
        check_chaos_mesh
        show_pod_status
        show_metrics_impact
        echo "⏱️  Starting in 10 seconds... (Ctrl+C to cancel)"
        sleep 10
        run_immediate_experiment
        echo "🔄 Monitoring recovery for 5 minutes..."
        monitor_recovery
        ;;
    *)
        echo "Usage: $0 {check|status|apply|immediate|monitor|list|cleanup|metrics|full-test}"
        echo ""
        echo "Commands:"
        echo "  check      - Check if Chaos Mesh is ready"
        echo "  status     - Show current pod status"
        echo "  apply      - Apply scheduled chaos experiments"
        echo "  immediate  - Run immediate pod-kill experiment"
        echo "  monitor    - Monitor system recovery (5 minutes)"
        echo "  list       - List active experiments"
        echo "  cleanup    - Remove all chaos experiments"
        echo "  metrics    - Show metrics monitoring instructions"
        echo "  full-test  - Run complete chaos engineering test"
        echo ""
        ;;
esac
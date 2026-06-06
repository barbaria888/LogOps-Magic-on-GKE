#!/usr/bin/env bash

# GKE Day-2 Operations Setup Helper
# Automates GKE cluster connection verification and Online Boutique application deployment.

set -euo pipefail

ZONE="europe-west4-c"
CLUSTER_NAME="day2-ops"
REGION="europe-west4"

echo "=== GKE Day-2 Operations Infrastructure Setup ==="

# 1. Configure zone
echo "Setting compute zone to $ZONE..."
gcloud config set compute/zone "$ZONE"

# 2. Check cluster status
echo "Fetching GKE clusters..."
gcloud container clusters list

# 3. Get credentials
echo "Acquiring cluster credentials for $CLUSTER_NAME..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION"

# 4. Verify Nodes
echo "Verifying active Kubernetes nodes..."
kubectl get nodes

# 5. Deploy Online Boutique Application
echo "Cloning microservices-demo repository..."
if [ ! -d "microservices-demo" ]; then
  git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
fi

cd microservices-demo

echo "Deploying applications using Kubernetes manifests..."
kubectl apply -f release/kubernetes-manifests.yaml

# 6. Verify deployment status
echo "Waiting for pod resources to initialize (Press Ctrl+C to stop polling manually)..."
kubectl get pods -w

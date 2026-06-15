#!/usr/bin/env bash


set -euo pipefail

ZONE="europe-west4-c"
CLUSTER_NAME="day2-ops"
REGION="europe-west4"

# 1. Configure zone
echo "Setting compute zone to $ZONE..."
gcloud config set compute/zone "$ZONE"

# 2. Check cluster status
echo "Fetching GKE clusters..."
gcloud container clusters list

# 3. Geting credentials

gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION"

# 4. Verify Nodes

kubectl get nodes

# 5. Deploy Online Boutique Application

if [ ! -d "microservices-demo" ]; then
  git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
fi
cd microservices-demo

echo "Deploying applications using Kubernetes manifests..."
kubectl apply -f release/kubernetes-manifests.yaml

# 6. Verify pod status

kubectl get pods -w

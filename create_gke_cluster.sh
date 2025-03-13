#!/bin/bash

# Variables
PROJECT="your-project"
ZONE="us-west1-a"
USER=$(gcloud config get-value account)
HOOK_SECRET_PATH="/path/to/hook/secret"
GITHUB_CERT_PATH="/path/to/github/cert"
APP_ID="<The ID of your app>"

# Export project and zone
echo "Setting up GKE Cluster in project: $PROJECT and zone: $ZONE"
export PROJECT=$PROJECT
export ZONE=$ZONE

# Create GKE Cluster
gcloud container --project "$PROJECT" clusters create prow \
  --zone "$ZONE" --machine-type n1-standard-4 --num-nodes 2

# Configure cluster admin role bindings
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin --user "$USER"
kubectl create clusterrolebinding cluster-admin-binding-"${USER}" \
  --clusterrole=cluster-admin --user="${USER}"

# Create the 'prow' namespace
kubectl create namespace prow

# Generate and store the HMAC token
openssl rand -hex 20 > "$HOOK_SECRET_PATH"
kubectl create secret -n prow generic hmac-token --from-file=hmac="$HOOK_SECRET_PATH"

# Create GitHub secret with cert and app ID
kubectl create secret -n prow generic github-token \
  --from-file=cert="$GITHUB_CERT_PATH" --from-literal=appid="$APP_ID"

echo "GKE Cluster setup complete!"


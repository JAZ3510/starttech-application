#!/usr/bin/env bash
# Roll the backend back to the previous (or a specific) revision.
# Usage: ./scripts/rollback.sh [revision]
set -euo pipefail
if [ -n "${1:-}" ]; then
  kubectl rollout undo deployment/backend-api --to-revision="$1"
else
  kubectl rollout undo deployment/backend-api
fi
kubectl rollout status deployment/backend-api --timeout=300s
kubectl rollout history deployment/backend-api

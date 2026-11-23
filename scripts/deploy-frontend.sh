#!/usr/bin/env bash
# Usage: S3_BUCKET=<bucket> CLOUDFRONT_DISTRIBUTION_ID=<id> ./scripts/deploy-frontend.sh
set -euo pipefail
: "${S3_BUCKET:?set S3_BUCKET}"
: "${CLOUDFRONT_DISTRIBUTION_ID:?set CLOUDFRONT_DISTRIBUTION_ID}"

cd "$(dirname "$0")/../frontend"
npm ci
npm audit --audit-level=high
npm run build
aws s3 sync dist/ "s3://${S3_BUCKET}" --delete
aws cloudfront create-invalidation --distribution-id "${CLOUDFRONT_DISTRIBUTION_ID}" --paths "/*"

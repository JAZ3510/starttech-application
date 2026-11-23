#!/usr/bin/env bash
# Usage: ./scripts/health-check.sh https://dxxxx.cloudfront.net
set -euo pipefail
BASE_URL="${1:?Usage: $0 <cloudfront-base-url>}"
RETRIES="${RETRIES:-10}"

check() {
  local url="$1" expected="$2" code
  for i in $(seq 1 "${RETRIES}"); do
    code="$(curl -s -o /dev/null -w '%{http_code}' "${url}" || true)"
    if [ "${code}" = "${expected}" ]; then
      echo "OK   ${url} -> ${code}"
      return 0
    fi
    echo "WAIT ${url} -> ${code} (attempt ${i}/${RETRIES})"
    sleep 6
  done
  echo "FAIL ${url} (expected ${expected})"
  return 1
}

check "${BASE_URL}/" 200
check "${BASE_URL}/dashboard" 200          # SPA deep link (403/404 -> index.html 200)
check "${BASE_URL}/api/v1/health" 200      # API through CloudFront -> ALB
echo "All health checks passed"

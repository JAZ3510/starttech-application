# starttech-application

React frontend + Go backend, delivered to S3/CloudFront and Amazon EKS by GitHub Actions.

```
frontend/   React (Vite) app - calls the API with relative paths (/api/v1/...)
backend/    Go REST API - port 8080, /api/v1/health and /health, JSON logs on stdout
k8s/        deployment.yaml (RollingUpdate maxSurge 1 / maxUnavailable 0), service.yaml, ingress.yaml (alb)
scripts/    deploy-frontend.sh, deploy-backend.sh, health-check.sh, rollback.sh
.github/workflows/frontend-ci-cd.yml, backend-ci-cd.yml
```

> The code in `frontend/` and `backend/` is a minimal working skeleton. Copy in the real application
> from the `much-to-do` repo (branch `feature/full-stack`), keeping port 8080, the env vars
> `REDIS_HOST` / `MONGO_URI`, the health endpoint, JSON logging and relative `/api` URLs.

## Required GitHub secrets

| Secret | Value |
| --- | --- |
| AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_REGION | Deployer credentials (add its ARN to `eks_admin_principal_arns` in starttech-infra) |
| S3_BUCKET_NAME | `terraform output frontend_bucket_name` |
| CLOUDFRONT_DISTRIBUTION_ID | `terraform output cloudfront_distribution_id` |
| REDIS_HOST | `terraform output redis_endpoint` |
| MONGO_URI | MongoDB Atlas connection string (allow the NAT gateway IPs in Atlas network access) |

## Flow

1. Backend pipeline: `go test` -> docker build (tag = git SHA) -> Trivy scan -> push to ECR ->
   patch `k8s/deployment.yaml` -> `aws eks update-kubeconfig` -> `kubectl apply -f k8s/` ->
   `kubectl rollout status deployment/backend-api`.
2. Frontend pipeline: `npm ci` -> `npm audit` -> `npm run build` -> `aws s3 sync` -> CloudFront invalidation.
3. After the first backend deploy: `kubectl get ingress backend-api` -> put the ALB hostname into the infra repo (`alb_dns_name`) and re-apply.
4. Verify: `./scripts/health-check.sh https://<distribution>.cloudfront.net`. Roll back with `./scripts/rollback.sh`.

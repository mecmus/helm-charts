# ODK Central Helm Chart

A Helm chart for deploying [ODK Central](https://github.com/getodk/central) on Kubernetes.

ODK Central is the ODK server: it manages form definitions and submissions, and includes a web user interface.

## Architecture

```
                         ┌──────────────────────────────────────────┐
                         │              Kubernetes Cluster           │
                         │                                           │
Internet ─── Ingress ──► │  nginx (port 80)                         │
             (TLS)       │    │                                      │
                         │    ├──► service/backend (port 8383)       │
                         │    │        │                             │
                         │    │        ├──► postgres (port 5432)     │
                         │    │        └──► smtp2graph (port 587)    │
                         │    │                                      │
                         │    └──► enketo (port 8005)                │
                         │             ├──► enketo-redis-main (6379) │
                         │             ├──► enketo-redis-cache (6380) │
                         │             └──► pyxform (port 80)        │
                         └──────────────────────────────────────────┘
```

## Services

| Service | Image | Port | Role |
|---------|-------|------|------|
| `service` | `ghcr.io/getodk/central-service` | 8383 | Backend API Node.js |
| `nginx` | `ghcr.io/getodk/central-nginx` | 80 | Frontend + reverse proxy |
| `enketo` | `ghcr.io/getodk/central-enketo` | 8005 | Web forms |
| `pyxform` | `ghcr.io/getodk/pyxform-http` | 80 | XLSForm conversion |
| `postgres` | `postgres:14` | 5432 | PostgreSQL database |
| `enketo-redis-main` | `redis:7.4.7` | 6379 | Redis for Enketo |
| `enketo-redis-cache` | `redis:7.4.7` | 6380 | Redis XSLT cache |
| `smtp2graph` | `smtp2graph/smtp2graph` | 587 | SMTP → Microsoft Graph API |

## Prerequisites

- Kubernetes 1.19+
- [cert-manager](https://cert-manager.io/) for TLS certificate management
- An Ingress controller (e.g., nginx-ingress)
- A `ClusterIssuer` named `letsencrypt-prod` (or adjust the annotation in values)

## Quick Start

```bash
helm install odk charts/odk-central/ \
  --set domain=odk.example.com \
  --set sysadminEmail=admin@example.com \
  --set smtp2graph.tenantId=<tenant-id> \
  --set smtp2graph.clientId=<client-id> \
  --set smtp2graph.clientSecret=<client-secret> \
  --set smtp2graph.fromAddress=noreply@example.com \
  --set oidc.issuerUrl=https://login.microsoftonline.com/<tenant-id>/v2.0 \
  --set oidc.clientId=<client-id> \
  --set oidc.clientSecret=<client-secret> \
  --set s3.accessKey=<access-key> \
  --set s3.secretKey=<secret-key>
```

## First Admin User

After deployment, create the first admin user:

```bash
# Find the service pod
kubectl get pods -l app.kubernetes.io/component=service

# Create the user
kubectl exec <service-pod> -- odk-cmd --email admin@example.com user-create

# Promote to admin
kubectl exec <service-pod> -- odk-cmd --email admin@example.com user-promote
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `domain` | ODK Central domain | `odk.example.com` |
| `sysadminEmail` | Admin email address | `admin@example.com` |
| `httpsPort` | HTTPS port (used in URL construction) | `"443"` |
| `service.image.tag` | Backend service image tag | `v2024.3.1` |
| `nginx.image.tag` | Nginx image tag | `v2024.3.1` |
| `enketo.image.tag` | Enketo image tag | `v2024.3.1` |
| `pyxform.image.tag` | PyXForm image tag | `v4.2.0` |
| `postgres.database` | PostgreSQL database name | `odk` |
| `postgres.user` | PostgreSQL username | `odk` |
| `postgres.storage.size` | PostgreSQL PVC size | `10Gi` |
| `redis.image.tag` | Redis image tag | `7.4.7` |
| `redis.main.storage.size` | Redis main PVC size | `1Gi` |
| `redis.cache.storage.size` | Redis cache PVC size | `1Gi` |
| `smtp2graph.enabled` | Enable SMTP2Graph relay | `true` |
| `smtp2graph.tenantId` | Azure tenant ID | `""` |
| `smtp2graph.clientId` | Azure app client ID | `""` |
| `smtp2graph.clientSecret` | Azure app client secret | `""` |
| `smtp2graph.fromAddress` | From email address | `""` |
| `email.from` | Email from address | `noreply@example.com` |
| `email.port` | SMTP port | `587` |
| `oidc.enabled` | Enable OIDC authentication | `true` |
| `oidc.issuerUrl` | OIDC issuer URL | `""` |
| `oidc.clientId` | OIDC client ID | `""` |
| `oidc.clientSecret` | OIDC client secret | `""` |
| `s3.enabled` | Enable S3 storage | `true` |
| `s3.server` | S3 server endpoint | `s3.gra.io.cloud.ovh.net` |
| `s3.accessKey` | S3 access key | `""` |
| `s3.secretKey` | S3 secret key | `""` |
| `s3.bucketName` | S3 bucket name | `odk-central` |
| `sentry.key` | Sentry DSN key | `""` |
| `session.lifetime` | Session lifetime in seconds | `86400` |
| `transfer.storage.size` | Transfer data PVC size | `10Gi` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | cert-manager annotation |
| `ingress.tls` | TLS configuration | see values.yaml |
| `existingSecrets.enketo` | Existing secret name for Enketo keys | `""` |
| `existingSecrets.postgres` | Existing secret name for Postgres password | `""` |
| `existingSecrets.smtp2graph` | Existing secret name for SMTP2Graph | `""` |
| `existingSecrets.oidc` | Existing secret name for OIDC | `""` |
| `existingSecrets.s3` | Existing secret name for S3 | `""` |

## SMTP2Graph Setup (Entra ID / Microsoft 365)

This chart uses [smtp2graph](https://github.com/smtp2graph/smtp2graph) as an SMTP relay that forwards emails via the Microsoft Graph API. This is useful for organizations using Microsoft 365 that do not allow traditional SMTP relay.

### Setup steps

1. Register an application in Azure Active Directory (Entra ID)
2. Add the `Mail.Send` API permission (Application permission)
3. Grant admin consent
4. Create a client secret
5. Configure the values:

```yaml
smtp2graph:
  enabled: true
  tenantId: "your-tenant-id"
  clientId: "your-client-id"
  clientSecret: "your-client-secret"
  fromAddress: "noreply@yourdomain.com"
```

## S3 Storage (OVH Graveline)

ODK Central supports storing form attachments in S3-compatible object storage.

```yaml
s3:
  enabled: true
  server: "s3.gra.io.cloud.ovh.net"
  accessKey: "your-access-key"
  secretKey: "your-secret-key"
  bucketName: "odk-central"
```

Create the bucket in your OVH control panel and ensure it is private.

## Using Existing Secrets

To use pre-existing Kubernetes secrets instead of auto-generated ones:

```yaml
existingSecrets:
  enketo: "my-enketo-secret"     # must have keys: enketo-secret, enketo-less-secret, enketo-api-key
  postgres: "my-postgres-secret" # must have key: password
  smtp2graph: "my-smtp-secret"   # must have keys: tenant-id, client-id, client-secret, from-address
  oidc: "my-oidc-secret"         # must have keys: client-id, client-secret
  s3: "my-s3-secret"             # must have keys: access-key, secret-key
```

## Notes on SSL/TLS

The nginx container runs with `SSL_TYPE=upstream`, meaning:
- Nginx listens on port 80 only (no TLS termination)
- TLS is handled by the Kubernetes Ingress + cert-manager
- The `X-Forwarded-Proto: https` header is set on proxied requests

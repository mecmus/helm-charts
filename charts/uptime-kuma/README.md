# Uptime Kuma Helm Chart

This chart deploys [Uptime Kuma](https://github.com/louislam/uptime-kuma) and can initialize the first admin account automatically through the Uptime Kuma API.

## Installation

```bash
helm install uptime-kuma ./charts/uptime-kuma \
  --set admin.username=admin \
  --set admin.password='change-me-with-a-strong-password'
```

## Admin initialization

The `admin-init` Job runs as a Helm `post-install,post-upgrade` hook. It waits for Uptime Kuma, checks whether the initial setup is still required, and creates the admin user from the configured values. If the instance is already initialized, the Job exits successfully.

For production, prefer `admin.existingSecret` so the password is not stored in Helm values.

## Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Uptime Kuma image repository | `louislam/uptime-kuma` |
| `image.tag` | Uptime Kuma image tag | `2.3.2` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `ingress.enabled` | Enable ingress | `false` |
| `persistence.enabled` | Enable persistent storage for `/app/data` | `true` |
| `persistence.size` | PVC size | `4Gi` |
| `admin.enabled` | Enable admin initialization Job | `true` |
| `admin.username` | Admin username used when the chart creates the secret | `admin` |
| `admin.password` | Admin password used when the chart creates the secret; generated when empty | `""` |
| `admin.existingSecret` | Existing secret containing admin credentials | `""` |
| `admin.existingSecretUsernameKey` | Username key in the admin secret | `username` |
| `admin.existingSecretPasswordKey` | Password key in the admin secret | `password` |

## Existing secret example

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: uptime-kuma-admin
type: Opaque
stringData:
  username: admin
  password: change-me-with-a-strong-password
```

Then install with:

```yaml
admin:
  existingSecret: uptime-kuma-admin
```

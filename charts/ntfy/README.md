# ntfy Helm Chart

This chart deploys [ntfy](https://github.com/binwiederhier/ntfy), a lightweight pub-sub notification server.

## Installation

```bash
helm install ntfy ./charts/ntfy
```

The Deployment uses a `Recreate` strategy by default to avoid multiple pods mounting the same `ReadWriteOnce` data volume during updates.

## Configuration

The chart renders `.Values.config` into `/etc/ntfy/server.yml`, so you can override the default ntfy settings or add any supported server option.

By default, the chart stores ntfy cache, attachments, and auth data in `/var/cache/ntfy` and persists that directory with a PVC.

## Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | ntfy image repository | `binwiederhier/ntfy` |
| `image.tag` | ntfy image tag | `2.25.0` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Kubernetes service port | `80` |
| `service.targetPort` | ntfy container HTTP port | `80` |
| `ingress.enabled` | Enable ingress | `false` |
| `persistence.enabled` | Enable persistent storage for `/var/cache/ntfy` | `true` |
| `persistence.size` | PVC size | `2Gi` |
| `config.base-url` | Public base URL advertised by ntfy | `https://ntfy.local` |
| `config.listen-http` | HTTP listen address for ntfy | `:80` |
| `config.behind-proxy` | Trust forwarded headers from a reverse proxy | `true` |
| `config.cache-file` | Persistent cache database path | `/var/cache/ntfy/cache.db` |
| `config.auth-file` | Persistent auth database path | `/var/cache/ntfy/auth.db` |
| `config.auth-default-access` | Default access policy for unauthenticated users | `read-write` |
| `config.attachment-cache-dir` | Persistent attachments directory | `/var/cache/ntfy/attachments` |

## Custom configuration example

```yaml
config:
  base-url: https://ntfy.example.com
  behind-proxy: true
  auth-default-access: deny-all
  upstream-base-url: https://ntfy.sh
```

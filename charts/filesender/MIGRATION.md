# Migration Guide: SimpleSAMLphp to OIDC/Fake Auth

## Overview

This guide helps you migrate from the old FileSender chart (with SimpleSAMLphp) to the new lightweight version with OIDC or Fake authentication.

## Breaking Changes

### 1. Docker Image Changes

**Old:**
- Image: Based on Docker Hardened Image (DHI)
- Port: 9000 (PHP-FPM only)
- Architecture: FPM-only, requires external web server

**New:**
- Image: Alpine-based with nginx + PHP-FPM
- Port: 80 (HTTP)
- Architecture: Standalone with integrated nginx

### 2. Authentication Changes

**Old:**
```yaml
config:
  sso:
    enabled: true
    type: "saml2"
    sp_entity_id: "..."
    idp_entity_id: "..."
```

**New:**
```yaml
filesender:
  auth:
    type: "oidc"  # or "fake"
    oidc:
      issuer: "https://login.microsoftonline.com/TENANT_ID/v2.0"
      clientId: "..."
      clientSecret: "..."
```

### 3. Configuration Structure Changes

**Old:**
```yaml
config:
  site_url: "..."
  admin_email: "..."
  db:
    type: "pgsql"
    host: "..."
```

**New:**
```yaml
filesender:
  siteUrl: "..."
  adminEmail: "..."
postgresql:
  internal:
    enabled: true
  external:
    enabled: false
```

### 4. Service Port Changes

**Old:**
```yaml
service:
  port: 9000  # PHP-FPM
```

**New:**
```yaml
service:
  port: 80  # HTTP (nginx)
```

### 5. Ingress Annotations

**Old:**
```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "FASTCGI"
```

**New:**
```yaml
ingress:
  annotations:
    # Standard HTTP backend - no special protocol needed
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
```

## Migration Steps

### Step 1: Backup Current Data

```bash
# Backup database
kubectl exec -it <filesender-pod> -- pg_dump > filesender-backup.sql

# Backup uploaded files (if using PVC)
kubectl cp <filesender-pod>:/var/www/html/files ./filesender-files-backup
```

### Step 2: Prepare New Configuration

Create a new `values.yaml` based on your current setup:

#### For Production (OIDC with Azure AD):

```yaml
filesender:
  siteUrl: "https://your-filesender.com"
  siteName: "Your FileSender"
  admin: "admin@yourdomain.com"
  adminEmail: "admin@yourdomain.com"
  
  auth:
    type: "oidc"
    oidc:
      issuer: "https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0"
      clientId: "YOUR_CLIENT_ID"
      clientSecret: "YOUR_CLIENT_SECRET"

postgresql:
  internal:
    enabled: true
    persistence:
      enabled: true
      size: 20Gi

persistence:
  enabled: true
  size: 100Gi

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: your-filesender.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: filesender-tls
      hosts:
        - your-filesender.com
```

#### For Development/Testing (Fake Auth):

```yaml
filesender:
  siteUrl: "http://localhost:8080"
  auth:
    type: "fake"
    fake:
      enabled: true
      uid: "testuser"
      email: "test@example.com"
      name: "Test User"

postgresql:
  internal:
    enabled: true
    persistence:
      enabled: false

persistence:
  enabled: false

ingress:
  enabled: false
```

### Step 3: Azure AD Configuration (for OIDC)

1. Go to **Azure Portal** → **Azure Active Directory** → **App registrations**
2. Click **New registration**
3. Configure:
   - Name: FileSender
   - Redirect URI: `https://your-filesender.com/oidc.php`
4. Note the **Application (client) ID** and **Directory (tenant) ID**
5. Create a **Client secret** and note the value

### Step 4: Uninstall Old Chart

```bash
# Backup your data first!
helm uninstall filesender
```

### Step 5: Install New Chart

```bash
# Add/update repo
helm repo add mecmus https://mecmus.github.io/helm-charts/
helm repo update

# Install new version
helm install filesender mecmus/filesender -f values.yaml
```

### Step 6: Restore Data (if needed)

```bash
# Restore database
kubectl exec -it <new-filesender-pod> -- psql < filesender-backup.sql

# Restore files (if needed)
kubectl cp ./filesender-files-backup <new-filesender-pod>:/opt/filesender/filesender/files
```

## Key Differences

### Paths

| Component | Old Path | New Path |
|-----------|----------|----------|
| Application | `/var/www/html` | `/opt/filesender/filesender` |
| Files | `/var/www/html/files` | `/opt/filesender/filesender/files` |
| Config | `/var/www/html/config` | `/opt/filesender/filesender/config` |
| Logs | `/var/www/html/log` | `/opt/filesender/filesender/log` |
| SimpleSAML | `/var/www/simplesaml` | ❌ Removed |

### Health Checks

**Old:**
```yaml
livenessProbe:
  tcpSocket:
    port: 9000
```

**New:**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 80
```

### CronJob

**Old:**
```yaml
cronjob:
  enabled: true
  schedule: "0 1 * * *"
```

**New:**
```yaml
cleanup:
  enabled: true
  schedule: "0 2 * * *"
```

## Troubleshooting

### Issue: Cannot authenticate

**Solution for OIDC:**
1. Verify Azure AD configuration
2. Check that Redirect URI matches exactly: `https://your-domain/oidc.php`
3. Verify client ID and secret are correct
4. Check logs: `kubectl logs -f <filesender-pod>`

**Solution for Fake:**
Ensure `filesender.auth.type` is set to `"fake"` and `filesender.auth.fake.enabled` is `true`

### Issue: Database connection failed

**Solution:**
1. Check PostgreSQL is running: `kubectl get pods`
2. Verify credentials in secret: `kubectl get secret <release>-postgresql -o yaml`
3. Check logs: `kubectl logs -f <postgresql-pod>`

### Issue: Files not persisting

**Solution:**
1. Verify PVC is created: `kubectl get pvc`
2. Check PVC is bound: `kubectl describe pvc <pvc-name>`
3. Ensure `persistence.enabled: true` in values.yaml

## Support

For issues or questions:
- GitHub Issues: https://github.com/mecmus/helm-charts/issues
- Chart Repository: https://github.com/mecmus/helm-charts

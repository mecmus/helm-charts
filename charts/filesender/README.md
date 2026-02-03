# FileSender Helm Chart

Ce chart Helm déploie FileSender v3.3 avec une image **légère sans SimpleSAMLphp**.

## Caractéristiques

* **Sécurité maximale** : Image basée sur Alpine Linux avec nginx + PHP-FPM
* **Architecture standalone** : Le conteneur inclut nginx et expose le port **80** (HTTP)
* **Automatisations** : Mis à jour automatiquement par Renovate
* **Persistence** : Support des PVC pour le stockage des fichiers, des logs et des fichiers temporaires
* **Maintenance** : CronJobs intégrés pour le nettoyage automatique des fichiers expirés
* **Authentication** : Support de deux modes d'authentification :
  - **Fake** : Pour dev/test (zéro dépendance externe)
  - **OIDC** : Pour production avec Microsoft Entra ID (Azure AD)

## Installation

```bash
helm repo add mecmus https://mecmus.github.io/helm-charts/
helm install filesender mecmus/filesender
```

## Authentication

Ce chart supporte deux modes d'authentification **sans SimpleSAMLphp** :

### Mode Fake (dev/test)

Mode de développement avec authentification simulée. Idéal pour les tests locaux.

```yaml
filesender:
  auth:
    type: "fake"
    fake:
      uid: "testuser"
      email: "test@example.com"
      name: "Test User"
```

### Mode OIDC (Microsoft Entra ID)

Pour l'authentification en production avec Microsoft Entra ID (Azure AD).

#### 1. Configuration Azure AD

1. Accédez au **Azure Portal** → **Azure Active Directory** → **App registrations**
2. Cliquez sur **New registration**
3. Configurez l'application :
   - **Name** : FileSender
   - **Supported account types** : Accounts in this organizational directory only
   - **Redirect URI** : Web - `https://your-filesender.com/oidc.php`
4. Une fois créée, notez :
   - **Application (client) ID**
   - **Directory (tenant) ID**
5. Allez dans **Certificates & secrets** → **New client secret**
   - Notez la **Value** du secret (vous ne pourrez plus la voir après)

#### 2. Configuration du Chart

```yaml
filesender:
  siteUrl: "https://your-filesender.com"
  auth:
    type: "oidc"
    oidc:
      issuer: "https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0"
      clientId: "YOUR_CLIENT_ID"
      clientSecret: "YOUR_CLIENT_SECRET"
      # Optionnel : Utiliser un secret existant
      # existingSecret: "my-oidc-secret"
```

#### 3. Configuration avancée

**Restriction par groupes Azure AD** :

```yaml
filesender:
  auth:
    type: "oidc"
    oidc:
      issuer: "https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0"
      clientId: "YOUR_CLIENT_ID"
      clientSecret: "YOUR_CLIENT_SECRET"
      requiredGroups:
        - "filesender-users"
        - "filesender-admins"
      groupsClaim: "groups"
```

**Mapping d'attributs personnalisés** :

```yaml
filesender:
  auth:
    type: "oidc"
    oidc:
      issuer: "https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0"
      clientId: "YOUR_CLIENT_ID"
      clientSecret: "YOUR_CLIENT_SECRET"
      uidAttribute: "oid"        # Azure Object ID
      emailAttribute: "email"
      nameAttribute: "name"
```

## Database Configuration

Le chart supporte deux modes de base de données PostgreSQL :

### PostgreSQL interne (par défaut)

```yaml
postgresql:
  internal:
    enabled: true
    database: "filesender"
    username: "filesender"
    password: ""  # Généré automatiquement si vide
    persistence:
      enabled: true
      size: 10Gi
```

### PostgreSQL externe

```yaml
postgresql:
  external:
    enabled: true
    host: "postgresql.example.com"
    port: 5432
    database: "filesender"
    username: "filesender"
    password: "your-password"
    # Ou utiliser un secret existant
    # existingSecret: "my-postgres-secret"
    # secretKey: "password"
  internal:
    enabled: false
```

## Storage

Configuration du stockage des fichiers uploadés :

```yaml
persistence:
  enabled: true
  size: 100Gi
  storageClass: ""  # Utilise la classe par défaut
  accessMode: ReadWriteOnce
```

## Ingress

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: filesender.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: filesender-tls
      hosts:
        - filesender.example.com
```

## Resources

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Cleanup CronJob

Nettoyage automatique des fichiers expirés :

```yaml
cleanup:
  enabled: true
  schedule: "0 2 * * *"  # Tous les jours à 2h du matin
```

## Ports et Service

Le conteneur écoute sur le port **80** (nginx + PHP-FPM).
Le service Kubernetes expose ce port en interne.

```yaml
service:
  type: ClusterIP
  port: 80
```


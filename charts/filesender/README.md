# FileSender Helm Chart

Chart Helm pour déployer FileSender v3.3 sur Kubernetes avec SimpleSAMLphp et Nginx intégrés.

## Prérequis

- Kubernetes 1.19+
- Helm 3.0+
- PersistentVolume provisioner (si la persistence est activée)
- PostgreSQL (externe ou déployé via ce chart)

## Installation rapide

```bash
# Ajouter le repository Helm
helm repo add mecmus https://mecmus.github.io/helm-charts/
helm repo update

# Installation avec les valeurs par défaut
helm install filesender mecmus/filesender

# Installation avec un fichier de valeurs personnalisé
helm install filesender mecmus/filesender -f my-values.yaml
```

## Configuration

### PostgreSQL

#### Option A - Base de données externe

Pour utiliser une base de données PostgreSQL existante :

```yaml
postgresql:
  external:
    enabled: true
    host: "postgres.example.com"
    port: 5432
    database: "filesender"
    username: "filesender"
    password: "votre-mot-de-passe"
    # OU utiliser un secret existant
    existingSecret: "postgres-credentials"
    secretKey: "password"
  
  internal:
    enabled: false
```

#### Option B - PostgreSQL intégré

Pour déployer PostgreSQL dans le cluster :

```yaml
postgresql:
  external:
    enabled: false
  
  internal:
    enabled: true
    image:
      repository: postgres
      tag: "15-alpine"
    database: "filesender"
    username: "filesender"
    password: ""  # Sera généré automatiquement si vide
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "500m"
    persistence:
      enabled: true
      size: 10Gi
      storageClass: ""
```

### SimpleSAMLphp - Authentification

#### Mode SAML avec IdP externe

```yaml
simplesamlphp:
  authType: "saml"
  authenticationSource: "default-sp"
  uidAttribute: "eduPersonPrincipalName"
  emailAttribute: "mail"
  nameAttribute: "cn"
  
  idp:
    entityId: "https://idp.example.com/saml2"
    ssoUrl: "https://idp.example.com/saml2/login"
    certificate: |
      -----BEGIN CERTIFICATE-----
      MIIDXTCCAkWgAwIBAgIJAKJ...
      -----END CERTIFICATE-----
```

#### Mode test avec utilisateurs locaux

Pour les tests et le développement :

```yaml
simplesamlphp:
  authType: "fake"
  localUsers:
    enabled: true
    users:
      - username: "testuser"
        password: "testpassword"
        email: "test@example.com"
        uid: "testuser"
      - username: "admin"
        password: "adminpass"
        email: "admin@example.com"
        uid: "admin"
```

### Configuration de l'Ingress

#### Ingress standard avec TLS

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

### Stockage des fichiers

```yaml
persistence:
  enabled: true
  size: 100Gi
  storageClass: "fast-ssd"  # Ou "" pour la classe par défaut
  accessMode: ReadWriteOnce
```

### Limites et configuration FileSender

```yaml
filesender:
  siteUrl: "https://filesender.example.com"
  siteName: "FileSender - Mon Organisation"
  admin: "admin@example.com"
  adminEmail: "admin@example.com"
  emailReplyTo: "noreply@example.com"
  defaultTimezone: "Europe/Paris"
  
  storage:
    type: "filesystem"
    path: "/var/www/files"
  
  # Limites de transfert
  maxTransferSize: "107374182400"  # 100GB
  maxTransferFiles: 100
  defaultTransferDaysValid: 20
  maxTransferDaysValid: 60
```

### Ressources

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### CronJob de nettoyage

```yaml
cleanup:
  enabled: true
  schedule: "0 2 * * *"  # Tous les jours à 2h du matin
```

## Exemples de déploiement

### Exemple 1 : Configuration minimale avec PostgreSQL externe

```yaml
# values-minimal.yaml
filesender:
  siteUrl: "https://filesender.example.com"
  siteName: "FileSender"
  admin: "admin@example.com"

postgresql:
  external:
    enabled: true
    host: "my-postgres.example.com"
    existingSecret: "postgres-secret"
  internal:
    enabled: false

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: filesender.example.com
      paths:
        - path: /
          pathType: Prefix
```

Déploiement :
```bash
helm install filesender mecmus/filesender -f values-minimal.yaml
```

### Exemple 2 : Configuration complète avec PostgreSQL interne et SAML

```yaml
# values-production.yaml
replicaCount: 2

filesender:
  siteUrl: "https://filesender.example.com"
  siteName: "FileSender Production"
  admin: "admin@example.com"
  adminEmail: "admin@example.com"
  emailReplyTo: "noreply@example.com"
  defaultTimezone: "Europe/Paris"
  
  maxTransferSize: "214748364800"  # 200GB
  maxTransferFiles: 200
  defaultTransferDaysValid: 30
  maxTransferDaysValid: 90

simplesamlphp:
  authType: "saml"
  authenticationSource: "default-sp"
  uidAttribute: "eduPersonPrincipalName"
  emailAttribute: "mail"
  nameAttribute: "cn"
  
  idp:
    entityId: "https://idp.example.com/saml2"
    ssoUrl: "https://idp.example.com/saml2/login"
    certificate: |
      -----BEGIN CERTIFICATE-----
      [VOTRE CERTIFICAT ICI]
      -----END CERTIFICATE-----

postgresql:
  external:
    enabled: false
  internal:
    enabled: true
    persistence:
      enabled: true
      size: 20Gi
      storageClass: "fast-ssd"
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "1000m"

persistence:
  enabled: true
  size: 500Gi
  storageClass: "fast-ssd"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/proxy-body-size: "32m"
  hosts:
    - host: filesender.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: filesender-tls
      hosts:
        - filesender.example.com

resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "1000m"

cleanup:
  enabled: true
  schedule: "0 3 * * *"
```

Déploiement :
```bash
helm install filesender mecmus/filesender -f values-production.yaml
```

### Exemple 3 : Configuration de test/développement

```yaml
# values-dev.yaml
filesender:
  siteUrl: "http://filesender.local"
  siteName: "FileSender Dev"
  admin: "dev@example.com"

simplesamlphp:
  authType: "fake"
  localUsers:
    enabled: true
    users:
      - username: "testuser"
        password: "test123"
        email: "test@example.com"
        uid: "testuser"

postgresql:
  internal:
    enabled: true
    persistence:
      enabled: false  # Utilise emptyDir pour le dev

persistence:
  enabled: false  # Pas de persistence en dev

ingress:
  enabled: false  # Utiliser port-forward pour le dev
```

Déploiement et accès :
```bash
helm install filesender mecmus/filesender -f values-dev.yaml

# Accéder via port-forward
kubectl port-forward svc/filesender 8080:80
# Puis visitez http://localhost:8080
```

## Mise à niveau

```bash
# Mettre à jour le repository
helm repo update

# Voir les changements avant la mise à niveau
helm diff upgrade filesender mecmus/filesender -f my-values.yaml

# Effectuer la mise à niveau
helm upgrade filesender mecmus/filesender -f my-values.yaml
```

## Dépannage

### Les pods ne démarrent pas

```bash
# Vérifier les logs du pod
kubectl logs -l app.kubernetes.io/name=filesender

# Vérifier les événements
kubectl get events --sort-by=.metadata.creationTimestamp

# Vérifier le statut des pods
kubectl describe pod -l app.kubernetes.io/name=filesender
```

### Problèmes de base de données

```bash
# Tester la connexion à PostgreSQL
kubectl run -it --rm debug --image=postgres:15-alpine --restart=Never -- \
  psql -h filesender-postgresql -U filesender -d filesender

# Vérifier les logs PostgreSQL
kubectl logs -l app.kubernetes.io/component=database
```

### Problèmes d'authentification SAML

```bash
# Accéder à l'interface d'administration SimpleSAMLphp
# https://filesender.example.com/simplesaml/

# Vérifier les logs SimpleSAMLphp dans les logs du pod
kubectl logs -l app.kubernetes.io/name=filesender | grep simplesaml
```

### Vérifier la configuration

```bash
# Voir la configuration générée
kubectl get configmap filesender-filesender -o yaml
kubectl get configmap filesender-simplesamlphp -o yaml

# Voir les secrets (encodés en base64)
kubectl get secret filesender -o yaml
```

### Problèmes de stockage

```bash
# Vérifier le PVC
kubectl get pvc

# Vérifier le PV
kubectl get pv

# Voir les détails du PVC
kubectl describe pvc filesender-data
```

## Désinstallation

```bash
# Supprimer le déploiement
helm uninstall filesender

# Supprimer les PVC (optionnel, ATTENTION : cela supprime les données !)
kubectl delete pvc -l app.kubernetes.io/name=filesender
```

## Support

Pour obtenir de l'aide :
- Documentation FileSender : https://filesender.org/
- Issues GitHub : https://github.com/mecmus/helm-charts/issues
- Documentation SimpleSAMLphp : https://simplesamlphp.org/

## Licence

Ce chart Helm est distribué sous licence MIT. FileSender est distribué sous licence BSD.

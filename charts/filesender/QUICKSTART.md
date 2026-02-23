# Guide de démarrage rapide - FileSender Helm Chart

## Installation en 5 minutes

### 1. PostgreSQL externe (recommandé pour la production)

```bash
# Créer un fichier de configuration
cat > my-values.yaml <<EOF
filesender:
  siteUrl: "https://filesender.votredomaine.com"
  siteName: "FileSender"
  admin: "admin@votredomaine.com"

postgresql:
  external:
    enabled: true
    host: "votre-postgres.example.com"
    database: "filesender"
    username: "filesender"
    existingSecret: "postgres-secret"
  internal:
    enabled: false

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: filesender.votredomaine.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: filesender-tls
      hosts:
        - filesender.votredomaine.com
EOF

# Créer le secret PostgreSQL
kubectl create secret generic postgres-secret \
  --from-literal=password='votre-mot-de-passe-postgres'

# Installer FileSender
helm install filesender mecmus/filesender -f my-values.yaml
```

### 2. Installation complète avec PostgreSQL interne

```bash
# Créer un fichier de configuration
cat > my-values.yaml <<EOF
filesender:
  siteUrl: "https://filesender.votredomaine.com"
  siteName: "FileSender"
  admin: "admin@votredomaine.com"

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
    - host: filesender.votredomaine.com
      paths:
        - path: /
          pathType: Prefix
EOF

# Installer FileSender
helm install filesender mecmus/filesender -f my-values.yaml
```

### 3. Installation de test/développement

```bash
# Créer un fichier de configuration
cat > dev-values.yaml <<EOF
filesender:
  siteUrl: "http://localhost:8080"
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
      enabled: false

persistence:
  enabled: false

ingress:
  enabled: false
EOF

# Installer FileSender
helm install filesender mecmus/filesender -f dev-values.yaml

# Accéder via port-forward
kubectl port-forward svc/filesender 8080:80

# Ouvrir dans le navigateur: http://localhost:8080
# Utilisateur: testuser / Mot de passe: test123
```

## Commandes utiles

### Vérifier le statut

```bash
# Voir les pods
kubectl get pods -l app.kubernetes.io/name=filesender

# Voir les logs
kubectl logs -l app.kubernetes.io/name=filesender -f

# Voir tous les ressources
kubectl get all -l app.kubernetes.io/instance=filesender
```

### Mettre à jour la configuration

```bash
# Modifier les valeurs
nano my-values.yaml

# Appliquer les changements
helm upgrade filesender mecmus/filesender -f my-values.yaml

# Redémarrer les pods
kubectl rollout restart deployment filesender
```

### Dépannage

```bash
# Logs complets
kubectl logs -l app.kubernetes.io/name=filesender --tail=100

# Logs PostgreSQL
kubectl logs -l app.kubernetes.io/component=database

# Décrire le pod
kubectl describe pod -l app.kubernetes.io/name=filesender

# Exécuter une commande dans le pod
kubectl exec -it deployment/filesender -- /bin/sh

# Tester la connexion à PostgreSQL
kubectl run -it --rm psql-test --image=postgres:15-alpine --restart=Never -- \
  psql -h filesender-postgresql -U filesender -d filesender
```

### Sauvegardes

```bash
# Sauvegarder la base de données
kubectl exec deployment/filesender-postgresql -- \
  pg_dump -U filesender filesender > backup-$(date +%Y%m%d).sql

# Sauvegarder les fichiers uploadés
kubectl cp filesender-pod:/var/www/files ./files-backup-$(date +%Y%m%d)
```

### Désinstaller

```bash
# Désinstaller FileSender (garde les PVC)
helm uninstall filesender

# Supprimer aussi les données (ATTENTION: perte de données!)
kubectl delete pvc -l app.kubernetes.io/name=filesender
```

## Configuration SAML minimale

Pour configurer l'authentification SAML avec un IdP externe:

```yaml
simplesamlphp:
  authType: "saml"
  authenticationSource: "default-sp"
  uidAttribute: "eduPersonPrincipalName"
  emailAttribute: "mail"
  nameAttribute: "cn"
  
  idp:
    entityId: "https://votre-idp.com/saml2"
    ssoUrl: "https://votre-idp.com/saml2/login"
    certificate: |
      -----BEGIN CERTIFICATE-----
      [Votre certificat IdP ici]
      -----END CERTIFICATE-----
```

## Support

- Documentation complète: Voir [README.md](README.md)
- Issues GitHub: https://github.com/mecmus/helm-charts/issues
- Documentation FileSender: https://filesender.org/

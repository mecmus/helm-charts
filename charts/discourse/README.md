# Discourse Helm Chart

Ce chart Helm déploie Discourse, un forum moderne et open-source, sur Kubernetes.

## Caractéristiques

*   **Déploiement Kubernetes-natif** : Image Docker personnalisée basée sur `discourse/base` officielle
*   **Dépendances intégrées** : PostgreSQL et Redis via charts Bitnami
*   **Configuration flexible** : Support SMTP, S3, base de données externe, etc.
*   **Sécurité** : Contextes de sécurité non-root, capacités restreintes
*   **Sondes de santé** : Liveness, readiness et startup probes configurés
*   **Stockage persistant** : PVC pour uploads, backups et logs
*   **Ingress & Gateway API** : Support des deux modes d'exposition
*   **Mises à jour automatiques** : Via Renovate et GitHub Actions

## Prérequis

*   Kubernetes 1.19+
*   Helm 3.0+
*   PV provisioner support dans le cluster (si persistence activée)

## Installation

### Installation basique

```bash
helm repo add mecmus https://mecmus.github.io/helm-charts/
helm install discourse mecmus/discourse \
  --set discourse.hostname=forum.example.com \
  --set discourse.developerEmails=admin@example.com
```

### Installation avec SMTP

```bash
helm install discourse mecmus/discourse \
  --set discourse.hostname=forum.example.com \
  --set discourse.developerEmails=admin@example.com \
  --set discourse.smtp.enabled=true \
  --set discourse.smtp.address=smtp.gmail.com \
  --set discourse.smtp.port=587 \
  --set discourse.smtp.username=your-email@gmail.com \
  --set discourse.smtp.password=your-password
```

### Installation avec S3

```bash
helm install discourse mecmus/discourse \
  --set discourse.hostname=forum.example.com \
  --set discourse.developerEmails=admin@example.com \
  --set discourse.s3.enabled=true \
  --set discourse.s3.bucket=my-discourse-uploads \
  --set discourse.s3.region=us-east-1 \
  --set discourse.s3.accessKeyId=AKIAIOSFODNN7EXAMPLE \
  --set discourse.s3.secretAccessKey=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### Installation avec base de données externe

```bash
helm install discourse mecmus/discourse \
  --set discourse.hostname=forum.example.com \
  --set discourse.developerEmails=admin@example.com \
  --set postgresql.enabled=false \
  --set externalPostgresql.host=my-postgres.example.com \
  --set externalPostgresql.password=secure-password
```

## Configuration

### Paramètres obligatoires

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `discourse.hostname` | Nom d'hôte du forum (REQUIS) | `""` |
| `discourse.developerEmails` | Email(s) admin (REQUIS) | `""` |

### Paramètres PostgreSQL

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `postgresql.enabled` | Utiliser PostgreSQL intégré | `true` |
| `postgresql.auth.username` | Nom d'utilisateur PostgreSQL | `discourse` |
| `postgresql.auth.password` | Mot de passe PostgreSQL | `discourse` |
| `postgresql.auth.database` | Nom de la base de données | `discourse` |
| `externalPostgresql.host` | Hôte PostgreSQL externe | `""` |
| `externalPostgresql.port` | Port PostgreSQL externe | `5432` |

### Paramètres Redis

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `redis.enabled` | Utiliser Redis intégré | `true` |
| `externalRedis.host` | Hôte Redis externe | `""` |
| `externalRedis.port` | Port Redis externe | `6379` |

### Paramètres SMTP

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `discourse.smtp.enabled` | Activer SMTP | `false` |
| `discourse.smtp.address` | Adresse serveur SMTP | `""` |
| `discourse.smtp.port` | Port SMTP | `587` |
| `discourse.smtp.username` | Nom d'utilisateur SMTP | `""` |
| `discourse.smtp.password` | Mot de passe SMTP | `""` |

### Paramètres S3

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `discourse.s3.enabled` | Activer uploads S3 | `false` |
| `discourse.s3.bucket` | Nom du bucket S3 | `""` |
| `discourse.s3.region` | Région S3 | `""` |
| `discourse.s3.accessKeyId` | Access Key ID AWS | `""` |
| `discourse.s3.secretAccessKey` | Secret Access Key AWS | `""` |

### Paramètres de stockage

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `persistence.enabled` | Activer persistence | `true` |
| `persistence.size` | Taille du PVC | `20Gi` |
| `persistence.storageClass` | Storage class | `""` |

### Paramètres Ingress

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `ingress.enabled` | Activer Ingress | `false` |
| `ingress.className` | Ingress class | `""` |
| `ingress.annotations` | Annotations Ingress | `{}` |

## Premier démarrage

Le premier démarrage peut prendre 2 à 5 minutes pour :
- Les migrations de base de données
- La compilation des assets (si activée)

Surveillez les logs :
```bash
kubectl logs -f deployment/discourse
```

## Création d'un administrateur

Pour créer un compte administrateur :

```bash
kubectl exec -it deployment/discourse -- bundle exec rake admin:create
```

Suivez les instructions interactives pour créer votre compte admin.

## Mise à jour

```bash
helm repo update
helm upgrade discourse mecmus/discourse
```

## Désinstallation

```bash
helm uninstall discourse
```

**Note** : Les PVCs ne sont pas supprimés automatiquement. Pour les supprimer :

```bash
kubectl delete pvc -l app.kubernetes.io/instance=discourse
```

## Support

- Documentation Discourse : https://meta.discourse.org/
- Repository : https://github.com/mecmus/helm-charts
- Issues : https://github.com/mecmus/helm-charts/issues

## Architecture

Discourse utilise :
- **PostgreSQL 13+** : Base de données principale
- **Redis** : Cache et files d'attente Sidekiq
- **Volume /shared** : Uploads, backups, logs
- **Port 3000** : Application web Rails

## Notes de sécurité

- L'image Docker s'exécute en utilisateur non-root (UID 1000)
- Les capacités sont restreintes
- Les secrets sont stockés dans des Kubernetes Secrets
- HTTPS recommandé pour la production (via Ingress + cert-manager)

## Limitations

- **Scaling horizontal** : Discourse ne scale pas bien horizontalement. Privilégiez le scaling vertical (plus de CPU/RAM).
- **Premier démarrage** : Peut être lent (2-5 minutes) pour la compilation des assets.
- **Plugins** : Non supportés actuellement par ce chart (à venir).

## Exemples de configuration complète

Voir `values.yaml` pour tous les paramètres disponibles.

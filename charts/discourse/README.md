# Discourse Helm Chart

Ce chart Helm déploie Discourse, une plateforme de forum moderne, sur Kubernetes sans dépendances Bitnami.

## Caractéristiques

* **Sans dépendances Bitnami** : Utilise les images officielles PostgreSQL et Redis
* **PostgreSQL intégré** : Image officielle `postgres:16-alpine`
* **Redis intégré** : Image officielle `redis:7-alpine`
* **Stockage persistant** : Support des PVC pour les uploads, backups et logs
* **Gateway API** : Support natif pour HTTPRoute et Ingress
* **Autoscaling** : HorizontalPodAutoscaler optionnel
* **Sécurité** : Security contexts et utilisateurs non-privilégiés

## Installation

```bash
helm repo add mecmus https://mecmus.github.io/helm-charts/
helm install discourse mecmus/discourse \
  --set discourse.hostname=forum.example.com \
  --set discourse.developerEmails=admin@example.com \
  --set discourse.smtp.address=smtp.example.com \
  --set discourse.smtp.username=user@example.com \
  --set discourse.smtp.password=yourpassword
```

## Configuration minimale requise

Les valeurs suivantes sont **OBLIGATOIRES** :

* `discourse.hostname` - Le nom de domaine de votre forum
* `discourse.developerEmails` - L'email de l'administrateur
* `discourse.smtp.address` - Serveur SMTP pour les emails

## Configuration PostgreSQL

Par défaut, PostgreSQL est déployé dans le cluster :

```yaml
postgresql:
  enabled: true
  image:
    repository: postgres
    tag: "16-alpine"
```

Pour utiliser une base de données externe :

```yaml
postgresql:
  enabled: false
externalDatabase:
  host: postgres.example.com
  port: 5432
  username: discourse
  password: yourpassword
  database: discourse
```

## Configuration Redis

Par défaut, Redis est déployé dans le cluster :

```yaml
redis:
  enabled: true
  image:
    repository: redis
    tag: "7-alpine"
```

Pour utiliser un Redis externe :

```yaml
redis:
  enabled: false
externalRedis:
  host: redis.example.com
  port: 6379
```

## Stockage S3

Pour activer le stockage S3 des uploads :

```yaml
discourse:
  s3:
    enabled: true
    bucket: my-discourse-bucket
    region: eu-west-1
    accessKeyId: AKIAIOSFODNN7EXAMPLE
    secretAccessKey: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

## Plugins

Pour installer des plugins Discourse :

```yaml
discourse:
  plugins:
    - https://github.com/discourse/docker_manager.git
    - https://github.com/discourse/discourse-solved.git
```

## Support

Pour plus d'informations, consultez la [documentation officielle de Discourse](https://docs.discourse.org/).

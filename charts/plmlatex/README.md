# PLMLatex Helm Chart

Ce chart Helm permet de déployer [PLMLatex](https://plmlab.math.cnrs.fr/plmlatex/overleaf), une version customisée d'Overleaf Community Edition maintenue par le CNRS.

## Fonctionnalités

- Déploie PLMLatex (Overleaf Community Edition) avec MongoDB 4.4 et Redis 5
- Support de l'authentification OIDC
- Volumes persistants pour les données ShareLaTeX, MongoDB et Redis
- Ingress optionnel avec support TLS
- Configuration flexible des variables d'environnement

## Prérequis

- Cluster Kubernetes version 1.19+
- Helm 3+
- Persistence configurée (StorageClass) si vous souhaitez utiliser les PVCs

## Installation

Pour installer le chart avec le nom de release `my-plmlatex` :

```bash
helm install my-plmlatex ./plmlatex
```

Avec Ingress activé :

```bash
helm install my-plmlatex ./plmlatex \
  --set ingress.enabled=true \
  --set ingress.host=plmlatex.example.com
```

## Configuration

Les paramètres suivants peuvent être configurés via le fichier `values.yaml` ou avec l'option `--set` :

### Paramètres ShareLaTeX

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `sharelatex.image.repository` | Image Docker ShareLaTeX | `registry.plmlab.math.cnrs.fr/plmlatex/overleaf/sharelatex` |
| `sharelatex.image.tag` | Tag de l'image | `latest` |
| `sharelatex.containerPort` | Port du conteneur | `8080` |
| `sharelatex.service.type` | Type de service Kubernetes | `ClusterIP` |
| `sharelatex.service.port` | Port du service | `80` |

### Variables d'environnement OIDC

Les variables suivantes sont disponibles pour configurer l'authentification OIDC :

- `OIDC_SERVER` : URL du serveur OIDC
- `OIDC_CLIENTID` : Client ID OIDC
- `OIDC_SECRET` : Secret OIDC
- `OIDC_CALLBACK_URL` : URL de callback
- `OIDC_LOGOUT_URL` : URL de logout
- `OIDC_TITLE` : Titre du bouton de connexion (défaut: "connexion avec OIDC")
- `OIDC_SCOPE` : Scopes OIDC (défaut: "openid profile")

### Paramètres MongoDB

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `mongo.image.repository` | Image Docker MongoDB | `mongo` |
| `mongo.image.tag` | Version de MongoDB | `4.4` |
| `mongo.service.port` | Port du service MongoDB | `27017` |

### Paramètres Redis

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `redis.image.repository` | Image Docker Redis | `redis` |
| `redis.image.tag` | Version de Redis | `5` |
| `redis.service.port` | Port du service Redis | `6379` |

### Ingress

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `ingress.enabled` | Activer l'Ingress | `false` |
| `ingress.host` | Hostname pour l'Ingress | `plmlatex.example.com` |
| `ingress.annotations` | Annotations pour l'Ingress | `cert-manager.io/cluster-issuer: le-prod` |
| `ingress.tls` | Configuration TLS | Voir `values.yaml` |

### Persistence

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `persistence.sharelatex.enabled` | Activer la persistence pour ShareLaTeX | `true` |
| `persistence.sharelatex.size` | Taille du volume ShareLaTeX | `10Gi` |
| `persistence.mongo.enabled` | Activer la persistence pour MongoDB | `true` |
| `persistence.mongo.size` | Taille du volume MongoDB | `10Gi` |
| `persistence.redis.enabled` | Activer la persistence pour Redis | `true` |
| `persistence.redis.size` | Taille du volume Redis | `1Gi` |

## Exemple de configuration OIDC

### Configuration avec Keycloak

Pour configurer l'authentification OIDC avec Keycloak :

```yaml
sharelatex:
  env:
    OIDC_SERVER: "https://keycloak.example.com/auth/realms/myrealm"
    OIDC_CLIENTID: "plmlatex"
    OIDC_SECRET: "your-secret-here"
    OIDC_CALLBACK_URL: "https://plmlatex.example.com/oauth/callback"
    OIDC_LOGOUT_URL: "https://keycloak.example.com/auth/realms/myrealm/protocol/openid-connect/logout"
```

### Configuration avec Microsoft Entra ID (Azure AD)

Pour configurer l'authentification OIDC avec Microsoft Entra ID :

1. **Enregistrer une application dans Entra ID** :
   - Accédez au portail Azure > Microsoft Entra ID > Inscriptions d'applications
   - Créez une nouvelle inscription d'application
   - Notez l'**ID d'application (client)** et l'**ID de l'annuaire (locataire)**
   - Dans **Certificats et secrets**, créez un nouveau secret client et notez sa valeur

2. **Configurer l'URI de redirection** :
   - Dans les paramètres d'authentification de votre application
   - Ajoutez l'URI : `https://votre-domaine.com/oauth/callback`

3. **Configuration dans le chart Helm** :

```yaml
sharelatex:
  env:
    # URL du serveur OIDC (remplacez {tenant-id} par votre ID de locataire)
    OIDC_SERVER: "https://login.microsoftonline.com/{tenant-id}/v2.0"
    # ID d'application (client) depuis Entra ID
    OIDC_CLIENTID: "votre-application-id"
    # Secret client généré dans Entra ID
    OIDC_SECRET: "votre-secret-client"
    # URL de callback (doit correspondre à l'URI de redirection enregistrée)
    OIDC_CALLBACK_URL: "https://votre-domaine.com/oauth/callback"
    # URL de déconnexion Entra ID
    OIDC_LOGOUT_URL: "https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/logout"
    # Scopes demandés (openid et profile sont recommandés)
    OIDC_SCOPE: "openid profile email"
    # Mappage des claims Entra ID
    OIDC_EMAIL: "email"
    OIDC_FIRSTNAME: "given_name"
    OIDC_LASTNAME: "family_name"
    OIDC_PREFERRED_ID: "preferred_username"
```

**Notes importantes pour Entra ID** :
- L'URL du serveur OIDC peut aussi utiliser le nom de domaine du tenant : `https://login.microsoftonline.com/{nom-domaine}.onmicrosoft.com/v2.0`
- Pour obtenir le Tenant ID : Portail Azure > Microsoft Entra ID > Vue d'ensemble
- Le scope `email` nécessite que l'API Microsoft Graph soit autorisée dans les permissions de l'application
- Assurez-vous que les claims `email`, `given_name`, et `family_name` sont inclus dans le token ID en configurant les revendications optionnelles si nécessaire

## Architecture

Le chart déploie 3 composants :

1. **ShareLaTeX** : L'application web Overleaf (port 8080)
2. **MongoDB 4.4** : Base de données (port 27017)
3. **Redis 5** : Cache et file d'attente (port 6379)

Les URL de connexion à MongoDB et Redis sont générées automatiquement et injectées dans le conteneur ShareLaTeX via les variables d'environnement `SHARELATEX_MONGO_URL` et `SHARELATEX_REDIS_HOST`.

## Notes

- Le déploiement ShareLaTeX utilise une stratégie `Recreate` pour éviter les problèmes de concurrence
- Un `terminationGracePeriodSeconds` de 60 secondes est configuré pour permettre une fermeture propre
- Les healthchecks MongoDB sont configurés pour vérifier la disponibilité de la base de données

## Désinstallation

```bash
helm uninstall my-plmlatex
```

**Note** : Les PersistentVolumeClaims ne sont pas automatiquement supprimés. Pour les supprimer manuellement :

```bash
kubectl delete pvc -l app.kubernetes.io/instance=my-plmlatex
```

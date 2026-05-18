# Overleaf Community Edition — Helm Chart

## Introduction

Ce chart Helm déploie **Overleaf Community Edition** (v6.1.1) sur Kubernetes avec une authentification OIDC via **oauth2-proxy**. Il est compatible avec les fournisseurs d'identité **Microsoft Entra ID (Azure AD)** et **Keycloak** (et tout fournisseur OIDC standard).

Le chart inclut optionnellement MongoDB (image officielle `mongo:8`) et Redis (image officielle `redis:7`) déployés directement, ou peut s'intégrer à des instances externes.

---

## Architecture

```
Utilisateur
    │
    ▼
Ingress (nginx + cert-manager TLS)
    │
    ▼
oauth2-proxy (OIDC)
    │                 ↔  Entra ID / Keycloak
    ▼
Overleaf CE
    │
MongoDB + Redis
```

- **oauth2-proxy** sert de reverse proxy : il gère l'authentification OIDC et transmet les requêtes authentifiées à Overleaf.
- **Overleaf CE** utilise l'image officielle `sharelatex/sharelatex`.
- **MongoDB** et **Redis** peuvent être déployés directement (images officielles) ou configurés comme services externes.

---

## Prérequis

- Kubernetes **1.19+**
- Helm **3.2+**
- [nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [cert-manager](https://cert-manager.io/) (pour TLS Let's Encrypt)
- Un fournisseur OIDC (Entra ID ou Keycloak)

---

## Configuration Entra ID (Azure AD)

### Étapes

1. **Aller dans** Azure Portal → **Microsoft Entra ID** → **App registrations** → **New registration**

2. **Remplir le formulaire** :
   - Nom : `Overleaf`
   - Redirect URI : `https://overleaf.example.com/oauth2/callback`
   - Type de compte : *Single tenant* ou *Multitenant* selon vos besoins

3. **Certificates & Secrets** :
   - Aller dans **Certificates & secrets** → **New client secret**
   - Copier la valeur du secret (elle n'est visible qu'une fois)

4. **API Permissions** :
   - Ajouter : `openid`, `email`, `profile` (Microsoft Graph, Delegated)
   - Cliquer sur **Grant admin consent**

5. **Token configuration** :
   - Ajouter les **optional claims** : `email`, `preferred_username`

6. **Noter les informations** :
   - **Application (client) ID** → `clientId`
   - **Directory (tenant) ID** → dans l'URL du issuer : `https://login.microsoftonline.com/<TENANT_ID>/v2.0`
   - **Client Secret** → `clientSecret`

### Exemple de values pour Entra ID

```yaml
overleaf:
  siteUrl: "https://overleaf.example.com"
  appName: "Overleaf - Mon Organisation"
  adminEmail: "admin@example.com"

oauth2Proxy:
  enabled: true
  provider: "oidc"
  oidcIssuerUrl: "https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0"
  clientId: "YOUR_CLIENT_ID"
  clientSecret: "YOUR_CLIENT_SECRET"
  cookieSecret: "VOTRE_COOKIE_SECRET_BASE64_32_BYTES"
  emailDomains:
    - "example.com"

ingress:
  hosts:
    - host: overleaf.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: overleaf-tls
      hosts:
        - overleaf.example.com
```

---

## Configuration Keycloak

### Étapes

1. **Créer un Realm** : par exemple `overleaf`

2. **Créer un Client** :
   - Client ID : `overleaf`
   - Protocol : `openid-connect`
   - Access Type : `confidential`
   - Valid Redirect URIs : `https://overleaf.example.com/oauth2/callback`

3. **Récupérer le Client Secret** dans l'onglet **Credentials**

4. **Configurer les mappers** pour inclure `email` et `preferred_username` dans les tokens

### Exemple de values pour Keycloak

```yaml
overleaf:
  siteUrl: "https://overleaf.example.com"
  appName: "Overleaf"
  adminEmail: "admin@example.com"

oauth2Proxy:
  enabled: true
  provider: "oidc"
  oidcIssuerUrl: "https://keycloak.example.com/realms/overleaf"
  clientId: "overleaf"
  clientSecret: "YOUR_KEYCLOAK_CLIENT_SECRET"
  cookieSecret: "VOTRE_COOKIE_SECRET_BASE64_32_BYTES"
  emailDomains:
    - "*"
```

---

## Installation

```bash
# Ajouter le repo Helm
helm repo add mecmus https://mecmus.github.io/helm-charts/
helm repo update

# Générer un cookie secret
COOKIE_SECRET=$(python3 -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())')
echo "Cookie secret: $COOKIE_SECRET"

# Installer avec votre fichier de values
helm install overleaf mecmus/overleaf \
  -f my-values.yaml \
  -n overleaf \
  --create-namespace
```

---

## Configuration MongoDB / Redis

### Utiliser les instances intégrées (par défaut)

MongoDB (`mongo:8`) et Redis (`redis:7`) sont déployés directement dans le cluster à partir des images officielles.

```yaml
mongodb:
  enabled: true
  image:
    repository: mongo
    tag: "7"
  persistence:
    size: 8Gi

redis:
  enabled: true
  image:
    repository: redis
    tag: "7"
  persistence:
    size: 2Gi
```

### Utiliser des instances externes

```yaml
mongodb:
  enabled: false
  external:
    url: "mongodb://mongo.database.svc.cluster.local:27017/sharelatex"

redis:
  enabled: false
  external:
    host: "redis.database.svc.cluster.local"
    port: 6379
```

---

## Valeurs

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `replicaCount` | Nombre de réplicas Overleaf | `1` |
| `image.repository` | Image Docker Overleaf | `sharelatex/sharelatex` |
| `image.tag` | Tag de l'image | `6.1.1` |
| `image.pullPolicy` | Politique de téléchargement | `IfNotPresent` |
| `overleaf.siteUrl` | URL publique du site (requis) | `https://overleaf.example.com` |
| `overleaf.appName` | Nom de l'application | `Overleaf` |
| `overleaf.navTitle` | Titre de la barre de navigation | `Overleaf` |
| `overleaf.adminEmail` | Email de l'administrateur | `admin@example.com` |
| `overleaf.allowPublicAccess` | Autoriser l'accès public aux projets | `true` |
| `overleaf.allowAnonymousReadAndWriteSharing` | Partage anonyme | `true` |
| `overleaf.behindProxy` | Indique que l'app est derrière un proxy | `true` |
| `overleaf.secureCookie` | Cookie sécurisé (HTTPS) | `true` |
| `overleaf.extraEnv` | Variables d'environnement supplémentaires | `{}` |
| `smtp.host` | Hôte SMTP | `""` |
| `smtp.port` | Port SMTP | `587` |
| `smtp.secure` | SMTP TLS | `false` |
| `smtp.user` | Utilisateur SMTP | `""` |
| `smtp.password` | Mot de passe SMTP | `""` |
| `smtp.existingSecret` | Secret Kubernetes existant pour SMTP | `""` |
| `smtp.fromAddress` | Adresse d'expéditeur | `""` |
| `oauth2Proxy.enabled` | Activer oauth2-proxy | `true` |
| `oauth2Proxy.image.repository` | Image oauth2-proxy | `quay.io/oauth2-proxy/oauth2-proxy` |
| `oauth2Proxy.image.tag` | Tag oauth2-proxy | `v7.7.1` |
| `oauth2Proxy.provider` | Fournisseur OIDC | `oidc` |
| `oauth2Proxy.oidcIssuerUrl` | URL de l'issuer OIDC | `""` |
| `oauth2Proxy.clientId` | Client ID OIDC | `""` |
| `oauth2Proxy.clientSecret` | Client Secret OIDC | `""` |
| `oauth2Proxy.cookieSecret` | Secret de cookie (32 bytes, base64) | `""` |
| `oauth2Proxy.existingSecret` | Secret Kubernetes existant pour OIDC | `""` |
| `oauth2Proxy.emailDomains` | Domaines email autorisés | `["*"]` |
| `oauth2Proxy.scope` | Scopes OAuth2 | `openid email profile` |
| `oauth2Proxy.cookieName` | Nom du cookie de session | `_oauth2_proxy` |
| `oauth2Proxy.cookieExpire` | Durée de vie du cookie | `168h` |
| `oauth2Proxy.cookieRefresh` | Durée de rafraîchissement du cookie | `60m` |
| `oauth2Proxy.extraArgs` | Arguments supplémentaires oauth2-proxy | `[]` |
| `service.type` | Type de service Kubernetes | `ClusterIP` |
| `service.port` | Port du service | `80` |
| `ingress.enabled` | Activer l'Ingress | `true` |
| `ingress.className` | Classe d'Ingress | `nginx` |
| `ingress.annotations` | Annotations de l'Ingress | voir values.yaml |
| `ingress.hosts` | Hôtes de l'Ingress | `[{host: overleaf.example.com}]` |
| `ingress.tls` | Configuration TLS | voir values.yaml |
| `persistence.data.enabled` | Activer la persistance des données | `true` |
| `persistence.data.size` | Taille du volume | `10Gi` |
| `persistence.data.storageClass` | Classe de stockage | `""` |
| `persistence.data.existingClaim` | PVC existant | `""` |
| `mongodb.enabled` | Déployer MongoDB (image officielle) | `true` |
| `mongodb.image.repository` | Image MongoDB | `mongo` |
| `mongodb.image.tag` | Tag MongoDB | `7` |
| `mongodb.persistence.size` | Taille du volume MongoDB | `8Gi` |
| `mongodb.persistence.existingClaim` | PVC existant pour MongoDB | `""` |
| `mongodb.external.url` | URL MongoDB externe | `""` |
| `redis.enabled` | Déployer Redis (image officielle) | `true` |
| `redis.image.repository` | Image Redis | `redis` |
| `redis.image.tag` | Tag Redis | `7` |
| `redis.persistence.size` | Taille du volume Redis | `2Gi` |
| `redis.persistence.existingClaim` | PVC existant pour Redis | `""` |
| `redis.external.host` | Hôte Redis externe | `""` |
| `redis.external.port` | Port Redis externe | `6379` |
| `resources` | Ressources CPU/mémoire pour Overleaf | voir values.yaml |
| `nodeSelector` | Sélecteur de nœud | `{}` |
| `tolerations` | Tolérances | `[]` |
| `affinity` | Règles d'affinité | `{}` |

---

## Création du compte admin

Après le déploiement, créez le premier compte administrateur :

### Via l'interface web (recommandé)

Visitez `https://overleaf.example.com/launchpad` pour créer le compte admin.

### Via CLI

```bash
kubectl exec -it deploy/overleaf -n overleaf -- bash

# Dans le pod :
cd /overleaf/services/web
node modules/server-ce-scripts/scripts/create-user \
  --admin \
  --email=admin@example.com
```

---

## Dépannage

### L'authentification OIDC échoue

- Vérifiez que le `oidcIssuerUrl` est correct et accessible depuis le cluster.
- Vérifiez que la Redirect URI enregistrée chez votre IdP correspond à : `https://<votre-domaine>/oauth2/callback`.
- Consultez les logs d'oauth2-proxy :
  ```bash
  kubectl logs deploy/overleaf-oauth2-proxy -n overleaf
  ```

### Overleaf ne démarre pas

- Vérifiez la connexion MongoDB et Redis :
  ```bash
  kubectl logs deploy/overleaf -n overleaf
  ```
- Assurez-vous que MongoDB et Redis sont prêts avant Overleaf.

### Erreurs 502 Bad Gateway

- Vérifiez que les services sont correctement créés :
  ```bash
  kubectl get svc -n overleaf
  ```
- Vérifiez les annotations d'ingress pour oauth2-proxy.

### Certificat TLS non émis

- Vérifiez le statut du CertificateRequest :
  ```bash
  kubectl describe certificate overleaf-tls -n overleaf
  ```

---

## Mise à jour

```bash
helm repo update

# Mettre à jour Overleaf
helm upgrade overleaf mecmus/overleaf \
  -f my-values.yaml \
  -n overleaf

# Voir l'historique des révisions
helm history overleaf -n overleaf

# Revenir à la version précédente
helm rollback overleaf -n overleaf
```

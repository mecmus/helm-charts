# Configuration Microsoft Entra ID pour FileSender

Ce document explique comment configurer FileSender avec Microsoft Entra ID (anciennement Azure AD) comme fournisseur d'identité SAML.

## Prérequis

- Un tenant Microsoft Entra ID
- Droits d'administrateur sur Entra ID
- FileSender déployé avec accès HTTPS (obligatoire pour SAML)
- PostgreSQL configuré pour le stockage des sessions

## Configuration dans Microsoft Entra ID

### 1. Créer l'application d'entreprise

1. Connectez-vous au [portail Azure](https://portal.azure.com)
2. Naviguez vers **Microsoft Entra ID** > **Applications d'entreprise**
3. Cliquez sur **Nouvelle application**
4. Sélectionnez **Créez votre propre application**
5. Nommez l'application **FileSender**
6. Choisissez **Intégrer n'importe quelle autre application que vous ne trouvez pas dans la galerie (Non-galerie)**
7. Cliquez sur **Créer**

### 2. Configurer l'authentification unique (SSO) SAML

1. Ouvrez l'application **FileSender** que vous venez de créer
2. Dans le menu de gauche, cliquez sur **Authentification unique**
3. Sélectionnez **SAML** comme méthode

#### Configuration SAML de base

Dans la section **Configuration SAML de base**, configurez:

- **Identificateur (ID d'entité)**: `https://votre-domaine.com`
  - Remplacez `votre-domaine.com` par votre domaine réel
  - Exemple: `https://filesender.example.com`

- **URL de réponse (URL Assertion Consumer Service)**: 
  ```
  https://votre-domaine.com/simplesaml/module.php/saml/sp/saml2-acs.php/default-sp
  ```
  - Remplacez `votre-domaine.com` par votre domaine réel
  - Exemple: `https://filesender.example.com/simplesaml/module.php/saml/sp/saml2-acs.php/default-sp`

### 3. Configurer les attributs et revendications (Claims)

Par défaut, Entra ID envoie les revendications suivantes (à vérifier/modifier):

| Nom de la revendication | Valeur source |
|-------------------------|---------------|
| `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress` | `user.mail` |
| `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name` | `user.displayname` |
| `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier` | `user.userprincipalname` |

**Important**: Assurez-vous que l'attribut `emailaddress` pointe bien vers `user.mail` car FileSender l'utilise pour identifier les utilisateurs.

### 4. Récupérer les informations de configuration

Vous aurez besoin des informations suivantes pour configurer Helm:

#### Tenant ID
- Trouvé dans **Vue d'ensemble** de l'application ou dans **Microsoft Entra ID** > **Vue d'ensemble**
- Format: `12345678-1234-1234-1234-123456789abc`

#### Application (Client) ID
- Trouvé dans **Vue d'ensemble** de l'application
- Format: `abcdef12-3456-7890-abcd-ef1234567890`

#### Certificat de signature SAML
1. Dans la configuration SAML, allez à la section **Certificat de signature SAML**
2. Cliquez sur **Télécharger** pour le **Certificat (Base64)**
3. Ouvrez le fichier téléchargé et copiez le contenu **sans** les lignes:
   - `-----BEGIN CERTIFICATE-----`
   - `-----END CERTIFICATE-----`
4. Mettez tout le contenu sur une seule ligne (retirez les sauts de ligne)

#### URL des métadonnées (Alternative au certificat)
- Trouvée dans la section **Certificat de signature SAML**
- Nommée **URL des métadonnées de fédération d'application**
- Format: `https://login.microsoftonline.com/{tenant-id}/federationmetadata/2007-06/federationmetadata.xml`

### 5. Assigner des utilisateurs

1. Dans l'application FileSender, allez à **Utilisateurs et groupes**
2. Cliquez sur **Ajouter un utilisateur/groupe**
3. Sélectionnez les utilisateurs ou groupes qui auront accès à FileSender
4. Cliquez sur **Assigner**

## Configuration Helm

### Fichier values.yaml

Créez ou modifiez votre fichier `values.yaml`:

```yaml
filesender:
  # URL publique de votre instance FileSender (HTTPS obligatoire)
  siteUrl: "https://filesender.example.com"
  siteName: "FileSender"
  admin: "admin@example.com"  # Email d'un administrateur
  adminEmail: "admin@example.com"
  emailReplyTo: "noreply@example.com"

simplesamlphp:
  # IMPORTANT: Désactiver les utilisateurs locaux
  localUsers:
    enabled: false
  
  # Configuration Microsoft Entra ID
  entraId:
    enabled: true
    tenantId: "12345678-1234-1234-1234-123456789abc"  # Votre Tenant ID
    clientId: "abcdef12-3456-7890-abcd-ef1234567890"  # Votre Client ID
  
  # Certificat de signature SAML (optionnel si vous utilisez metadataUrl)
  idp:
    certificate: "MIIDPjCCAiqgAwIBAgIQ..."  # Contenu du certificat sur une ligne
    # OU utiliser l'URL des métadonnées:
    # metadataUrl: "https://login.microsoftonline.com/YOUR-TENANT-ID/federationmetadata/2007-06/federationmetadata.xml"

# Configuration PostgreSQL (recommandé pour les sessions)
postgresql:
  internal:
    enabled: true
    database: "filesender"
    username: "filesender"

# Configuration Ingress (HTTPS obligatoire)
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
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

### Déploiement

```bash
# Installation
helm install filesender ./charts/filesender -f values.yaml

# Ou mise à jour
helm upgrade filesender ./charts/filesender -f values.yaml
```

## Test de la configuration

### 1. Vérifier les métadonnées SP

Accédez à l'URL des métadonnées de votre Service Provider:
```
https://filesender.example.com/simplesaml/module.php/saml/sp/metadata.php/default-sp
```

Vous devriez voir un fichier XML avec les métadonnées SAML.

### 2. Tester l'authentification

1. Accédez à `https://filesender.example.com`
2. Cliquez sur le bouton de connexion
3. Vous devriez être redirigé vers la page de connexion Microsoft
4. Après authentification réussie, vous devriez être redirigé vers FileSender

### 3. Vérifier l'interface d'administration SimpleSAMLphp

Pour déboguer:
```
https://filesender.example.com/simplesaml/
```

Utilisez le mot de passe admin généré automatiquement (récupérable depuis le secret Kubernetes).

## Dépannage

### Erreur "Invalid audience"

- Vérifiez que l'**Identificateur (ID d'entité)** dans Entra ID correspond exactement à `filesender.siteUrl`
- Il doit être identique dans Entra ID et dans votre configuration Helm

### Erreur "Signature validation failed"

- Vérifiez que le certificat est correctement copié (sans les lignes BEGIN/END)
- Assurez-vous qu'il n'y a pas de sauts de ligne dans le certificat
- Essayez d'utiliser `metadataUrl` à la place

### Utilisateur non reconnu

- Vérifiez que l'attribut `emailaddress` est bien configuré dans les revendications
- Assurez-vous que l'utilisateur a bien l'attribut `mail` rempli dans Entra ID
- Vérifiez les logs de SimpleSAMLphp pour voir quels attributs sont reçus

### Session perdue après redirection

- Vérifiez que PostgreSQL est configuré pour les sessions
- Assurez-vous que `session.cookie.secure` est sur `true`
- Vérifiez que `session.cookie.samesite` est configuré à `None`

## Récupérer les logs

### Logs SimpleSAMLphp

```bash
kubectl logs -f deployment/filesender -c filesender | grep -i saml
```

### Logs PostgreSQL des sessions

```bash
kubectl exec -it deployment/filesender-postgresql -- psql -U filesender -c "SELECT * FROM simplesaml_kvstore LIMIT 10;"
```

## Références

- [Documentation SimpleSAMLphp](https://simplesamlphp.org/docs/stable/)
- [Microsoft Entra ID SAML Documentation](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal-setup-sso)
- [FileSender v3.0 Documentation](https://github.com/filesender/filesender/tree/master3/docs)

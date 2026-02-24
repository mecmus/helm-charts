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

### 6. Configurer l'envoi d'emails via Graph API (optionnel)

> **Note :** La même application Entra ID est utilisée pour le SAML SSO ET l'envoi d'emails. Pas besoin d'en créer une seconde.

#### a) Créer un client secret

1. Allez dans **Azure Portal > Entra ID > App registrations** (pas *Enterprise Applications*)
2. Ouvrez l'application **FileSender**
3. Allez dans **Certificates & secrets > New client secret**
4. Donnez un nom et une durée de validité, puis cliquez sur **Add**
5. **Copiez immédiatement la valeur** du secret (elle n'est visible qu'une seule fois !)

#### b) Ajouter la permission API `Mail.Send`

1. Dans l'App registration **FileSender**, allez dans **API permissions > Add a permission**
2. Choisissez **Microsoft Graph > Application permissions**
3. Recherchez et cochez `Mail.Send`
4. Cliquez sur **Add permissions**
5. Cliquez sur **Grant admin consent for [your tenant]** (consentement administrateur requis)

#### c) Créer une shared mailbox Exchange Online

Les shared mailboxes sont **gratuites** et ne nécessitent pas de licence utilisateur :

```powershell
New-Mailbox -Shared -Name "FileSender" -PrimarySmtpAddress "noreply-filesender@contoso.com"
```

#### d) (Recommandé) Restreindre l'application à la seule shared mailbox

Pour des raisons de sécurité, limitez l'accès de l'application à cette seule boîte :

```powershell
New-ApplicationAccessPolicy `
  -AppId "YOUR-APP-ID" `
  -PolicyScopeGroupId "noreply-filesender@contoso.com" `
  -AccessRight RestrictAccess `
  -Description "Restrict FileSender app to its shared mailbox"
```

#### e) Configurer les values Helm

```yaml
filesender:
  mail:
    enabled: true
    fromAddress: "noreply-filesender@contoso.com"  # Shared mailbox
    clientSecret: "votre-client-secret"             # Valeur copiée à l'étape a)

simplesamlphp:
  saml:
    provider: "entra"
    entra:
      tenantId: "YOUR-TENANT-ID"       # Réutilisé pour SAML et Graph API
      applicationId: "YOUR-APP-ID"     # Réutilisé pour SAML et Graph API
```

#### f) Comportement "envoyé au nom de" (sent on behalf of)

Lorsque Graph API est activé (`filesender.mail.enabled: true`), le chart configure automatiquement FileSender pour utiliser l'email de l'utilisateur connecté comme expéditeur visible. Dans Outlook, les destinataires voient :

> *noreply-filesender@contoso.com au nom de Jean Dupont \<jean.dupont@contoso.com\>*

Fonctionnement :
- **`sender`** = `noreply-filesender@contoso.com` — la shared mailbox qui envoie techniquement via Graph API
- **`from`** = `Jean Dupont <jean.dupont@contoso.com>` — l'utilisateur connecté qui partage le fichier (champ `email_from = 'sender'` dans FileSender)
- **`Reply-To`** = l'utilisateur connecté — les réponses lui parviennent directement

Si l'utilisateur connecté n'a pas d'adresse email dans Entra ID, ou si elle correspond à la shared mailbox, l'email est envoyé uniquement au nom de la shared mailbox (comportement standard).

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
  
  # Email via Graph API (optionnel)
  mail:
    enabled: true
    fromAddress: "noreply-filesender@contoso.com"
    clientSecret: "votre-client-secret"

simplesamlphp:
  # IMPORTANT: Désactiver les utilisateurs locaux
  localUsers:
    enabled: false
  
  saml:
    provider: "entra"
    entra:
      tenantId: "12345678-1234-1234-1234-123456789abc"  # Votre Tenant ID
      applicationId: "abcdef12-3456-7890-abcd-ef1234567890"  # Votre Application ID
      # metadataUrl est auto-construit ; override optionnel uniquement

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

### Emails non envoyés

Vérifiez les logs du pod pour les messages `[sendmail-graph]` :

```bash
kubectl logs -f deployment/filesender -c filesender | grep sendmail-graph
```

Testez l'envoi manuellement depuis le pod :

```bash
kubectl exec -it deployment/filesender -c filesender -- /bin/sh -c '
echo -e "To: test@example.com\nSubject: Test\n\nTest body" | \
  GRAPH_TENANT_ID="$GRAPH_TENANT_ID" \
  GRAPH_CLIENT_ID="$GRAPH_CLIENT_ID" \
  GRAPH_CLIENT_SECRET="$GRAPH_CLIENT_SECRET" \
  GRAPH_FROM_ADDRESS="$GRAPH_FROM_ADDRESS" \
  python3 /usr/local/bin/sendmail-graph.py -t -i
'
```

Vérifications courantes :
- La permission `Mail.Send` (Application) est bien accordée avec consentement admin
- La shared mailbox existe et son adresse correspond à `GRAPH_FROM_ADDRESS`
- Le client secret n'est pas expiré (vérifier dans Entra ID > App registrations > Certificates & secrets)

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

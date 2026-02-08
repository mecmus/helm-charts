# Corrections Applied - FileSender Configuration

## Problème 1 : Configuration des logs pour Loki

### Changement demandé
Passer d'une configuration de logs fichiers à une configuration error_log avec sortie JSON pour intégration avec Loki.

### Solution appliquée
**Fichier modifié:** `charts/filesender/templates/configmap-filesender.yaml`

**Ancienne configuration:**
```php
$config['log_facilities'] = array(
    array(
        'type' => 'file',
        'path' => '/opt/filesender/filesender/log/',
        'rotate' => 'hourly'
    )
);
```

**Nouvelle configuration:**
```php
$config['log_facilities'] = array(
    array(
        'type' => 'error_log',
        'output' => 'json',    // logs structurés pour Loki
        'level' => 'info',
    )
);
```

### Avantages
- Logs structurés en JSON faciles à parser
- Meilleure intégration avec les systèmes de gestion de logs comme Loki, Grafana, etc.
- Niveau de log configuré à `info` pour un bon équilibre entre détails et performances

---

## Problème 2 : Erreur 404 sur SimpleSAMLphp

### Symptôme
Erreurs 404 lors de la connexion SAML:
```
127.0.0.1 -  07/Feb/2026:22:34:19 +0000 "GET /simplesaml/module.php/saml/sp/login/default-sp" 404
```

### Cause racine
Dans la configuration nginx (`docker/filesender/default.conf`), le paramètre `SCRIPT_FILENAME` utilisait la variable `$document_root` qui pointait vers `/opt/filesender/filesender/www` (défini dans le bloc server principal).

Lorsque nginx utilise la directive `alias`, `$document_root` ne change pas automatiquement. Cela causait la construction d'un chemin incorrect:
- Attendu: `/opt/filesender/simplesaml/www/module.php`
- Obtenu: `/opt/filesender/filesender/www/module.php` (fichier inexistant → 404)

### Solution appliquée
**Fichier modifié:** `docker/filesender/default.conf`

**Avant:**
```nginx
location ^~ /simplesaml {
    alias /opt/filesender/simplesaml/www;
    location ~ ^(?<prefix>/simplesaml)(?<phpfile>.+?\.php)(?<pathinfo>/.*)?$ {
        fastcgi_param SCRIPT_FILENAME $document_root$phpfile;
        ...
    }
}
```

**Après:**
```nginx
location ^~ /simplesaml {
    alias /opt/filesender/simplesaml/www;
    location ~ ^(?<prefix>/simplesaml)(?<phpfile>.+?\.php)(?<pathinfo>/.*)?$ {
        fastcgi_param SCRIPT_FILENAME /opt/filesender/simplesaml/www$phpfile;
        ...
    }
}
```

### Résultat
Les URLs SimpleSAMLphp fonctionnent maintenant correctement:
- `/simplesaml/module.php/saml/sp/login/default-sp` → OK (200)
- Toutes les opérations SAML (login, logout, metadata) sont fonctionnelles

---

## Déploiement

Pour appliquer ces changements:

### 1. Reconstruire l'image Docker
```bash
docker build -t ghcr.io/mecmus/filesender:3.3-fixed docker/filesender/
docker push ghcr.io/mecmus/filesender:3.3-fixed
```

### 2. Mettre à jour le déploiement Helm
```bash
helm upgrade filesender ./charts/filesender \
  --set image.tag=3.3-fixed \
  --reuse-values
```

Ou si vous utilisez les valeurs par défaut du chart:
```bash
helm upgrade filesender ./charts/filesender
```

### 3. Vérifier le déploiement
```bash
# Vérifier que les pods redémarrent
kubectl get pods -w

# Vérifier les logs (maintenant en JSON)
kubectl logs -f deployment/filesender

# Tester la connexion SAML
curl -I https://votre-domaine.com/simplesaml/module.php/saml/sp/login/default-sp
# Devrait retourner 302 (redirection) ou 200, pas 404
```

---

## Notes importantes

1. **Logs JSON**: Les logs seront maintenant au format JSON. Si vous utilisez un système de collecte de logs, assurez-vous qu'il est configuré pour parser le JSON.

2. **SimpleSAMLphp**: La correction du chemin nginx nécessite de reconstruire l'image Docker car le fichier `default.conf` est inclus dans l'image.

3. **Compatibilité**: Ces changements sont compatibles avec toutes les configurations existantes (local users, Entra ID, IdP externe).

4. **Session PostgreSQL**: Les sessions continuent d'être stockées dans PostgreSQL comme configuré précédemment, ce qui permet le multi-replica et la persistance.

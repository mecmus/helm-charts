# FileSender Helm Chart (v3)

Ce chart Helm déploie FileSender v3.3 basé sur une image **Docker Hardened (DHI)** hautement sécurisée.

## Caractéristiques

*   **Sécurité maximale** : Image de runtime sans shell, sans gestionnaire de paquets, et tournant avec un utilisateur non-privilégié (UID 1000).
*   **Automatisations** : Mis à jour automatiquement par Renovate pour le socle PHP et les versions applicatives.
*   **Persistence** : Support des PVC pour le stockage des fichiers, des logs et des fichiers temporaires.
*   **Maintenance** : CronJobs intégrés pour le nettoyage automatique des fichiers expirés.
*   **SSO** : Support natif de SimpleSAMLphp pour l'authentification (ex: Azure AD).

## Installation

```bash
helm repo add mecmus https://mecmus.github.io/helm-charts/
helm install filesender mecmus/filesender
```

## Configuration SSO (Azure AD)

Pour activer l'authentification via Azure AD :

1.  Modifiez le `values.yaml` pour configurer les paramètres SimpleSAMLphp.
2.  Injectez vos certificats et metadata via des Secrets ou en modifiant le `configmap` associé.

## Persistence

Par défaut, le chart utilise le stockage dynamique. Assurez-vous d'avoir une `StorageClass` par défaut fonctionnelle.

```yaml
persistence:
  enabled: true
  size: 100Gi
```

## Maintenance

Le script de nettoyage est exécuté toutes les nuits via un CronJob :

```yaml
cronjob:
  schedule: "0 2 * * *"
```

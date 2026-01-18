# FileSender Helm Chart (v3)

Ce chart Helm déploie FileSender v3.3 basé sur une image **Docker Hardened (DHI)** hautement sécurisée.

## Caractéristiques

*   **Sécurité maximale** : Image de runtime sans shell, sans gestionnaire de paquets, et tournant avec un utilisateur non-privilégié (UID 1000).
*   **Architecture FPM-only** : Le conteneur expose uniquement le port **9000** (PHP-FPM). Nécessite un serveur web (Ingress-Nginx, Gateway API, etc.) pour traduire les requêtes HTTP vers FastCGI.
*   **Automatisations** : Mis à jour automatiquement par Renovate.
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

## Ports et Service

Le conteneur écoute sur le port **9000**. 
Le service Kubernetes expose ce port en interne.

```yaml
service:
  port: 9000
```

**Note importante** : Comme il s'agit d'un flux FastCGI et non HTTP direct, votre contrôleur Ingress doit être configuré pour parler le protocole FastCGI (ex: annotations Nginx `nginx.ingress.kubernetes.io/backend-protocol: "FASTCGI"`).

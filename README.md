# Helm Charts

Collection de charts Helm pour Kubernetes, maintenus par [mecmus](https://github.com/mecmus).

## Charts disponibles

<!-- CHART-TABLE-START -->
| Chart | Version | Description |
|-------|---------|-------------|
| [adguard-home](charts/adguard-home/) | 0.1.0 | A Helm chart for deploying AdGuard Home with optional DHCP relay. |
| [filesender](charts/filesender/) | 3.5.2 | FileSender v3.5 - Application web open-source de partage de fichiers volumineux avec SimpleSAMLphp et Nginx intégrés |
| [plmlatex](charts/plmlatex/) | 0.1.0 | A Helm chart for deploying PLMLatex (Overleaf Community Edition) with MongoDB and Redis. |
<!-- CHART-TABLE-END -->

Consultez le README de chaque chart pour la documentation complète et les options de configuration.

## Prérequis

- [Helm](https://helm.sh/) 3.0+
- Un cluster Kubernetes 1.19+

## Utilisation

### Ajouter le repository Helm

```bash
helm repo add mecmus https://mecmus.github.io/helm-charts/
helm repo update
```

### Installer un chart avec les valeurs par défaut

```bash
helm install <release-name> mecmus/<chart-name>
```

Par exemple, pour installer FileSender :

```bash
helm install filesender mecmus/filesender
```

### Installer avec un fichier de valeurs personnalisé

```bash
helm install <release-name> mecmus/<chart-name> -f my-values.yaml
```

### Désinstaller un chart

```bash
helm uninstall <release-name>
```

## Licence

Voir les licences individuelles de chaque chart pour plus de détails.

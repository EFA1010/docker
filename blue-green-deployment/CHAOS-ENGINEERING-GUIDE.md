# Guide Chaos Engineering - Guestbook Blue-Green Deployment

## 🎯 Objectif

Ce guide vous accompagne dans la mise en place d'expériences de chaos engineering pour tester la résilience de votre application guestbook en déploiement blue-green.

## 📋 Prérequis

- ✅ Cluster Kubernetes fonctionnel
- ✅ Application guestbook déployée (blue et green)
- ✅ Prometheus et Grafana configurés
- ✅ Chaos Mesh installé

## 🚀 Installation de Chaos Mesh

### 1. Ajouter le repository Helm
```bash
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update
```

### 2. Créer le namespace
```bash
kubectl create namespace chaos-mesh
```

### 3. Installer Chaos Mesh
```bash
helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-mesh --version 2.6.3
```

### 4. Vérifier l'installation
```bash
kubectl get pods -n chaos-mesh
```

## 🔥 Expériences de Chaos

### Types d'expériences disponibles

1. **Pod Kill** - Tue des pods aléatoirement
2. **Pod Failure** - Simule des pannes de pods
3. **Network Chaos** - Simule des problèmes réseau
4. **Stress Testing** - Stress CPU/Mémoire

### Configuration des expériences

Les expériences sont définies dans [`chaos-pod-kill-experiment.yaml`](./chaos-pod-kill-experiment.yaml) :

- **guestbook-pod-kill** : Tue un pod aléatoire toutes les 2 minutes
- **guestbook-blue-pod-kill** : Cible spécifiquement les pods blue
- **guestbook-green-pod-kill** : Cible spécifiquement les pods green
- **guestbook-chaos-schedule** : Expérience programmée avec 50% de pods affectés

## 🛠️ Utilisation du Script de Chaos

Le script [`chaos-experiments.sh`](./chaos-experiments.sh) fournit une interface complète :

### Commandes disponibles

```bash
# Vérifier que Chaos Mesh est prêt
./chaos-experiments.sh check

# Voir l'état actuel des pods
./chaos-experiments.sh status

# Appliquer les expériences programmées
./chaos-experiments.sh apply

# Lancer une expérience immédiate
./chaos-experiments.sh immediate

# Monitorer la récupération du système
./chaos-experiments.sh monitor

# Lister les expériences actives
./chaos-experiments.sh list

# Nettoyer toutes les expériences
./chaos-experiments.sh cleanup

# Voir les instructions de monitoring
./chaos-experiments.sh metrics

# Test complet automatisé
./chaos-experiments.sh full-test
```

## 📊 Monitoring et Observation

### Dashboards Grafana

1. **Dashboard Business** ([`guestbook-business-dashboard.json`](./guestbook-business-dashboard.json))
   - Vue d'ensemble de la santé applicative
   - Métriques de disponibilité
   - Comparaison Blue vs Green

2. **Dashboard Chaos** ([`chaos-monitoring-dashboard.json`](./chaos-monitoring-dashboard.json))
   - Événements de cycle de vie des pods
   - Analyse du temps de récupération
   - Impact des expériences de chaos
   - Métriques de résilience

### Métriques clés à observer

- **Disponibilité** : Pourcentage de pods prêts
- **Temps de récupération** : Temps pour revenir à l'état normal
- **Redémarrages** : Nombre de redémarrages de pods
- **Utilisation des ressources** : CPU/Mémoire pendant les pannes

### Alertes configurées

Les alertes suivantes se déclencheront pendant les expériences :

- `GuestbookPodNotReady` : Pod non prêt > 1 minute
- `GuestbookHighRestartRate` : > 3 redémarrages par heure
- `GuestbookLowAvailability` : Disponibilité < 80%
- `GuestbookServiceUnavailable` : Service indisponible

## 🧪 Scénarios de Test

### Scénario 1 : Test de Résilience Basique

```bash
# 1. Observer l'état initial
./chaos-experiments.sh status

# 2. Lancer une expérience immédiate
./chaos-experiments.sh immediate

# 3. Observer la récupération
./chaos-experiments.sh monitor
```

### Scénario 2 : Test de Charge avec Chaos

```bash
# 1. Lancer les tests de charge k6
node load-test.js &

# 2. Appliquer les expériences de chaos
./chaos-experiments.sh apply

# 3. Observer l'impact dans Grafana
./chaos-experiments.sh metrics
```

### Scénario 3 : Test de Basculement Blue-Green

```bash
# 1. Cibler spécifiquement la version active
kubectl apply -f - <<EOF
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: active-version-kill
  namespace: default
spec:
  action: pod-kill
  mode: all
  duration: "30s"
  selector:
    namespaces:
      - default
    labelSelectors:
      "app": "guestbook"
      "version": "blue"  # ou "green" selon la version active
EOF

# 2. Observer le basculement automatique
watch kubectl get pods -l app=guestbook
```

## 📈 Analyse des Résultats

### Métriques de Résilience

1. **RTO (Recovery Time Objective)**
   - Temps moyen de récupération après une panne
   - Objectif : < 30 secondes

2. **RPO (Recovery Point Objective)**
   - Perte de données acceptable
   - Objectif : 0 (application stateless)

3. **MTTR (Mean Time To Recovery)**
   - Temps moyen de résolution
   - Calculé sur plusieurs expériences

4. **Availability**
   - Pourcentage de disponibilité
   - Objectif : > 99%

### Questions d'Analyse

- ✅ L'application récupère-t-elle automatiquement ?
- ✅ Les alertes se déclenchent-elles correctement ?
- ✅ Le temps de récupération est-il acceptable ?
- ✅ Y a-t-il une perte de service visible ?
- ✅ Le déploiement blue-green améliore-t-il la résilience ?

## 🔧 Dépannage

### Problèmes courants

1. **Chaos Mesh ne démarre pas**
   ```bash
   # Vérifier les logs
   kubectl logs -n chaos-mesh -l app.kubernetes.io/name=chaos-mesh
   
   # Réinstaller si nécessaire
   helm uninstall chaos-mesh -n chaos-mesh
   helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-mesh
   ```

2. **Expériences ne s'appliquent pas**
   ```bash
   # Vérifier les CRDs
   kubectl get crd | grep chaos-mesh
   
   # Vérifier les permissions
   kubectl auth can-i create podchaos
   ```

3. **Métriques non visibles**
   ```bash
   # Vérifier Prometheus
   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
   
   # Vérifier les targets dans Prometheus UI
   ```

## 🎯 Bonnes Pratiques

### Avant les expériences

- ✅ Informer l'équipe des tests prévus
- ✅ Vérifier que les systèmes de monitoring fonctionnent
- ✅ Avoir un plan de rollback
- ✅ Commencer par des expériences simples

### Pendant les expériences

- ✅ Monitorer en temps réel
- ✅ Documenter les observations
- ✅ Être prêt à arrêter si nécessaire
- ✅ Communiquer avec l'équipe

### Après les expériences

- ✅ Analyser les résultats
- ✅ Identifier les améliorations
- ✅ Mettre à jour la documentation
- ✅ Planifier les prochaines expériences

## 📚 Ressources Supplémentaires

- [Documentation Chaos Mesh](https://chaos-mesh.org/docs/)
- [Principes du Chaos Engineering](https://principlesofchaos.org/)
- [Patterns de Résilience](https://docs.microsoft.com/en-us/azure/architecture/patterns/category/resiliency)

## 🚨 Sécurité et Limitations

- ⚠️ Ne jamais lancer d'expériences en production sans autorisation
- ⚠️ Commencer par des environnements de test
- ⚠️ Limiter la portée des expériences
- ⚠️ Avoir toujours un moyen d'arrêter les expériences

---

**Note** : Ce guide fait partie de l'implémentation complète du monitoring business pour le déploiement blue-green du guestbook.
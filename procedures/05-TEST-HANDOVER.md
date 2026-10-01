# 05 — Test du Handover

## Pré-vérifications

Avant de tester le handover, vérifier :

### 1. Les 2 eNB sont connectés au MME

```bash
docker logs mme 2>&1 | grep "Number of eNBs"
# [Added] Number of eNBs is now 2
```

### 2. Les UE sont attachés

```bash
docker logs mme 2>&1 | grep "Attach complete" | tail -2
# [001010000123451] Attach complete
# [001010000099901] Attach complete
```

### 3. Les UE sont enregistrés IMS

```bash
docker logs scscf 2>&1 | grep -i "registered" | tail -4
# State: [registered]
```

### 4. Identifier sur quelle cellule est chaque UE

```bash
docker logs mme 2>&1 | grep "CellID" | tail -5
# TAC[1] CellID[0x19b01]  <- eNB1
# TAC[1] CellID[0x19c01]  <- eNB2
```

## Procédure de test

### Étape 1 : Démarrer l'écoute des logs

```bash
# Terminal 1 — Logs Handover MME
docker logs -f --since 1s mme 2>&1 | grep -iE "Handover|CellID|StatusTransfer"
```

### Étape 2 : Passer un appel VoLTE

1. Sur le téléphone 1001, appeler **1099**
2. Attendre que l'appel soit établi (audio bidirectionnel)

### Étape 3 : Déclencher le Handover

**Option A : Déplacement physique**
- Éloigner le téléphone de l'eNB source
- Rapprocher le téléphone de l'eNB target

**Option B : Atténuation de signal**
- Utiliser un atténuateur RF
- Réduire le gain TX de l'eNB source

### Étape 4 : Observer les logs

## Séquence de logs attendue (MME)

```
# 1. Handover initié
HandoverRequest
    Source : ENB_UE_S1AP_ID[X] MME_UE_S1AP_ID[Y]
    Target : ENB_UE_S1AP_ID[Unknown] MME_UE_S1AP_ID[Z]

# 2. Transfert d'état
MMEStatusTransfer

# 3. L'UE est maintenant sur la nouvelle cellule
# (Optionnel dans les logs MME)
UE Context Release
```

### Exemple de log réel

```
15:04:10.520: HandoverRequest
15:04:10.520:     Source : ENB_UE_S1AP_ID[119] MME_UE_S1AP_ID[127]
15:04:10.520:     Target : ENB_UE_S1AP_ID[Unknown] MME_UE_S1AP_ID[128]
15:04:10.523: MMEStatusTransfer
```

## Vérification du succès

### 1. L'appel reste connecté

- ✅ L'audio continue sans interruption
- ✅ Pas de tonalité de coupure

### 2. L'UE est sur la nouvelle cellule

```bash
docker logs mme 2>&1 | grep "CellID" | tail -1
# Doit montrer le nouveau CellID
```

### 3. Wireshark (optionnel)

```bash
# Capturer le S1AP
sudo wireshark -i any -k -f 'sctp port 36412'

# Filtres utiles
s1ap.procedureCode == 0   # HandoverRequest
s1ap.procedureCode == 1   # HandoverRequired
```

## Test aller-retour

Pour un test complet, faire le handover dans les deux sens :

```
eNB1 → eNB2 (premier handover)
eNB2 → eNB1 (handover retour)
```

L'appel doit rester connecté pendant les deux handovers.

## Métriques à collecter

| Métrique | Valeur attendue | Comment mesurer |
|----------|-----------------|-----------------|
| Durée du handover | < 100 ms | Timestamp logs |
| Perte de paquets | 0-2 | Wireshark |
| Interruption audio | < 50 ms | Perception |
| Taux de succès | > 95% | Répéter 20x |

## Capture PCAP

Pour analyse ultérieure :

```bash
# Démarrer la capture
sudo tcpdump -i any -w handover_test.pcap \
  'sctp port 36412 or udp port 2152 or port 5060'

# Faire le test

# Arrêter la capture (Ctrl+C)
```

## Script de test automatisé

```bash
#!/bin/bash
# test_handover.sh

echo "=== Démarrage du test Handover ==="
echo "Timestamp: $(date)"

# Écouter les logs pendant 60 secondes
timeout 60 docker logs -f --since 1s mme 2>&1 | \
  grep -iE "Handover|CellID|StatusTransfer" | \
  tee handover_test_$(date +%Y%m%d_%H%M%S).log

echo "=== Test terminé ==="
```

---

➡️ **Étape suivante** : [06-TROUBLESHOOTING.md](06-TROUBLESHOOTING.md)

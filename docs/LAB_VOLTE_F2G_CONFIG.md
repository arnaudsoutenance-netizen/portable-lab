# 📞 LAB VoLTE F2G — Configuration Fonctionnelle

**Date de validation:** 2026-10-01
**Statut:** ✅ FONCTIONNEL — Appels VoLTE établis et stables

---

## 🎯 OBJECTIF ATTEINT

Appels VoLTE entre 2 UE sur un lab LTE avec 2 eNB (Handover S1).

---

## 📁 CHEMINS IMPORTANTS

| Élément | Chemin |
|---------|--------|
| **Docker Compose** | `/home/f2g/Telecom/Core-Network/openimss/` |
| **Repo Git** | `git@github.com:VoicenterTeam/openimss.git` |
| **Config MME** | `/home/f2g/Telecom/Core-Network/openimss/mme/mme.yaml` |
| **Variables .env** | `/home/f2g/Telecom/Core-Network/openimss/.env` |

---

## 🌐 ARCHITECTURE RÉSEAU

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         RÉSEAU PHYSIQUE                                 │
├─────────────────────────────────────────────────────────────────────────┤
│  PC1 (192.168.1.100) ─── eNB1 ───┐                                      │
│                                   ├──► MME (macvlan 192.168.1.102)      │
│  PC2 (192.168.1.101) ─── eNB2 ───┘         │                            │
│                                            │                            │
│                              Docker Network 172.22.0.0/24               │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                      DOCKER CONTAINERS (172.22.0.x)                     │
├─────────────────────────────────────────────────────────────────────────┤
│  Core EPC:                                                              │
│    MME      172.22.0.9   (+ macvlan 192.168.1.102 pour S1AP)           │
│    HSS      172.22.0.3                                                  │
│    SGWC     172.22.0.5                                                  │
│    SGWU     172.22.0.6                                                  │
│    SMF      172.22.0.7                                                  │
│    UPF      172.22.0.8                                                  │
│    PCRF     172.22.0.4                                                  │
│                                                                         │
│  IMS:                                                                   │
│    I-CSCF   172.22.0.19                                                 │
│    S-CSCF   172.22.0.20                                                 │
│    P-CSCF   172.22.0.21                                                 │
│    RTPEngine 172.22.0.16                                                │
│    DNS      172.22.0.15                                                 │
│    MySQL    172.22.0.17                                                 │
│                                                                         │
│  Autres:                                                                │
│    PyHSS, OsmoMSC, OsmoHLR, SMSC, Asterisk, WebUI, Mongo, Redis        │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📱 SUBSCRIBERS CONFIGURÉS

| IMSI | MSISDN | Ki | OPc | IP IMS |
|------|--------|----|----|--------|
| 001010000123451 | 1001 | (dans PyHSS) | (dans PyHSS) | 192.168.101.78 |
| 001010000099901 | 1099 | (dans PyHSS) | (dans PyHSS) | 192.168.101.77 |

**MCC/MNC:** 001/01
**APN IMS:** ims

---

## 🚀 COMMANDES DE DÉMARRAGE

### Démarrer tout le stack

```bash
cd /home/f2g/Telecom/Core-Network/openimss
docker-compose up -d
```

### Vérifier les containers

```bash
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "mme|hss|cscf|pcrf|rtpengine|dns"
```

### Vérifier les connexions eNB

```bash
docker logs mme 2>&1 | grep -i "eNB-S1 accepted\|Number of eNBs"
```

### Vérifier les connexions Diameter

```bash
# MME ↔ HSS
docker logs mme 2>&1 | grep -i "CONNECTED"

# PCRF ↔ P-CSCF
docker logs pcrf 2>&1 | grep -i "CONNECTED"
```

---

## 📞 TEST APPEL VoLTE

### 1. Vérifier enregistrement IMS

```bash
docker logs scscf 2>&1 | grep -i "REGISTER" | tail -10
```

### 2. Écouter les logs pendant l'appel

```bash
# Logs S-CSCF (signalisation SIP)
docker logs -f scscf 2>&1 | grep -iE "INVITE|180|200|ACK|BYE"

# Logs P-CSCF (QoS/Rx)
docker logs -f pcscf 2>&1 | grep -iE "INVITE|AAR|error"

# Logs MME (bearers)
docker logs -f mme 2>&1 | grep -iE "bearer|dedicated|QCI"
```

### 3. Flux d'appel attendu

```
1001 → P-CSCF → I-CSCF → S-CSCF → I-CSCF → P-CSCF → 1099
         │                                      │
         └──────── RTPEngine (media) ───────────┘

INVITE → 100 Trying → 180 Ringing → 200 OK → ACK → [APPEL EN COURS] → BYE
```

---

## ⚠️ PROBLÈME RÉSOLU — NE PAS MODIFIER

### Le fichier mme.yaml

**⛔ NE PAS MODIFIER** `/home/f2g/Telecom/Core-Network/openimss/mme/mme.yaml`

Le format doit rester :
```yaml
mme:
    s1ap:
      dev: MME_IF    # ← Ce format, PAS "server: - address:"
    gtpc:
      dev: MME_IF
```

### Si problème, restaurer depuis git

```bash
cd /home/f2g/Telecom/Core-Network/openimss
git checkout mme/mme.yaml
docker restart mme
```

---

## 🔄 HANDOVER S1 (À TESTER)

Pour tester le handover pendant un appel VoLTE :

1. Établir un appel 1001 → 1099
2. Déplacer physiquement le téléphone appelant vers l'autre eNB
3. L'appel doit rester connecté

### Logs à surveiller pour handover

```bash
docker logs -f mme 2>&1 | grep -iE "handover|source|target|path.switch"
```

---

## 🔧 TROUBLESHOOTING

### L'appel ne passe pas

1. Vérifier que les 2 UE sont enregistrés IMS :
   ```bash
   docker logs scscf 2>&1 | grep -i "200 OK" | grep REGISTER
   ```

2. Vérifier les connexions Diameter :
   ```bash
   docker logs pcrf 2>&1 | grep -i "CONNECTED"
   ```

3. Redémarrer l'IMS proprement :
   ```bash
   docker restart pcrf pcscf scscf icscf
   sleep 5
   # Puis mode avion ON/OFF sur les téléphones
   ```

### L'appel se coupe au décrochage

- Vérifier RTPEngine :
  ```bash
  docker logs rtpengine 2>&1 | tail -20
  ```

- Vérifier que les règles PCC ne sont PAS dans MongoDB (config standard suffit)

### eNB ne se connecte pas

1. Vérifier l'IP macvlan du MME :
   ```bash
   docker exec mme ip addr | grep 192.168.1
   ```

2. Vérifier que le port S1AP écoute :
   ```bash
   docker logs mme 2>&1 | grep "s1ap_server"
   ```

---

## 📊 ÉTAT VALIDÉ LE 2026-10-01

| Composant | Statut |
|-----------|--------|
| eNB1 (PC1 192.168.1.100) | ✅ Connecté |
| eNB2 (PC2 192.168.1.101) | ✅ Connecté |
| MME ↔ HSS (Diameter S6a) | ✅ Connecté |
| PCRF ↔ P-CSCF (Diameter Rx) | ✅ Connecté |
| UE 1001 (IMSI ...123451) | ✅ Enregistré IMS |
| UE 1099 (IMSI ...099901) | ✅ Enregistré IMS |
| Appel VoLTE 1001 → 1099 | ✅ Établi et stable |
| Handover S1 pendant appel | ⏳ À tester |

---

## 📚 RÉFÉRENCES

- **Repo original:** https://github.com/VoicenterTeam/openimss
- **Basé sur:** herlesupreeth/docker_open5gs
- **Specs 3GPP:** TS 23.228 (IMS), TS 29.214 (Rx), TS 23.401 (EPC)

---

*Documentation créée le 2026-10-01 par Kiro pour F2G TelcoLab*

# 🔍 COMPARAISON DÉTAILLÉE — Repos Handover Open5GS + srsRAN

**Analyse effectuée le:** 2026-10-01
**Pour:** Lab F2G avec 2 PC + bladeRF + 1 Core Open5GS

---

## 📊 TABLEAU COMPARATIF

| Critère | ripclap/srsran-mobility | szklisahub/s1handover |
|---------|-------------------------|----------------------|
| **Date création** | 2026-09-27 (très récent) | 2024-05-13 |
| **Dernière MAJ** | 2026-09-27 | 2024-05-13 |
| **Stars** | 0 | 0 |
| **Issues** | 0 | 0 |
| **Documentation** | ⭐⭐⭐ Excellente | ⭐⭐ Basique |
| **Tests validés** | ✅ Oui (evidence/) | ✅ Oui (log/) |
| **Type HO** | X2 + S1 | S1 uniquement |
| **RF** | ZMQ simulation | ZMQ simulation |
| **Déploiement** | Containerlab/Docker | Manuel |
| **Complexité** | 🔴 Élevée | 🟢 Simple |

---

## 🎯 POUR TON SETUP F2G (2 PC + bladeRF + 1 Core)

### ⭐⭐⭐ RECOMMANDATION : szklisahub/s1handover-srsran-open5gs

**Pourquoi ce repo est adapté à ton cas :**

| Ton besoin | szklisahub | ripclap |
|------------|------------|---------|
| 2 PC physiques séparés | ✅ Configs séparées (enb1.sh, enb2.sh) | ❌ Tout en containers |
| bladeRF (hardware réel) | ✅ Facile à adapter (changer ZMQ→bladeRF) | ❌ Simulation I/Q complexe |
| 1 seul Core Open5GS | ✅ Architecture identique | ✅ Aussi 1 core |
| S1 Handover | ✅ Natif et testé | ✅ Supporté |
| Simplicité | ✅ Scripts simples | ❌ Containerlab + patches |

---

## 📋 ANALYSE DÉTAILLÉE

### 1️⃣ ripclap/srsran-mobility

#### Points forts
- ✅ **X2 Handover natif** (patch inclus pour srsRAN)
- ✅ **Tests automatisés** avec résultats documentés
- ✅ **Simulation de channel I/Q** réaliste (positions, puissance, fading)
- ✅ **Résultats prouvés** : 607/608 pings (99.8% succès) pendant X2 HO
- ✅ **Documentation complète** (testing.md, scenario.json)

#### Points faibles pour ton cas
- ❌ **Orienté simulation** — tout en containers Docker
- ❌ **Pas adapté au hardware réel** (bladeRF)
- ❌ **Complexité élevée** — Containerlab, patches, builds custom
- ❌ **Architecture monolithique** — tout sur 1 machine
- ❌ **Très récent** — pas de feedback communauté

#### Architecture
```
┌─────────────────────────────────────────────────────┐
│                  MACHINE UNIQUE                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │  eNB1    │  │  eNB2    │  │  srsUE   │          │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘          │
│       │             │             │                 │
│       └──────┬──────┴─────────────┘                 │
│              │                                      │
│       ┌──────┴──────┐                              │
│       │  I/Q Channel │  ← Simulation software      │
│       │  (ZMQ mixer) │                              │
│       └─────────────┘                              │
│              │                                      │
│       ┌──────┴──────┐                              │
│       │  Open5GS    │                              │
│       └─────────────┘                              │
└─────────────────────────────────────────────────────┘
```

#### Pour adapter à ton setup
Il faudrait :
1. Extraire les configs des containers
2. Supprimer le channel I/Q (tu as du vrai RF)
3. Adapter pour 2 machines physiques
4. Remplacer ZMQ par bladeRF

**Effort estimé : 🔴 IMPORTANT**

---

### 2️⃣ szklisahub/s1handover-srsran-open5gs

#### Points forts
- ✅ **Architecture distribuée** (2 eNB séparés)
- ✅ **Scripts de démarrage simples** (enb1.sh, enb2.sh)
- ✅ **S1 Handover validé** — logs MME montrent le HO réussi
- ✅ **Configs complètes** (rr1.conf, rr2.conf avec meas_cell_list)
- ✅ **Facile à adapter** pour bladeRF

#### Points faibles
- ❌ Pas de X2 Handover
- ❌ Documentation minimale
- ❌ Pas de tests automatisés

#### Architecture (CORRESPOND À TON SETUP)
```
┌─────────────────┐         ┌─────────────────┐
│      PC1        │         │      PC2        │
│  ┌───────────┐  │         │  ┌───────────┐  │
│  │  srsENB   │  │         │  │  srsENB   │  │
│  │  (eNB1)   │  │         │  │  (eNB2)   │  │
│  │           │  │         │  │           │  │
│  │ rr1.conf  │  │         │  │ rr2.conf  │  │
│  └─────┬─────┘  │         │  └─────┬─────┘  │
│        │        │         │        │        │
│  ┌─────┴─────┐  │         │  ┌─────┴─────┐  │
│  │  bladeRF  │  │         │  │  bladeRF  │  │
│  └───────────┘  │         │  └───────────┘  │
└────────┬────────┘         └────────┬────────┘
         │      S1AP / GTP-U         │
         └───────────┬───────────────┘
              ┌──────┴──────┐
              │   Open5GS   │  ← Ton core actuel
              │  (MME/HSS)  │
              │  + IMS      │
              └─────────────┘
```

#### Pour adapter à ton setup
```bash
# Dans enb1.sh, remplacer:
# ZMQ_ARGS="--rf.device_name=zmq ..."
# Par:
BLADERF_ARGS="--rf.device_name=bladeRF"

sudo ./srsenb ./enb.conf \
  --rf.device_name=bladeRF \
  --rf.tx_gain=60 \
  --rf.rx_gain=40 \
  --enb_files.rr_config=rr1.conf
```

**Effort estimé : 🟢 MINIMAL**

---

## 📋 LOGS DE HANDOVER RÉEL (szklisahub)

### Log MME — S1 Handover réussi
```
19:30:07.899: HandoverRequest
19:30:07.899:     Source : ENB_UE_S1AP_ID[1] MME_UE_S1AP_ID[1]
19:30:07.899:     Target : ENB_UE_S1AP_ID[Unknown] MME_UE_S1AP_ID[2]
19:30:07.918: MMEStatusTransfer
19:30:08.525: UE Context Release [Action:4]
```

### Log eNB — Target cell
```
Rx S1AP SDU - HandoverRequest
Tx S1AP PDU, rnti=0x46 - HandoverCommand (49 B)
Tx S1AP SDU, HandoverRequestAcknowledge, rnti=0x46
FSM "rrc_mobility" - idle_st -> s1_target_ho_st (cause: ho_req_rx_ev)
User rnti=0x46 successfully handovered to cell_id=0x1
Tx S1AP SDU, HandoverNotify, rnti=0x46
```

**Le S1 Handover fonctionne !**

---

## 🔧 CONFIG À UTILISER (szklisahub adapté F2G)

### PC1 — eNB1 (192.168.1.100)

#### enb.conf
```conf
[enb]
enb_id = 0x19B
mcc = 001
mnc = 01
mme_addr = 192.168.1.102    # Ton MME macvlan
gtp_bind_addr = 192.168.1.100
s1c_bind_addr = 192.168.1.100
n_prb = 50

[enb_files]
rr_config = rr1.conf

[rf]
device_name = bladeRF
tx_gain = 60
rx_gain = 40
dl_earfcn = 1575            # Adapter à ta fréquence
```

#### rr1.conf (extrait)
```conf
cell_list =
(
  {
    cell_id = 0x01;
    tac = 0x0001;
    pci = 1;
    dl_earfcn = 1575;
    ho_active = true;
    
    meas_cell_list =
    (
      { eci = 0x19B01; dl_earfcn = 1575; pci = 1; },
      { eci = 0x19C01; dl_earfcn = 1575; pci = 6; }
    );
    
    meas_report_desc =
    (
      {
        eventA = 3;
        a3_offset = 6;
        hysteresis = 0;
        time_to_trigger = 480;
        trigger_quant = "RSRP";
      }
    );
  }
);
```

### PC2 — eNB2 (192.168.1.101)

#### Commande de démarrage
```bash
sudo ./srsenb ./enb.conf \
  --rf.device_name=bladeRF \
  --enb_files.rr_config=rr2.conf \
  --enb.enb_id=0x19C \
  --enb.gtp_bind_addr=192.168.1.101 \
  --enb.s1c_bind_addr=192.168.1.101
```

---

## ✅ CONCLUSION

### Pour ton lab F2G : **szklisahub/s1handover-srsran-open5gs**

| Raison | Détail |
|--------|--------|
| **Architecture identique** | 2 eNB distribués + 1 core central |
| **Hardware réel** | Facile à passer de ZMQ à bladeRF |
| **S1 Handover validé** | Logs prouvent que ça marche |
| **Simplicité** | Configs prêtes, juste adapter les IPs |

### ripclap/srsran-mobility : À garder pour plus tard

- Utile si tu veux expérimenter X2 Handover
- Utile pour comprendre la simulation de channel
- Nécessite plus de travail d'adaptation

---

## 📥 PROCHAINES ÉTAPES

1. **Cloner le repo**
   ```bash
   git clone https://github.com/szklisahub/s1handover-srsran-open5gs.git
   ```

2. **Adapter les configs** pour ton setup (IPs, bladeRF)

3. **Configurer tes 2 eNB** avec les rr1.conf/rr2.conf

4. **Tester le S1 Handover** pendant un appel VoLTE

---

*Analyse complète effectuée le 2026-10-01*
*Agent: task-researcher F2G*

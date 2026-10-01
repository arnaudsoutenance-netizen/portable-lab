# 🔄 S1 Handover Configuration — F2G TelcoLab

**Date:** 2026-10-01
**Basé sur:** szklisahub/s1handover-srsran-open5gs

---

## 📁 Fichiers

```
S1_Handover_Config/
├── enb1.conf        # Config principale eNB1 (PC1)
├── enb2.conf        # Config principale eNB2 (PC2)
├── rr1.conf         # Radio Resource eNB1 (avec HO)
├── rr2.conf         # Radio Resource eNB2 (avec HO)
├── start_enb1.sh    # Script démarrage eNB1
├── start_enb2.sh    # Script démarrage eNB2
└── README.md        # Ce fichier
```

---

## 🌐 Architecture

```
┌─────────────────┐                     ┌─────────────────┐
│      PC1        │                     │      PC2        │
│  192.168.1.100  │                     │  192.168.1.101  │
│  ┌───────────┐  │                     │  ┌───────────┐  │
│  │  srsENB   │  │                     │  │  srsENB   │  │
│  │  (eNB1)   │  │                     │  │  (eNB2)   │  │
│  │           │  │                     │  │           │  │
│  │ PCI=1     │  │                     │  │ PCI=2     │  │
│  │ eNB_ID=   │  │                     │  │ eNB_ID=   │  │
│  │ 0x19B     │  │                     │  │ 0x19C     │  │
│  └─────┬─────┘  │                     │  └─────┬─────┘  │
│        │        │                     │        │        │
│  ┌─────┴─────┐  │                     │  ┌─────┴─────┐  │
│  │  bladeRF  │  │        📻 RF        │  │  bladeRF  │  │
│  └───────────┘  │     ~~~~~~~~~~~~    │  └───────────┘  │
└────────┬────────┘                     └────────┬────────┘
         │                                       │
         │            S1AP / GTP-U               │
         └──────────────────┬────────────────────┘
                            │
                     ┌──────┴──────┐
                     │   Open5GS   │
                     │    MME      │
                     │192.168.1.102│
                     │  (macvlan)  │
                     └─────────────┘
```

---

## ⚙️ Paramètres Clés

### Paramètres identiques (requis pour S1 HO)
| Paramètre | eNB1 | eNB2 | Raison |
|-----------|------|------|--------|
| MCC/MNC | 001/01 | 001/01 | Même PLMN |
| TAC | 0x0001 | 0x0001 | Même Tracking Area |
| EARFCN | 1450 | 1450 | Intra-frequency HO |

### Paramètres différents (requis)
| Paramètre | eNB1 | eNB2 | Raison |
|-----------|------|------|--------|
| eNB ID | 0x19B | 0x19C | Identifiant unique |
| Cell ID | 0x01 | 0x01 | OK si eNB_ID différent |
| PCI | 1 | 2 | Doit être différent |
| Root Seq | 204 | 264 | Évite collision PRACH |
| ECI | 0x19B01 | 0x19C01 | = eNB_ID << 8 + Cell_ID |

---

## 🚀 Installation

### 1. Copier les configs sur chaque PC

**Sur PC1 (192.168.1.100):**
```bash
# Copier depuis ce dossier
scp enb1.conf rr1.conf sib.conf rb.conf start_enb1.sh user@192.168.1.100:~/srsran_ho/
```

**Sur PC2 (192.168.1.101):**
```bash
scp enb2.conf rr2.conf sib.conf rb.conf start_enb2.sh user@192.168.1.101:~/srsran_ho/
```

### 2. Vérifier les fichiers sib.conf et rb.conf

Ces fichiers sont standards srsRAN. Copie-les depuis ta config existante :
```bash
cp /home/f2g/Bureau/srsran_config/sib.conf ./
cp /home/f2g/Bureau/srsran_config/rb.conf ./
```

### 3. Rendre les scripts exécutables
```bash
chmod +x start_enb1.sh start_enb2.sh
```

---

## ▶️ Démarrage

### Étape 1: Démarrer Open5GS (si pas déjà fait)
```bash
cd /home/f2g/Telecom/Core-Network/openimss
docker-compose up -d
```

### Étape 2: Démarrer eNB1 sur PC1
```bash
cd ~/srsran_ho
./start_enb1.sh
```

### Étape 3: Démarrer eNB2 sur PC2
```bash
cd ~/srsran_ho
./start_enb2.sh
```

### Étape 4: Vérifier les connexions au MME
```bash
docker logs mme 2>&1 | grep -i "eNB-S1 accepted\|Number of eNBs"
```

Attendu:
```
eNB-S1 accepted[192.168.1.100] in master_sm module
[Added] Number of eNBs is now 1
eNB-S1 accepted[192.168.1.101] in master_sm module
[Added] Number of eNBs is now 2
```

---

## 📞 Test Handover

### 1. Établir un appel VoLTE
- UE 1001 → UE 1099 (ou inversement)
- Vérifier que l'appel est établi et stable

### 2. Écouter les logs handover
```bash
docker logs -f mme 2>&1 | grep -iE "handover|source|target|path.switch"
```

### 3. Déclencher le handover
- Déplacer physiquement le téléphone appelant vers l'autre eNB
- Ou atténuer le signal de l'eNB actuel

### 4. Logs attendus (succès)
```
HandoverRequired
    Source : ENB_UE_S1AP_ID[1] MME_UE_S1AP_ID[1]
HandoverRequest
    Target : ENB_UE_S1AP_ID[X] MME_UE_S1AP_ID[2]
HandoverRequestAcknowledge
MMEStatusTransfer
HandoverNotify
UE Context Release
```

---

## 📊 Paramètres A3 Event (Trigger Handover)

```conf
meas_report_desc =
(
  {
    eventA = 3;           // A3: Neighbour > Serving + offset
    a3_offset = 6;        // Offset en dB (6dB = signal voisin 4x plus fort)
    hysteresis = 0;       // Pas d'hystérésis (réactif)
    time_to_trigger = 480; // 480ms de stabilité avant trigger
    trigger_quant = "RSRP"; // Basé sur la puissance (pas RSRQ)
  }
);
```

### Ajuster pour ton environnement

| Scénario | a3_offset | time_to_trigger |
|----------|-----------|-----------------|
| Cellules proches, HO rapide | 3 | 320 |
| Cellules éloignées, HO stable | 6 | 640 |
| Anti ping-pong | 9 | 1024 |

---

## 🔧 Troubleshooting

### Le handover ne se déclenche pas
1. Vérifier que `ho_active = true` dans les deux rr.conf
2. Vérifier que `meas_cell_list` contient les deux cellules
3. Vérifier que les PCI sont différents
4. Augmenter `a3_offset` ou diminuer `time_to_trigger`

### L'appel se coupe pendant le handover
1. Vérifier que le TAC est identique sur les deux eNB
2. Vérifier la connectivité GTP-U entre eNB et SGW
3. Augmenter `t304` (timeout handover)

### Ping-pong handover (HO répétés)
1. Augmenter `hysteresis` (ex: 2 ou 3 dB)
2. Augmenter `time_to_trigger` (ex: 640ms ou plus)

---

## 📚 Références

- **3GPP TS 36.331** — RRC Protocol (Handover procedures)
- **3GPP TS 36.413** — S1AP Protocol (S1 Handover)
- **srsRAN Docs** — https://docs.srsran.com/projects/4g/en/latest/app_notes/source/handover/

---

*Configuration créée le 2026-10-01 pour F2G TelcoLab*

# 🔄 HANDOVER Open5GS + srsRAN — Repos & Ressources

**Date de recherche:** 2026-10-01
**Recherche effectuée par:** Agent task-researcher F2G

---

## 📊 RÉSUMÉ

| Repo | Type HO | Stars | Dernière MAJ | Recommandation |
|------|---------|-------|--------------|----------------|
| **ripclap/srsran-mobility** | X2 + S1 | - | 2026-09-27 | ⭐⭐⭐ LE PLUS COMPLET |
| szklisahub/s1handover-srsran-open5gs | S1 | 0 | 2024-05-13 | ⭐⭐ Configs simples |
| ramkumar1887/predictive-lte-handover | S1 (ML) | 0 | 2026-09-25 | ⭐ Recherche/ML |

---

## 1️⃣ ripclap/srsran-mobility ⭐ RECOMMANDÉ

**URL:** https://github.com/ripclap/srsran-mobility

### Description
Lab complet LTE mobility avec:
- **X2 Handover natif** (patch inclus pour srsRAN)
- **S1 Handover** 
- 2 eNB srsRAN 4G
- Open5GS Core
- Containerlab pour orchestration
- ZMQ channel avec simulation de mouvement UE

### Architecture
```
eNB1 <-->|X2AP| eNB2
eNB1 <-->|S1AP / GTP-U| Open5GS
eNB2 <-->|S1AP / GTP-U| Open5GS
eNB1 <-->|I/Q| Channel
eNB2 <-->|I/Q| Channel
Channel <-->|I/Q| srsUE
```

### Installation
```bash
git clone https://github.com/ripclap/srsran-mobility.git
cd srsran-mobility

./scripts/bootstrap.sh
docker build -f Dockerfile.ran -t srsran-mobility-ran:verified .
docker build -f Dockerfile.core -t srsran-mobility-core:verified .
docker pull mongo:7.0
```

### Démarrage
```bash
# Créer le réseau
docker network create --internal --subnet 10.87.0.0/24 --gateway 10.87.0.1 srs-mobility-lab

# Mode X2 Handover
LAB_HANDOVER_MODE=x2 ./scripts/containerlab.sh deploy --skip-labdir-acl -t mobility.clab.yml

# Mode S1 Handover
LAB_HANDOVER_MODE=s1 ./scripts/containerlab.sh deploy --skip-labdir-acl -t mobility.clab.yml
```

### Vérification
```bash
# Test handover avec fault injection
python3 scripts/verify.py --runtime containerlab --mode x2 --fault-test

# Test S1 simple
python3 scripts/verify.py --runtime containerlab --mode s1
```

### Points forts
- ✅ Patch X2 inclus pour srsRAN (interface X2AP native)
- ✅ Containerlab pour déploiement reproductible
- ✅ Simulation de channel I/Q avec positions des cellules
- ✅ Scripts de vérification automatisés
- ✅ Support Docker Compose alternatif

### Fichiers clés
```
patches/srsran-x2.patch    # Patch pour activer X2 dans srsRAN
mobility.clab.yml          # Topologie containerlab
config/scenario.json       # Paramètres simulation (positions, puissance)
scripts/verify.py          # Tests automatisés
```

---

## 2️⃣ szklisahub/s1handover-srsran-open5gs

**URL:** https://github.com/szklisahub/s1handover-srsran-open5gs

### Description
Simulation S1 Handover basique avec:
- srsRAN 4G + ZeroMQ
- Open5GS
- Configs prêtes à l'emploi

### Structure
```
config/
├── gnu-radio/       # Configs GNU Radio (optionnel)
├── open5gs/         # Configs Open5GS
├── srsenb/          # Configs eNB
│   ├── enb.conf     # Config principale
│   ├── rr1.conf     # Radio Resource eNB1
│   ├── rr2.conf     # Radio Resource eNB2
│   ├── sib.conf     # SIB config
│   └── rb.conf      # Radio Bearer
└── srsue/           # Configs UE
log/                 # Logs de simulation
```

### Config Handover clé (rr.conf)
```conf
cell_list =
(
  {
    cell_id = 0x01;
    tac = 0x0007;
    pci = 1;                    # PCI eNB1
    root_seq_idx = 204;
    dl_earfcn = 3350;
    ho_active = true;           # ⚠️ ACTIVER HANDOVER
    
    # Cellules voisines pour mesure
    meas_cell_list =
    (
      { eci = 0x19B01; dl_earfcn = 3350; pci = 1; },   # eNB1
      { eci = 0x19C01; dl_earfcn = 3350; pci = 6; }    # eNB2
    );

    # Trigger A3 Event (neighbour better than serving)
    meas_report_desc =
    (
      {
        eventA = 3;             # A3 Event
        a3_offset = 6;          # Offset en dB
        hysteresis = 0;
        time_to_trigger = 480;  # ms avant trigger
        trigger_quant = "RSRP";
        max_report_cells = 1;
        report_interv = 120;
        report_amount = 1;
      }
    );
  }
);
```

### Paramètres A3 Event expliqués
| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `eventA = 3` | A3 | Neighbour becomes offset better than serving |
| `a3_offset` | 6 dB | Offset avant trigger |
| `hysteresis` | 0 dB | Hystérésis pour éviter ping-pong |
| `time_to_trigger` | 480 ms | Temps avant déclenchement |
| `trigger_quant` | RSRP | Mesure utilisée (RSRP ou RSRQ) |

---

## 3️⃣ ramkumar1887/predictive-lte-handover

**URL:** https://github.com/ramkumar1887/predictive-lte-handover

### Description
Recherche sur le handover prédictif avec ML:
- Logique de décision RRC prédictive
- Évaluation sur srsRAN 4G + Open5GS
- Émulation multi-cellule ZMQ

### Cas d'usage
- Recherche académique
- Optimisation des paramètres A3
- Machine Learning pour prédiction handover

---

## 📚 DOCUMENTATION OFFICIELLE

### srsRAN 4G Handover Guide
**URL:** https://docs.srsran.com/projects/4g/en/latest/app_notes/source/handover/source/index.html

**Sections:**
1. S1 Handover Configuration
2. X2 Handover Configuration  
3. Multi-cell ZMQ Setup
4. Handover Triggers (A3 Event)

### Open5GS Documentation
**URL:** https://open5gs.org/open5gs/docs/

**Sections pertinentes:**
- MME Configuration (S1 Handover)
- S1AP Interface
- GTP-U Tunneling

---

## 🔧 CONFIG S1 HANDOVER POUR TON LAB F2G

### Modifications requises sur tes eNB

#### eNB1 (PC1 - 192.168.1.100) — rr.conf
```conf
cell_list =
(
  {
    cell_id = 0x01;
    tac = 0x0001;           # Même TAC que Open5GS
    pci = 1;
    root_seq_idx = 204;
    dl_earfcn = 1575;       # Adapter à ta fréquence
    ho_active = true;
    
    meas_cell_list =
    (
      { eci = 0x19B01; dl_earfcn = 1575; pci = 1; },
      { eci = 0x19B02; dl_earfcn = 1575; pci = 2; }  # eNB2
    );

    meas_report_desc =
    (
      {
        eventA = 3;
        a3_offset = 6;
        hysteresis = 0;
        time_to_trigger = 480;
        trigger_quant = "RSRP";
        max_report_cells = 1;
        report_interv = 120;
        report_amount = 1;
      }
    );
  }
);
```

#### eNB2 (PC2 - 192.168.1.101) — rr.conf
```conf
cell_list =
(
  {
    cell_id = 0x02;         # Cell ID différent
    tac = 0x0001;           # Même TAC
    pci = 2;                # PCI différent
    root_seq_idx = 264;     # Root seq différent
    dl_earfcn = 1575;
    ho_active = true;
    
    meas_cell_list =
    (
      { eci = 0x19B01; dl_earfcn = 1575; pci = 1; },  # eNB1
      { eci = 0x19B02; dl_earfcn = 1575; pci = 2; }
    );

    meas_report_desc =
    (
      {
        eventA = 3;
        a3_offset = 6;
        hysteresis = 0;
        time_to_trigger = 480;
        trigger_quant = "RSRP";
        max_report_cells = 1;
        report_interv = 120;
        report_amount = 1;
      }
    );
  }
);
```

### Vérification Open5GS MME
Le MME doit supporter S1 Handover — c'est le cas par défaut dans Open5GS/VoicenterTeam.

---

## 📋 CHECKLIST IMPLÉMENTATION

### Prérequis
- [ ] 2 eNB avec PCI différents
- [ ] Même TAC pour les 2 cellules
- [ ] Même EARFCN (même fréquence)
- [ ] `ho_active = true` dans les 2 rr.conf
- [ ] `meas_cell_list` configurée avec les 2 cellules
- [ ] `meas_report_desc` avec A3 Event

### Test
- [ ] Établir appel VoLTE
- [ ] Déplacer physiquement le téléphone
- [ ] Vérifier logs MME: `handover|source|target|path.switch`
- [ ] Vérifier que l'appel reste connecté

### Logs à surveiller
```bash
# MME - S1 Handover
docker logs -f mme 2>&1 | grep -iE "handover|source|target|path.switch|forward"

# eNB (si accès aux logs)
grep -iE "RRC.*handover|meas.*report|A3" /path/to/enb.log
```

---

## 🔗 LIENS UTILES

| Ressource | URL |
|-----------|-----|
| srsRAN 4G Handover Docs | https://docs.srsran.com/projects/4g/en/latest/app_notes/source/handover/source/index.html |
| Open5GS Docs | https://open5gs.org/open5gs/docs/ |
| ripclap/srsran-mobility | https://github.com/ripclap/srsran-mobility |
| szklisahub/s1handover | https://github.com/szklisahub/s1handover-srsran-open5gs |
| 3GPP TS 36.331 (RRC) | https://www.3gpp.org/DynaReport/36331.htm |
| 3GPP TS 36.413 (S1AP) | https://www.3gpp.org/DynaReport/36413.htm |

---

## 📊 COMPARAISON X2 vs S1 HANDOVER

| Aspect | X2 Handover | S1 Handover |
|--------|-------------|-------------|
| Interface | X2 (eNB ↔ eNB direct) | S1 (via MME) |
| Latence | Plus faible | Plus élevée |
| Complexité | Nécessite patch srsRAN | Natif Open5GS |
| Data forwarding | Direct | Via SGW |
| Ton lab actuel | ❌ Non configuré | ✅ Devrait marcher |

**Recommandation pour ton lab:** Commence par **S1 Handover** car il fonctionne nativement avec Open5GS. X2 nécessite de patcher srsRAN.

---

*Document généré le 2026-10-01*
*Recherche par Agent task-researcher F2G*

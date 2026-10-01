# S1 Handover VoLTE — Open5GS + srsRAN + bladeRF

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![3GPP Release](https://img.shields.io/badge/3GPP-Rel--15-blue.svg)](https://www.3gpp.org/)
[![Open5GS](https://img.shields.io/badge/Open5GS-v2.7-green.svg)](https://open5gs.org/)
[![srsRAN](https://img.shields.io/badge/srsRAN-v23.11-orange.svg)](https://www.srsran.com/)

Configuration complète pour le **S1 Handover intra-frequency** sur un lab LTE privé avec appels **VoLTE** fonctionnels.

## 🎯 Objectif

Permettre à un UE de changer de cellule (handover) **pendant un appel VoLTE** sans coupure, sur un réseau LTE privé composé de :
- 2 eNodeB physiques (bladeRF xA4)
- 1 Core Network Open5GS avec IMS (Kamailio)

## 📊 Architecture

```
┌─────────────────────┐         ┌─────────────────────┐
│       PC1           │         │       PC2           │
│   192.168.1.100     │         │   192.168.1.101     │
│  ┌───────────────┐  │         │  ┌───────────────┐  │
│  │    srsENB     │  │         │  │    srsENB     │  │
│  │    (eNB1)     │  │         │  │    (eNB2)     │  │
│  │               │  │         │  │               │  │
│  │  PCI=1        │  │         │  │  PCI=2        │  │
│  │  TAC=0x0001   │  │         │  │  TAC=0x0001   │  │
│  │  CellID=19B01 │  │         │  │  CellID=19C01 │  │
│  │  EARFCN=1450  │  │         │  │  EARFCN=1450  │  │
│  └───────┬───────┘  │         │  └───────┬───────┘  │
│          │          │         │          │          │
│  ┌───────┴───────┐  │         │  ┌───────┴───────┐  │
│  │   bladeRF     │  │   RF    │  │   bladeRF     │  │
│  │     xA4       │◄─┼────────►┼──│     xA4       │  │
│  └───────────────┘  │         │  └───────────────┘  │
└──────────┬──────────┘         └──────────┬──────────┘
           │        S1AP / GTP-U           │
           └──────────────┬────────────────┘
                   ┌──────┴──────┐
                   │   Open5GS   │
                   │ 192.168.1.102│
                   │  MME / HSS  │
                   │  SGW / PGW  │
                   └──────┬──────┘
                          │
                   ┌──────┴──────┐
                   │  IMS Core   │
                   │  (Kamailio) │
                   │  P/I/S-CSCF │
                   │  RTPEngine  │
                   └─────────────┘
```

## 📁 Structure du Repository

```
.
├── README.md                    # Ce fichier
├── configs/                     # Configurations eNodeB
│   ├── enb1/                    # Config PC1 (eNB1)
│   ├── enb2/                    # Config PC2 (eNB2)
│   ├── rr1.conf                 # Radio Resource eNB1
│   ├── rr2.conf                 # Radio Resource eNB2
│   └── README.md                # Guide des configs
├── procedures/                  # Procédures pas à pas
│   ├── 01-PREREQUIS.md
│   ├── 02-INSTALLATION.md
│   ├── 03-CONFIGURATION-ENB.md
│   ├── 04-CONFIGURATION-MME.md
│   ├── 05-TEST-HANDOVER.md
│   └── 06-TROUBLESHOOTING.md
├── docs/                        # Documentation détaillée
│   ├── ARCHITECTURE.md
│   ├── HANDOVER_SEQUENCE.md
│   └── VOLTE_IMS.md
├── scripts/                     # Scripts utilitaires
│   ├── start_enb1.sh
│   ├── start_enb2.sh
│   └── volte-lab.sh
├── logs/                        # Logs de référence
│   └── mme_handover_example.log
├── diagrams/                    # Diagrammes
│   └── s1_handover_flow.md
└── tests/                       # Tests et résultats
    └── results/
```

## 🚀 Quick Start

### 1. Prérequis

- 2 PC Linux (Ubuntu 22.04 recommandé)
- 2 bladeRF xA4 avec antennes
- Open5GS + IMS (Kamailio) déployé
- srsRAN 23.11+ compilé

### 2. Configuration eNB1 (PC1)

```bash
cd configs/enb1
sudo srsenb enb1_handover.conf
```

### 3. Configuration eNB2 (PC2)

```bash
cd configs/enb2
sudo srsenb enb2_handover.conf
```

### 4. Test du Handover

```bash
# Écouter les logs MME
docker logs -f mme 2>&1 | grep -iE "Handover|CellID"

# Passer un appel VoLTE et déplacer le téléphone
```

## 📋 Configuration Clé

### Paramètres critiques pour le S1 Handover

| Paramètre | eNB1 | eNB2 | Importance |
|-----------|------|------|------------|
| `tac` | 0x0001 | **0x0001** | ⚠️ DOIT être identique |
| `pci` | 1 | 2 | DOIT être différent |
| `dl_earfcn` | 1450 | 1450 | DOIT être identique (intra-freq) |
| `ho_active` | true | true | Active le handover |

### Configuration meas_cell_list (rr.conf)

```conf
meas_cell_list =
(
  { eci = 0x19C01; dl_earfcn = 1450; pci = 2; }  # Cellule voisine
);

meas_report_desc =
{
  a3_report_type = "RSRP";
  a3_offset = 6;          # dB de marge
  a3_hysteresis = 0;
  a3_time_to_trigger = 480;  # ms avant déclenchement
};
```

## 📡 Séquence S1 Handover (3GPP TS 23.401)

```
    UE          eNB Source       MME         eNB Target
     │               │            │               │
     │◄─────────────►│            │               │
     │  Measurement  │            │               │
     │    Report     │            │               │
     │               │            │               │
     │               │──────────►│               │
     │               │ Handover  │               │
     │               │ Required  │               │
     │               │            │──────────────►│
     │               │            │   Handover   │
     │               │            │   Request    │
     │               │            │◄──────────────│
     │               │            │   Handover   │
     │               │            │   Request Ack│
     │               │◄───────────│               │
     │               │  Handover │               │
     │               │  Command  │               │
     │◄──────────────│            │               │
     │  RRC Conn.   │            │               │
     │  Reconfiguration          │               │
     │               │            │               │
     │─────────────────────────────────────────►│
     │              Handover to Target           │
     │               │            │               │
     │               │            │◄──────────────│
     │               │            │   Handover   │
     │               │            │    Notify    │
     │               │◄───────────│               │
     │               │ UE Context│               │
     │               │  Release  │               │
```

## 🔍 Logs Attendus (MME)

```
HandoverRequest
    Source : ENB_UE_S1AP_ID[X] MME_UE_S1AP_ID[Y]
    Target : ENB_UE_S1AP_ID[Unknown] MME_UE_S1AP_ID[Z]
MMEStatusTransfer
UE Context Release
```

## 🛠️ Troubleshooting

| Problème | Cause probable | Solution |
|----------|----------------|----------|
| Pas de handover | TAC différent | Mettre le même TAC sur les 2 eNB |
| Handover cancel | Timeout | Augmenter `a3_time_to_trigger` |
| Appel coupé après HO | Bearer IMS perdu | Vérifier la config QoS |
| UE ne voit pas la cellule voisine | PCI conflict | Vérifier PCI différents |

## 📚 Références 3GPP

- **TS 23.401** — GPRS enhancements for E-UTRAN access
- **TS 36.413** — S1 Application Protocol (S1AP)
- **TS 36.331** — RRC Protocol specification
- **TS 23.228** — IP Multimedia Subsystem (IMS)
- **TS 24.229** — SIP procedures for IMS

## 📄 License

MIT License — Voir [LICENSE](LICENSE)

## 👤 Auteur

**Arnaud DJOUM** — F2G Telecom Lab  
[GitHub](https://github.com/arnauddjoum) | Cameroun

---

*Testé le 2026-10-01 avec Open5GS v2.7 + srsRAN 23.11 + bladeRF xA4*

# S1 Handover VoLTE — Open5GS + srsRAN + bladeRF

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![3GPP Release](https://img.shields.io/badge/3GPP-Rel--15-blue.svg)](https://www.3gpp.org/)
[![Open5GS](https://img.shields.io/badge/Open5GS-v2.7-green.svg)](https://open5gs.org/)
[![srsRAN](https://img.shields.io/badge/srsRAN-v23.11-orange.svg)](https://www.srsran.com/)

Complete configuration for **S1 Handover intra-frequency** on a private LTE lab with functional **VoLTE** calls.

## 🎯 Objective

Enable a UE to change cells (handover) **during a VoLTE call** without interruption, on a private LTE network consisting of:
- 2 physical eNodeBs (bladeRF xA4)
- 1 Open5GS Core Network with IMS (Kamailio)

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

## 📁 Repository Structure

```
.
├── README.md                    # This file
├── configs/                     # eNodeB configurations
│   ├── enb1/                    # PC1 config (eNB1)
│   ├── enb2/                    # PC2 config (eNB2)
│   ├── rr1.conf                 # Radio Resource eNB1
│   ├── rr2.conf                 # Radio Resource eNB2
│   └── README.md                # Config guide
├── procedures/                  # Step-by-step procedures
│   ├── 01-PREREQUISITES.md
│   ├── 02-INSTALLATION.md
│   ├── 03-ENB-CONFIGURATION.md
│   ├── 04-MME-CONFIGURATION.md
│   ├── 05-HANDOVER-TESTING.md
│   └── 06-TROUBLESHOOTING.md
├── docs/                        # Detailed documentation
│   ├── ARCHITECTURE.md
│   ├── HANDOVER_SEQUENCE.md
│   └── VOLTE_IMS.md
├── scripts/                     # Utility scripts
│   ├── start_enb1.sh
│   ├── start_enb2.sh
│   └── volte-lab.sh
├── logs/                        # Reference logs
│   └── mme_handover_example.log
├── diagrams/                    # Diagrams
│   └── s1_handover_flow.md
└── tests/                       # Tests and results
    └── results/
```

## 🚀 Quick Start

### 1. Prerequisites

- 2 Linux PCs (Ubuntu 22.04 recommended)
- 2 bladeRF xA4 with antennas
- Open5GS + IMS (Kamailio) deployed
- srsRAN 23.11+ compiled

### 2. Configure eNB1 (PC1)

```bash
cd configs/enb1
sudo srsenb enb1_handover.conf
```

### 3. Configure eNB2 (PC2)

```bash
cd configs/enb2
sudo srsenb enb2_handover.conf
```

### 4. Test the Handover

```bash
# Monitor MME logs
docker logs -f mme 2>&1 | grep -iE "Handover|CellID"

# Make a VoLTE call and move the phone
```

## 📋 Key Configuration

### Critical Parameters for S1 Handover

| Parameter | eNB1 | eNB2 | Importance |
|-----------|------|------|------------|
| `tac` | 0x0001 | **0x0001** | ⚠️ MUST be identical |
| `pci` | 1 | 2 | MUST be different |
| `dl_earfcn` | 1450 | 1450 | MUST be identical (intra-freq) |
| `ho_active` | true | true | Enables handover |

### meas_cell_list Configuration (rr.conf)

```conf
meas_cell_list =
(
  { eci = 0x19C01; dl_earfcn = 1450; pci = 2; }  # Neighbor cell
);

meas_report_desc =
{
  a3_report_type = "RSRP";
  a3_offset = 6;          # dB margin
  a3_hysteresis = 0;
  a3_time_to_trigger = 480;  # ms before triggering
};
```

## 📡 S1 Handover Sequence (3GPP TS 23.401)

```
    UE          Source eNB       MME         Target eNB
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

## 🔍 Expected Logs (MME)

```
HandoverRequest
    Source : ENB_UE_S1AP_ID[X] MME_UE_S1AP_ID[Y]
    Target : ENB_UE_S1AP_ID[Unknown] MME_UE_S1AP_ID[Z]
MMEStatusTransfer
UE Context Release
```

## 🛠️ Troubleshooting

| Issue | Probable Cause | Solution |
|-------|----------------|----------|
| No handover | Different TAC | Set same TAC on both eNBs |
| Handover cancel | Timeout | Increase `a3_time_to_trigger` |
| Call drops after HO | IMS bearer lost | Check QoS config |
| UE doesn't see neighbor | PCI conflict | Verify different PCIs |

## 📚 3GPP References

- **TS 23.401** — GPRS enhancements for E-UTRAN access
- **TS 36.413** — S1 Application Protocol (S1AP)
- **TS 36.331** — RRC Protocol specification
- **TS 23.228** — IP Multimedia Subsystem (IMS)
- **TS 24.229** — SIP procedures for IMS

## 📄 License

MIT License — See [LICENSE](LICENSE)

## 👤 Author

**Arnaud DJOUM** — F2G Telecom Lab  
[GitHub](https://github.com/arnauddjoum) | Cameroon

---

*Tested on 2026-10-01 with Open5GS v2.7 + srsRAN 23.11 + bladeRF xA4*

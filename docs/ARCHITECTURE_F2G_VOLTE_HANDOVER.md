# 🏗️ ARCHITECTURE F2G VoLTE LAB — S1 Handover

**Date:** 2026-10-01
**Statut:** ✅ FONCTIONNEL — VoLTE + S1 Handover

---

## 📊 SCHÉMA D'ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              RÉSEAU PHYSIQUE 192.168.1.0/24                         │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│   ┌─────────────────────┐                      ┌─────────────────────┐              │
│   │        PC1          │                      │        PC2          │              │
│   │   192.168.1.100     │                      │   192.168.1.101     │              │
│   │                     │                      │                     │              │
│   │  ┌───────────────┐  │                      │  ┌───────────────┐  │              │
│   │  │    srsENB     │  │                      │  │    srsENB     │  │              │
│   │  │    (eNB1)     │  │                      │  │    (eNB2)     │  │              │
│   │  │               │  │                      │  │               │  │              │
│   │  │ eNB_ID: 0x19B │  │                      │  │ eNB_ID: 0x19C │  │              │
│   │  │ Cell_ID: 0x01 │  │                      │  │ Cell_ID: 0x01 │  │              │
│   │  │ PCI: 1        │  │                      │  │ PCI: 2        │  │              │
│   │  │ TAC: 0x0001   │  │                      │  │ TAC: 0x0002   │  │              │
│   │  │ EARFCN: 1450  │  │                      │  │ EARFCN: 1450  │  │              │
│   │  │ PRB: 50       │  │                      │  │ PRB: 50       │  │              │
│   │  └───────┬───────┘  │                      │  └───────┬───────┘  │              │
│   │          │          │                      │          │          │              │
│   │  ┌───────┴───────┐  │      📻 RF          │  ┌───────┴───────┐  │              │
│   │  │   bladeRF     │  │   ~~~~~~~~~~~~      │  │   bladeRF     │  │              │
│   │  │   xA4/xA9     │  │                      │  │   xA4/xA9     │  │              │
│   │  └───────────────┘  │                      │  └───────────────┘  │              │
│   │                     │                      │                     │              │
│   │  + Open5GS Core     │                      │                     │              │
│   │  + IMS (Docker)     │                      │                     │              │
│   └──────────┬──────────┘                      └──────────┬──────────┘              │
│              │                                            │                         │
│              │              S1AP / GTP-U                   │                         │
│              │         (vers MME macvlan)                 │                         │
│              └────────────────┬───────────────────────────┘                         │
│                               │                                                     │
│                               ▼                                                     │
│                    ┌──────────────────────┐                                         │
│                    │   MME (macvlan)      │                                         │
│                    │   192.168.1.102      │                                         │
│                    │   (S1AP interface)   │                                         │
│                    └──────────┬───────────┘                                         │
│                               │                                                     │
└───────────────────────────────┼─────────────────────────────────────────────────────┘
                                │
┌───────────────────────────────┼─────────────────────────────────────────────────────┐
│                     RÉSEAU DOCKER 172.22.0.0/24                                     │
├───────────────────────────────┼─────────────────────────────────────────────────────┤
│                               │                                                     │
│   ┌───────────────────────────┴───────────────────────────┐                         │
│   │                                                       │                         │
│   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │                         │
│   │  │     MME     │  │     HSS     │  │    PCRF     │   │                         │
│   │  │ 172.22.0.9  │  │ 172.22.0.3  │  │ 172.22.0.4  │   │                         │
│   │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │                         │
│   │         │                │                │          │                         │
│   │         └────────────────┼────────────────┘          │                         │
│   │                          │ Diameter                  │                         │
│   │                          │                           │                         │
│   │  ┌─────────────┐  ┌──────┴──────┐  ┌─────────────┐   │                         │
│   │  │    SGWC     │  │    PyHSS    │  │     SMF     │   │                         │
│   │  │ 172.22.0.5  │  │ 172.22.0.18 │  │ 172.22.0.7  │   │                         │
│   │  └──────┬──────┘  └─────────────┘  └──────┬──────┘   │                         │
│   │         │                                 │          │                         │
│   │  ┌──────┴──────┐                   ┌──────┴──────┐   │                         │
│   │  │    SGWU     │                   │     UPF     │   │                         │
│   │  │ 172.22.0.6  │                   │ 172.22.0.8  │   │                         │
│   │  └─────────────┘                   └─────────────┘   │                         │
│   │                                                       │                         │
│   │                    OPEN5GS EPC                        │                         │
│   └───────────────────────────────────────────────────────┘                         │
│                                                                                     │
│   ┌───────────────────────────────────────────────────────┐                         │
│   │                                                       │                         │
│   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │                         │
│   │  │   I-CSCF    │  │   S-CSCF    │  │   P-CSCF    │   │                         │
│   │  │ 172.22.0.19 │  │ 172.22.0.20 │  │ 172.22.0.21 │   │                         │
│   │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │                         │
│   │         │                │                │          │                         │
│   │         └────────────────┼────────────────┘          │                         │
│   │                          │                           │                         │
│   │  ┌─────────────┐  ┌──────┴──────┐  ┌─────────────┐   │                         │
│   │  │  RTPEngine  │  │    MySQL    │  │     DNS     │   │                         │
│   │  │ 172.22.0.16 │  │ 172.22.0.17 │  │ 172.22.0.15 │   │                         │
│   │  └─────────────┘  └─────────────┘  └─────────────┘   │                         │
│   │                                                       │                         │
│   │                       IMS CORE                        │                         │
│   └───────────────────────────────────────────────────────┘                         │
│                                                                                     │
│   ┌───────────────────────────────────────────────────────┐                         │
│   │  Autres services:                                     │                         │
│   │  • MongoDB    172.22.0.2   (subscribers DB)          │                         │
│   │  • Redis      172.22.0.100 (cache)                   │                         │
│   │  • WebUI      172.22.0.26  (gestion subscribers)     │                         │
│   │  • OsmoMSC    172.22.0.31  (SMS/CSFB)                │                         │
│   │  • OsmoHLR    172.22.0.32  (2G/3G HLR)               │                         │
│   │  • SMSC       172.22.0.33  (SMS Center)              │                         │
│   │  • Asterisk   172.22.0.23  (PSTN Gateway)            │                         │
│   └───────────────────────────────────────────────────────┘                         │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📡 CONFIGURATION eNB1 (PC1 — 192.168.1.100)

### enb1_handover.conf

```conf
[enb]
enb_id = 0x19B
mcc = 001
mnc = 01
mme_addr = 192.168.1.102
gtp_bind_addr = 192.168.1.100
s1c_bind_addr = 192.168.1.100
s1c_bind_port = 0
n_prb = 50

[rf]
dl_earfcn = 1450
tx_gain = 60
rx_gain = 40
device_name = bladeRF
```

### rr_enb1_ho.conf (Radio Resource)

```conf
cell_list =
(
  {
    cell_id = 0x01;
    tac = 0x0001;
    pci = 1;
    dl_earfcn = 1450;
    ho_active = true;
    
    // Cellule voisine pour handover
    meas_cell_list =
    (
      { eci = 0x19C01; dl_earfcn = 1450; pci = 2; }  // eNB2
    );

    // Trigger A3 Event
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

---

## 📡 CONFIGURATION eNB2 (PC2 — 192.168.1.101)

### enb2_handover.conf

```conf
[enb]
enb_id = 0x19C
mcc = 001
mnc = 01
mme_addr = 192.168.1.102
gtp_bind_addr = 192.168.1.101
s1c_bind_addr = 192.168.1.101
s1c_bind_port = 0
n_prb = 50

[rf]
dl_earfcn = 1450
tx_gain = 60
rx_gain = 40
device_name = bladeRF
```

### rr_enb2_ho.conf (Radio Resource)

```conf
cell_list =
(
  {
    cell_id = 0x01;
    tac = 0x0002;
    pci = 2;
    dl_earfcn = 1450;
    ho_active = true;
    
    // Cellule voisine pour handover
    meas_cell_list =
    (
      { eci = 0x19B01; dl_earfcn = 1450; pci = 1; }  // eNB1
    );

    // Trigger A3 Event
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

---

## 📋 TABLEAU RÉCAPITULATIF DES IPs

### Réseau Physique (192.168.1.0/24)

| Équipement | IP | Rôle |
|------------|-----|------|
| PC1 (eNB1) | 192.168.1.100 | Source eNB + Core |
| PC2 (eNB2) | 192.168.1.101 | Target eNB |
| MME (macvlan) | 192.168.1.102 | S1AP interface |

### Réseau Docker (172.22.0.0/24)

| Container | IP | Port | Rôle |
|-----------|-----|------|------|
| mongo | 172.22.0.2 | 27017 | MongoDB |
| hss | 172.22.0.3 | 3868 | HSS (Diameter) |
| pcrf | 172.22.0.4 | 3868 | PCRF (Diameter Rx) |
| sgwc | 172.22.0.5 | 2123 | SGW-C (GTP-C) |
| sgwu | 172.22.0.6 | 2152 | SGW-U (GTP-U) |
| smf | 172.22.0.7 | 2123 | SMF |
| upf | 172.22.0.8 | 2152 | UPF |
| mme | 172.22.0.9 | 36412 | MME (+ macvlan) |
| dns | 172.22.0.15 | 53 | DNS IMS |
| rtpengine | 172.22.0.16 | 22222 | RTPEngine |
| mysql | 172.22.0.17 | 3306 | MySQL IMS |
| pyhss | 172.22.0.18 | 3868 | PyHSS |
| icscf | 172.22.0.19 | 4060 | I-CSCF |
| scscf | 172.22.0.20 | 6060 | S-CSCF |
| pcscf | 172.22.0.21 | 5060 | P-CSCF |
| asterisk | 172.22.0.23 | 5060 | PSTN Gateway |
| webui | 172.22.0.26 | 9999 | WebUI |

---

## 📱 SUBSCRIBERS

| IMSI | MSISDN | Ki | OPc | APN |
|------|--------|-----|-----|-----|
| 001010000123451 | 1001 | (PyHSS) | (PyHSS) | internet, ims |
| 001010000099901 | 1099 | (PyHSS) | (PyHSS) | internet, ims |

### Réseau UE (IMS)
- **Plage IP:** 192.168.101.0/24
- **APN internet:** Accès data
- **APN ims:** Signalisation VoLTE

---

## 🔄 PARAMÈTRES S1 HANDOVER

### Paramètres identiques (requis)

| Paramètre | eNB1 | eNB2 |
|-----------|------|------|
| MCC | 001 | 001 |
| MNC | 01 | 01 |
| EARFCN | 1450 | 1450 |
| n_prb | 50 | 50 |
| ho_active | true | true |

### Paramètres différents (requis)

| Paramètre | eNB1 | eNB2 |
|-----------|------|------|
| eNB_ID | 0x19B | 0x19C |
| PCI | 1 | 2 |
| TAC | 0x0001 | 0x0002 |
| ECI | 0x19B01 | 0x19C01 |
| S1C bind | 192.168.1.100 | 192.168.1.101 |
| GTP bind | 192.168.1.100 | 192.168.1.101 |

### A3 Event Configuration

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| eventA | 3 | Neighbour > Serving + offset |
| a3_offset | 6 dB | Marge avant trigger |
| hysteresis | 0 dB | Anti ping-pong |
| time_to_trigger | 480 ms | Stabilité avant HO |
| trigger_quant | RSRP | Puissance signal |

---

## 📞 FLUX VoLTE

```
UE (1001) ──► P-CSCF ──► I-CSCF ──► S-CSCF ──► I-CSCF ──► P-CSCF ──► UE (1099)
                │                                              │
                └──────────────── RTPEngine ───────────────────┘
                                  (Media)
```

### Séquence d'appel
```
INVITE → 100 Trying → 180 Ringing → 200 OK → ACK → [APPEL] → BYE → 200 OK
```

---

## 🔄 FLUX S1 HANDOVER

```
┌─────────┐          ┌─────────┐          ┌─────────┐
│  eNB1   │          │   MME   │          │  eNB2   │
│(Source) │          │         │          │(Target) │
└────┬────┘          └────┬────┘          └────┬────┘
     │                    │                    │
     │ HandoverRequired   │                    │
     │───────────────────►│                    │
     │                    │                    │
     │                    │ HandoverRequest    │
     │                    │───────────────────►│
     │                    │                    │
     │                    │ HandoverRequestAck │
     │                    │◄───────────────────│
     │                    │                    │
     │ HandoverCommand    │                    │
     │◄───────────────────│                    │
     │                    │                    │
     │ MMEStatusTransfer  │                    │
     │───────────────────►│                    │
     │                    │ MMEStatusTransfer  │
     │                    │───────────────────►│
     │                    │                    │
     │         [UE bascule vers eNB2]          │
     │                    │                    │
     │                    │ HandoverNotify     │
     │                    │◄───────────────────│
     │                    │                    │
     │ UEContextRelease   │                    │
     │◄───────────────────│                    │
     │                    │                    │
```

---

## 🛠️ COMMANDES UTILES

### Démarrage

```bash
# Core (PC1)
cd /home/f2g/Telecom/Core-Network/openimss
docker-compose up -d

# eNB1 (PC1)
cd /home/f2g/Desktop/F2G_Handover_VoLTE_20261001
sudo ./start_enb1.sh

# eNB2 (PC2)
ssh f2g@192.168.1.101
cd ~/srsran_ho
./start_enb2.sh
```

### Monitoring

```bash
# Voir les eNB connectés
docker logs mme 2>&1 | grep "Number of eNBs"

# Écouter les handovers
docker logs -f mme 2>&1 | grep -iE "Handover|CellID"

# Vérifier les enregistrements IMS
docker logs scscf 2>&1 | grep "REGISTER"
```

---

## 📚 RÉFÉRENCES

- **Repo:** VoicenterTeam/openimss
- **srsRAN:** https://docs.srsran.com
- **3GPP TS 36.413:** S1AP (Handover)
- **3GPP TS 23.228:** IMS Architecture

---

*Architecture documentée le 2026-10-01*
*F2G TelcoLab*

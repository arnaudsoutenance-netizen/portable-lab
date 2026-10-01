# S1 Handover VoLTE Lab — Implementation Guide

**Technical details for building the complete system**

---

## 1. Directory Structure

```
portable-lab/
├── configs/
│   ├── enb1/
│   │   ├── enb1_handover.conf      # Main eNB1 config
│   │   └── rr_enb1_ho.conf         # Radio resource with handover
│   ├── enb2/
│   │   ├── enb2_handover.conf      # Main eNB2 config
│   │   └── rr_enb2_ho.conf         # Radio resource with handover
│   ├── sib.conf                    # System information
│   └── rb.conf                     # Radio bearer
├── procedures/
│   ├── 01-PREREQUISITES.md
│   ├── 02-INSTALLATION.md
│   ├── 03-ENB-CONFIGURATION.md
│   ├── 04-MME-CONFIGURATION.md
│   ├── 05-HANDOVER-TESTING.md
│   └── 06-TROUBLESHOOTING.md
├── docs/
│   ├── SPECIFICATION.md
│   ├── IMPLEMENTATION.md           # This file
│   ├── COMPLETE_SETUP.md
│   └── TASKS.md
├── scripts/
│   ├── start_enb1.sh
│   └── start_enb2.sh
├── images/
│   └── architecture_diagram.png
└── README.md
```

## 2. Core Network Setup

### 2.1 Clone Repository

```bash
cd ~/Telecom/Core-Network
git clone https://github.com/VoicenterTeam/openimss.git
cd openimss
```

### 2.2 Docker Containers

The stack runs 12 containers:

| Container | IP | Port | Protocol |
|-----------|-----|------|----------|
| mme | 172.22.0.9 | 36412 | SCTP |
| hss | 172.22.0.3 | 3868 | Diameter |
| sgwc | 172.22.0.5 | 2123 | GTP-C |
| sgwu | 172.22.0.6 | 2152 | GTP-U |
| smf | 172.22.0.7 | 2123 | GTP-C |
| upf | 172.22.0.8 | 2152 | GTP-U |
| pcrf | 172.22.0.4 | 3868 | Diameter |
| pcscf | 172.22.0.21 | 5060 | SIP |
| icscf | 172.22.0.19 | 5060 | SIP |
| scscf | 172.22.0.20 | 5060 | SIP |
| rtpengine | 172.22.0.16 | 2223 | Control |
| asterisk | 172.22.0.23 | 5060 | SIP |

### 2.3 MME Configuration

Edit `mme/mme.yaml`:

```yaml
mme:
  freeDiameter: /etc/freeDiameter/mme.conf
  s1ap:
    - addr: 192.168.1.102
      port: 36412
  gtpc:
    - addr: 127.0.0.2
  gummei:
    plmn_id:
      mcc: 001
      mnc: 01
    mme_gid: 2
    mme_code: 1
  tai:
    plmn_id:
      mcc: 001
      mnc: 01
    tac: 1
  security:
    integrity_order: [EIA2, EIA1, EIA0]
    ciphering_order: [EEA0, EEA1, EEA2]
  network_name:
    full: F2G Network
```

### 2.4 macvlan Network

Create a macvlan interface to expose MME on the physical network:

```bash
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  macvlan_net

docker network connect macvlan_net mme --ip 192.168.1.102
```

### 2.5 Start Core

```bash
docker-compose up -d
```

Verify:

```bash
docker ps | grep -E "mme|hss|pcscf"
docker logs mme 2>&1 | head -20
```

## 3. eNodeB Configuration

### 3.1 eNB1 Main Config (PC1)

File: `/tmp/enb1_handover.conf`

```ini
[enb]
enb_id = 0x19B
mcc = 001
mnc = 01
mme_addr = 192.168.1.102
gtp_bind_addr = 192.168.1.100
s1c_bind_addr = 192.168.1.100
n_prb = 50

[enb_files]
sib_config = sib.conf
rr_config = rr_enb1_ho.conf
rb_config = rb.conf

[rf]
device_name = bladeRF
device_args = default
tx_gain = 60
rx_gain = 40

[log]
all_level = info
filename = /tmp/enb1.log
```

### 3.2 eNB1 Radio Resource Config

File: `/tmp/rr_enb1_ho.conf`

```conf
mac_cnfg = {
  phr_cnfg = {
    dl_pathloss_change = "dB3";
    periodic_phr_timer = 50;
    prohibit_phr_timer = 0;
  };
  ulsch_cnfg = {
    max_harq_tx = 4;
    periodic_bsr_timer = 20;
    retx_bsr_timer = 320;
  };
  time_alignment_timer = -1;
};

phy_cnfg = {
  phich_cnfg = {
    duration = "Normal";
    resources = "1/6";
  };
  pusch_cnfg_ded = {
    beta_offset_ack_idx = 6;
    beta_offset_ri_idx = 6;
    beta_offset_cqi_idx = 6;
  };
  sched_request_cnfg = {
    dsr_trans_max = 64;
    period = 20;
    nof_prb = 2;
  };
  cqi_report_cnfg = {
    mode = "periodic";
    period = 40;
    m_ri = 8;
    simultaneousAckCQI = true;
  };
};

cell_list = (
  {
    cell_id = 0x01;
    tac = 0x0001;
    pci = 1;
    root_seq_idx = 204;
    dl_earfcn = 1450;

    ho_active = true;

    meas_cell_list = (
      { eci = 0x19C01; dl_earfcn = 1450; pci = 2; }
    );

    meas_report_desc = {
      a3_report_type = "RSRP";
      a3_offset = 6;
      a3_hysteresis = 0;
      a3_time_to_trigger = 480;
    };
  }
);
```

### 3.3 eNB2 Main Config (PC2)

File: `/tmp/enb2_handover.conf`

```ini
[enb]
enb_id = 0x19C
mcc = 001
mnc = 01
mme_addr = 192.168.1.102
gtp_bind_addr = 192.168.1.101
s1c_bind_addr = 192.168.1.101
n_prb = 50

[enb_files]
sib_config = sib.conf
rr_config = rr_enb2_ho.conf
rb_config = rb.conf

[rf]
device_name = bladeRF
device_args = default
tx_gain = 60
rx_gain = 40

[log]
all_level = info
filename = /tmp/enb2.log
```

### 3.4 eNB2 Radio Resource Config

File: `/tmp/rr_enb2_ho.conf`

```conf
cell_list = (
  {
    cell_id = 0x01;
    tac = 0x0001;
    pci = 2;
    root_seq_idx = 205;
    dl_earfcn = 1450;

    ho_active = true;

    meas_cell_list = (
      { eci = 0x19B01; dl_earfcn = 1450; pci = 1; }
    );

    meas_report_desc = {
      a3_report_type = "RSRP";
      a3_offset = 6;
      a3_hysteresis = 0;
      a3_time_to_trigger = 480;
    };
  }
);
```

## 4. Handover Parameters

### 4.1 A3 Event

The A3 event triggers handover when:

```
Neighbor RSRP > Serving RSRP + Offset
```

| Parameter | Value | Effect |
|-----------|-------|--------|
| a3_offset | 6 dB | Neighbor must be 6 dB stronger |
| a3_hysteresis | 0 dB | No extra margin |
| a3_time_to_trigger | 480 ms | Wait 480 ms before triggering |

### 4.2 Measurement Configuration

Each eNB broadcasts its neighbor list. The UE measures RSRP of listed cells.

```
meas_cell_list = (
  { eci = 0x19C01; dl_earfcn = 1450; pci = 2; }
);
```

- **eci**: E-UTRAN Cell Identifier (enb_id << 8 | cell_id)
- **dl_earfcn**: Frequency (must match)
- **pci**: Physical Cell ID (UE uses this to identify the cell)

## 5. IMS Configuration

### 5.1 S-CSCF Dispatcher

The S-CSCF routes calls to Asterisk for PSTN interconnect.

File: `/etc/kamailio_scscf/dispatcher.list`

```
1 sip:172.22.0.23:5060
```

Reload after change:

```bash
docker exec scscf kamcmd dispatcher.reload
```

### 5.2 P-CSCF IPsec

The P-CSCF establishes IPsec tunnels with UEs. Ports:

| Port | Direction |
|------|-----------|
| 5060 | SIP signaling |
| 5062 | IPsec client |
| 5063 | IPsec server |

## 6. Subscriber Provisioning

### 6.1 HSS (EPC)

Add subscribers via Open5GS web UI (http://localhost:3000) or database:

```sql
INSERT INTO subscribers (imsi, msisdn, k, opc, amf, sqn)
VALUES (
  '001010000123451',
  '1001',
  '465B5CE8B199B49FAA5F0A2EE238A6BC',
  'E8ED289DEBA952E4283B54E88E6183CA',
  '8000',
  '000000000000'
);
```

### 6.2 HSS (IMS)

The IMS HSS stores identity mappings:

```
IMPI: 001010000123451@ims.mnc001.mcc001.3gppnetwork.org
IMPU: sip:1001@ims.mnc001.mcc001.3gppnetwork.org
IMPU: tel:1001
```

## 7. Verification Commands

### 7.1 Check eNB Connections

```bash
docker logs mme 2>&1 | grep "Number of eNBs"
```

Expected: `Number of eNBs is now 2`

### 7.2 Check UE Attachment

```bash
docker logs mme 2>&1 | grep "Attach complete"
```

### 7.3 Check IMS Registration

```bash
docker logs scscf 2>&1 | grep "registered"
```

### 7.4 Monitor Handover

```bash
docker logs -f mme 2>&1 | grep -iE "Handover|CellID|StatusTransfer"
```

## 8. S1 Handover Message Flow

```
1. UE sends Measurement Report to Source eNB
2. Source eNB sends HandoverRequired to MME
3. MME sends HandoverRequest to Target eNB
4. Target eNB sends HandoverRequestAcknowledge to MME
5. MME sends HandoverCommand to Source eNB
6. Source eNB sends RRC Reconfiguration to UE
7. Source eNB sends eNB Status Transfer to MME
8. MME sends MME Status Transfer to Target eNB
9. UE completes handover to Target eNB
10. Target eNB sends HandoverNotify to MME
11. MME sends UE Context Release to Source eNB
```

## 9. Files Modified

| File | Location | Purpose |
|------|----------|---------|
| mme.yaml | mme/mme.yaml | TAI and S1AP address |
| enb1_handover.conf | /tmp/ | eNB1 main config |
| rr_enb1_ho.conf | /tmp/ | eNB1 handover settings |
| enb2_handover.conf | /tmp/ | eNB2 main config |
| rr_enb2_ho.conf | /tmp/ | eNB2 handover settings |
| dispatcher.list | scscf container | PSTN routing |

---

*This document describes how to build the system. See TASKS.md for ordered work items.*

# 03 — Configuration des eNodeB

## Paramètres critiques pour le S1 Handover

⚠️ **IMPORTANT** : Pour que le S1 Handover fonctionne correctement :

| Paramètre | Règle | Raison |
|-----------|-------|--------|
| `tac` | **IDENTIQUE** sur les 2 eNB | Même Tracking Area |
| `pci` | **DIFFÉRENT** sur chaque eNB | Identification unique |
| `dl_earfcn` | **IDENTIQUE** | Handover intra-frequency |
| `enb_id` | **DIFFÉRENT** | Identification S1AP |
| `cell_id` | **DIFFÉRENT** | Identification cellule |

## Configuration eNB1 (PC1 — 192.168.1.100)

### Fichier enb1_handover.conf

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
phy_level = info
all_hex_limit = 32
filename = /tmp/enb1.log
file_max_size = -1
```

### Fichier rr_enb1_ho.conf

```conf
mac_cnfg =
{
  phr_cnfg =
  {
    dl_pathloss_change = "dB3";
    periodic_phr_timer = 50;
    prohibit_phr_timer = 0;
  };
  ulsch_cnfg =
  {
    max_harq_tx = 4;
    periodic_bsr_timer = 20;
    retx_bsr_timer = 320;
  };
  time_alignment_timer = -1;
};

phy_cnfg =
{
  phich_cnfg =
  {
    duration = "Normal";
    resources = "1/6";
  };
  pusch_cnfg_ded =
  {
    beta_offset_ack_idx = 6;
    beta_offset_ri_idx = 6;
    beta_offset_cqi_idx = 6;
  };
  sched_request_cnfg =
  {
    dsr_trans_max = 64;
    period = 20;
    nof_prb = 2;
  };
  cqi_report_cnfg =
  {
    mode = "periodic";
    period = 40;
    m_ri = 8;
    simultaneousAckCQI = true;
  };
};

cell_list =
(
  {
    cell_id = 0x01;
    tac = 0x0001;           // ⚠️ DOIT être identique à eNB2
    pci = 1;                // ⚠️ DOIT être différent de eNB2
    root_seq_idx = 204;
    dl_earfcn = 1450;       // ⚠️ DOIT être identique à eNB2

    // === HANDOVER CONFIG ===
    ho_active = true;
    
    // Liste des cellules voisines
    meas_cell_list =
    (
      { 
        eci = 0x19C01;      // Cell ID de eNB2 (enb_id << 8 | cell_id)
        dl_earfcn = 1450; 
        pci = 2;            // PCI de eNB2
      }
    );
    
    // Configuration A3 Event (déclenchement handover)
    meas_report_desc =
    {
      a3_report_type = "RSRP";
      a3_offset = 6;              // Seuil en dB
      a3_hysteresis = 0;
      a3_time_to_trigger = 480;   // Délai en ms
    };
  }
);
```

## Configuration eNB2 (PC2 — 192.168.1.101)

### Fichier enb2_handover.conf

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
phy_level = info
all_hex_limit = 32
filename = /tmp/enb2.log
file_max_size = -1
```

### Fichier rr_enb2_ho.conf

```conf
mac_cnfg =
{
  // ... (identique à eNB1)
};

phy_cnfg =
{
  // ... (identique à eNB1)
};

cell_list =
(
  {
    cell_id = 0x01;
    tac = 0x0001;           // ⚠️ IDENTIQUE à eNB1
    pci = 2;                // ⚠️ DIFFÉRENT de eNB1
    root_seq_idx = 205;     // Différent pour éviter collision PRACH
    dl_earfcn = 1450;       // ⚠️ IDENTIQUE à eNB1

    // === HANDOVER CONFIG ===
    ho_active = true;
    
    // Liste des cellules voisines
    meas_cell_list =
    (
      { 
        eci = 0x19B01;      // Cell ID de eNB1
        dl_earfcn = 1450; 
        pci = 1;            // PCI de eNB1
      }
    );
    
    // Configuration A3 Event
    meas_report_desc =
    {
      a3_report_type = "RSRP";
      a3_offset = 6;
      a3_hysteresis = 0;
      a3_time_to_trigger = 480;
    };
  }
);
```

## Tableau récapitulatif

| Paramètre | eNB1 (PC1) | eNB2 (PC2) |
|-----------|------------|------------|
| IP | 192.168.1.100 | 192.168.1.101 |
| enb_id | 0x19B | 0x19C |
| cell_id | 0x01 | 0x01 |
| **ECI** | **0x19B01** | **0x19C01** |
| **tac** | **0x0001** | **0x0001** |
| **pci** | **1** | **2** |
| **dl_earfcn** | **1450** | **1450** |
| root_seq_idx | 204 | 205 |
| ho_active | true | true |

## Démarrage des eNodeB

### PC1

```bash
cd /tmp
sudo srsenb enb1_handover.conf
```

### PC2

```bash
cd /tmp
sudo srsenb enb2_handover.conf
```

## Vérification

### Logs MME — Les 2 eNB doivent être connectés

```bash
docker logs mme 2>&1 | grep "Number of eNBs"
# [Added] Number of eNBs is now 1
# [Added] Number of eNBs is now 2
```

### Logs eNB — Connexion S1 établie

```
S1 Setup procedure
S1 Setup Response received
```

---

➡️ **Étape suivante** : [04-CONFIGURATION-MME.md](04-CONFIGURATION-MME.md)

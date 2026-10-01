# 03 — eNodeB Configuration

## Critical Parameters for S1 Handover

⚠️ **IMPORTANT**: For S1 Handover to work correctly:

| Parameter | Rule | Reason |
|-----------|------|--------|
| `tac` | **IDENTICAL** on both eNBs | Same Tracking Area |
| `pci` | **DIFFERENT** on each eNB | Unique identification |
| `dl_earfcn` | **IDENTICAL** | Intra-frequency handover |
| `enb_id` | **DIFFERENT** | S1AP identification |
| `cell_id` | **DIFFERENT** | Cell identification |

## eNB1 Configuration (PC1 — 192.168.1.100)

### File: enb1_handover.conf

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

### File: rr_enb1_ho.conf

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
    tac = 0x0001;           // ⚠️ MUST be identical to eNB2
    pci = 1;                // ⚠️ MUST be different from eNB2
    root_seq_idx = 204;
    dl_earfcn = 1450;       // ⚠️ MUST be identical to eNB2

    // === HANDOVER CONFIG ===
    ho_active = true;
    
    // Neighbor cell list
    meas_cell_list =
    (
      { 
        eci = 0x19C01;      // Cell ID of eNB2 (enb_id << 8 | cell_id)
        dl_earfcn = 1450; 
        pci = 2;            // PCI of eNB2
      }
    );
    
    // A3 Event configuration (handover trigger)
    meas_report_desc =
    {
      a3_report_type = "RSRP";
      a3_offset = 6;              // Threshold in dB
      a3_hysteresis = 0;
      a3_time_to_trigger = 480;   // Delay in ms
    };
  }
);
```

## eNB2 Configuration (PC2 — 192.168.1.101)

### File: enb2_handover.conf

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

### File: rr_enb2_ho.conf

```conf
mac_cnfg =
{
  // ... (same as eNB1)
};

phy_cnfg =
{
  // ... (same as eNB1)
};

cell_list =
(
  {
    cell_id = 0x01;
    tac = 0x0001;           // ⚠️ IDENTICAL to eNB1
    pci = 2;                // ⚠️ DIFFERENT from eNB1
    root_seq_idx = 205;     // Different to avoid PRACH collision
    dl_earfcn = 1450;       // ⚠️ IDENTICAL to eNB1

    // === HANDOVER CONFIG ===
    ho_active = true;
    
    // Neighbor cell list
    meas_cell_list =
    (
      { 
        eci = 0x19B01;      // Cell ID of eNB1
        dl_earfcn = 1450; 
        pci = 1;            // PCI of eNB1
      }
    );
    
    // A3 Event configuration
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

## Summary Table

| Parameter | eNB1 (PC1) | eNB2 (PC2) |
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

## Starting the eNodeBs

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

## Verification

### MME Logs — Both eNBs must be connected

```bash
docker logs mme 2>&1 | grep "Number of eNBs"
# [Added] Number of eNBs is now 1
# [Added] Number of eNBs is now 2
```

### eNB Logs — S1 connection established

```
S1 Setup procedure
S1 Setup Response received
```

---

➡️ **Next Step**: [04-MME-CONFIGURATION.md](04-MME-CONFIGURATION.md)

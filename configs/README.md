# Configuration Files

## Directory Structure

```
configs/
├── enb1/                    # eNB1 (PC1) configurations
│   ├── enb1_handover.conf   # Main eNB config
│   └── rr_enb1_ho.conf      # Radio Resource with handover
├── enb2/                    # eNB2 (PC2) configurations
│   ├── enb2_handover.conf   # Main eNB config
│   └── rr_enb2_ho.conf      # Radio Resource with handover
├── rr1.conf                 # Reference RR config for eNB1
├── rr2.conf                 # Reference RR config for eNB2
├── sib.conf                 # System Information Block
├── rb.conf                  # Radio Bearer config
├── start_enb1.sh            # Startup script for eNB1
└── start_enb2.sh            # Startup script for eNB2
```

## Key Parameters

| Parameter | eNB1 | eNB2 | Notes |
|-----------|------|------|-------|
| enb_id | 0x19B | 0x19C | Must be different |
| tac | 0x0001 | 0x0001 | **Must be identical** |
| pci | 1 | 2 | Must be different |
| dl_earfcn | 1450 | 1450 | Must be identical |
| ho_active | true | true | Enables handover |

## Usage

### PC1 (eNB1)
```bash
sudo srsenb configs/enb1/enb1_handover.conf
```

### PC2 (eNB2)
```bash
sudo srsenb configs/enb2/enb2_handover.conf
```

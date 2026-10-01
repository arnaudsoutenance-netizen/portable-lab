# 01 — Prerequisites

## Required Hardware

### PC1 (eNodeB 1)
- [x] Linux PC (Ubuntu 22.04 LTS recommended)
- [x] bladeRF xA4 or xA9
- [x] TX/RX Antenna (700-2700 MHz)
- [x] USB 3.0 cable
- [x] Network connection to Core (192.168.1.x)

### PC2 (eNodeB 2)
- [x] Linux PC (Ubuntu 22.04 LTS recommended)
- [x] bladeRF xA4 or xA9
- [x] TX/RX Antenna (700-2700 MHz)
- [x] USB 3.0 cable
- [x] Network connection to Core (192.168.1.x)

### Core Network
- [x] Open5GS installed and running
- [x] IMS (Kamailio P-CSCF, I-CSCF, S-CSCF)
- [x] RTPEngine
- [x] HSS with configured subscribers

### UE (Phones)
- [x] 2 VoLTE-compatible smartphones
- [x] Programmable SIMs (sysmoISIM or equivalent)
- [x] APN configured: `internet` + `ims`

## Required Software

### On PC1 and PC2

```bash
# System dependencies
sudo apt update
sudo apt install -y build-essential cmake libfftw3-dev \
    libmbedtls-dev libboost-program-options-dev \
    libconfig++-dev libsctp-dev libbladerf-dev

# srsRAN (v23.11+)
git clone https://github.com/srsran/srsRAN_4G.git
cd srsRAN_4G
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo make install
```

### On the Core Network

```bash
# Open5GS (Docker recommended)
git clone https://github.com/VoicenterTeam/openimss.git
cd openimss
docker-compose up -d

# Verify everything is up
docker ps | grep -E "mme|hss|sgwc|pcscf"
```

## Network Configuration

### IP Addressing Plan

| Device | IP | Role |
|--------|-----|------|
| PC1 (eNB1) | 192.168.1.100 | Source eNodeB |
| PC2 (eNB2) | 192.168.1.101 | Target eNodeB |
| MME | 192.168.1.102 | Mobility Management Entity |
| SGW | 192.168.1.103 | Serving Gateway |

### Connectivity Check

```bash
# From PC1
ping -c 3 192.168.1.102  # MME
ping -c 3 192.168.1.101  # PC2

# From PC2
ping -c 3 192.168.1.102  # MME
ping -c 3 192.168.1.100  # PC1
```

## HSS Subscribers

### Add Subscribers

```bash
# Via Open5GS web interface (http://localhost:3000)
# Or via script

# Subscriber 1
IMSI: 001010000123451
MSISDN: 1001
Key: 465B5CE8B199B49FAA5F0A2EE238A6BC
OPC: E8ED289DEBA952E4283B54E88E6183CA

# Subscriber 2
IMSI: 001010000099901
MSISDN: 1099
Key: 465B5CE8B199B49FAA5F0A2EE238A6BC
OPC: E8ED289DEBA952E4283B54E88E6183CA
```

## Final Checks

### Checklist Before Continuing

- [ ] Both PCs can ping the MME
- [ ] bladeRF detected on both PCs (`bladeRF-cli -p`)
- [ ] Open5GS containers running (`docker ps`)
- [ ] Subscribers added to HSS
- [ ] SIMs programmed with correct values

### Test bladeRF

```bash
# On each PC
bladeRF-cli -p
# Should display: "Backend: libusb, Serial: xxxxxx"

bladeRF-cli -i
bladeRF> version
# Should display firmware version
bladeRF> quit
```

---

➡️ **Next Step**: [02-INSTALLATION.md](02-INSTALLATION.md)

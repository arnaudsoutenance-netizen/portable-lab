# 02 — Installation

## srsRAN Installation on PC1 and PC2

### 1. Clone the Repository

```bash
cd ~
git clone https://github.com/srsran/srsRAN_4G.git
cd srsRAN_4G
```

### 2. Install Dependencies

```bash
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    libfftw3-dev \
    libmbedtls-dev \
    libboost-program-options-dev \
    libconfig++-dev \
    libsctp-dev \
    libbladerf-dev \
    bladerf \
    bladerf-fpga-hostedx40 \
    libbladerf2
```

### 3. Compile srsRAN

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
sudo ldconfig
```

### 4. Verify Installation

```bash
which srsenb
# /usr/local/bin/srsenb

srsenb --version
# srsRAN release 23.xx
```

## Install Handover Configurations

### On PC1 (eNB1)

```bash
# Copy config files
sudo mkdir -p /etc/srsran
sudo cp configs/enb1/* /etc/srsran/

# Or use /tmp for testing
cp configs/enb1/enb1_handover.conf /tmp/
cp configs/enb1/rr_enb1_ho.conf /tmp/
```

### On PC2 (eNB2)

```bash
# Copy via SCP from PC1
scp -r configs/enb2/* f2g@192.168.1.101:/tmp/

# Or copy manually
sudo mkdir -p /etc/srsran
cp configs/enb2/* /etc/srsran/
```

## Open5GS + IMS Installation (if not already done)

### 1. Clone VoicenterTeam Repo

```bash
cd ~/Telecom/Core-Network
git clone https://github.com/VoicenterTeam/openimss.git
cd openimss
```

### 2. Configure the MME

Edit `mme/mme.yaml`:

```yaml
mme:
  s1ap:
    - addr: 192.168.1.102  # IP accessible by eNBs
  
  tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 1  # TAC must match eNBs
```

### 3. Start Containers

```bash
docker-compose up -d

# Verify
docker ps
docker logs mme | tail -20
```

### 4. Create macvlan Interface (if needed)

```bash
# To expose MME on physical network
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  macvlan_net

# Connect MME
docker network connect macvlan_net mme --ip 192.168.1.102
```

## Installation Verification

### S1 Connectivity Test

```bash
# From PC1
nc -zv 192.168.1.102 36412
# Connection to 192.168.1.102 36412 port [tcp/*] succeeded!
```

### bladeRF Test

```bash
# On each PC
bladeRF-cli -p

# Should return something like:
#   Backend:        libusb
#   Serial:         abc123...
#   USB Bus:        1
#   USB Address:    5
```

### IMS Container Test

```bash
docker logs pcscf 2>&1 | tail -5
docker logs scscf 2>&1 | tail -5
docker logs icscf 2>&1 | tail -5
```

## Directory Structure After Installation

```
PC1 (/tmp/)
├── enb1_handover.conf
├── rr_enb1_ho.conf
├── sib.conf
└── rb.conf

PC2 (/tmp/)
├── enb2_handover.conf
├── rr_enb2_ho.conf
├── sib.conf
└── rb.conf

Core Network (Docker)
├── mme
├── hss
├── sgwc
├── sgwu
├── smf
├── upf
├── pcscf
├── icscf
├── scscf
└── rtpengine
```

---

➡️ **Next Step**: [03-ENB-CONFIGURATION.md](03-ENB-CONFIGURATION.md)

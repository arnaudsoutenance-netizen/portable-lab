# 02 — Installation

## Installation srsRAN sur PC1 et PC2

### 1. Cloner le repository

```bash
cd ~
git clone https://github.com/srsran/srsRAN_4G.git
cd srsRAN_4G
```

### 2. Installer les dépendances

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

### 3. Compiler srsRAN

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
sudo ldconfig
```

### 4. Vérifier l'installation

```bash
which srsenb
# /usr/local/bin/srsenb

srsenb --version
# srsRAN release 23.xx
```

## Installation des configs Handover

### Sur PC1 (eNB1)

```bash
# Copier les fichiers de config
sudo mkdir -p /etc/srsran
sudo cp configs/enb1/* /etc/srsran/

# Ou utiliser /tmp pour les tests
cp configs/enb1/enb1_handover.conf /tmp/
cp configs/enb1/rr_enb1_ho.conf /tmp/
```

### Sur PC2 (eNB2)

```bash
# Copier via SCP depuis PC1
scp -r configs/enb2/* f2g@192.168.1.101:/tmp/

# Ou copier manuellement
sudo mkdir -p /etc/srsran
cp configs/enb2/* /etc/srsran/
```

## Installation Open5GS + IMS (si pas déjà fait)

### 1. Cloner le repo VoicenterTeam

```bash
cd ~/Telecom/Core-Network
git clone https://github.com/VoicenterTeam/openimss.git
cd openimss
```

### 2. Configurer le MME

Éditer `mme/mme.yaml` :

```yaml
mme:
  s1ap:
    - addr: 192.168.1.102  # IP accessible par les eNB
  
  tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 1  # TAC doit matcher les eNB
```

### 3. Démarrer les containers

```bash
docker-compose up -d

# Vérifier
docker ps
docker logs mme | tail -20
```

### 4. Créer l'interface macvlan (si nécessaire)

```bash
# Pour exposer le MME sur le réseau physique
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  macvlan_net

# Connecter le MME
docker network connect macvlan_net mme --ip 192.168.1.102
```

## Vérification de l'installation

### Test de connectivité S1

```bash
# Sur PC1
nc -zv 192.168.1.102 36412
# Connection to 192.168.1.102 36412 port [tcp/*] succeeded!
```

### Test bladeRF

```bash
# Sur chaque PC
bladeRF-cli -p

# Doit retourner quelque chose comme:
#   Backend:        libusb
#   Serial:         abc123...
#   USB Bus:        1
#   USB Address:    5
```

### Test containers IMS

```bash
docker logs pcscf 2>&1 | tail -5
docker logs scscf 2>&1 | tail -5
docker logs icscf 2>&1 | tail -5
```

## Arborescence après installation

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

➡️ **Étape suivante** : [03-CONFIGURATION-ENB.md](03-CONFIGURATION-ENB.md)

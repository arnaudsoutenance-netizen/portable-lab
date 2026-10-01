# 01 — Prérequis

## Matériel requis

### PC1 (eNodeB 1)
- [x] PC Linux (Ubuntu 22.04 LTS recommandé)
- [x] bladeRF xA4 ou xA9
- [x] Antenne TX/RX (700-2700 MHz)
- [x] Câble USB 3.0
- [x] Connexion réseau vers le Core (192.168.1.x)

### PC2 (eNodeB 2)
- [x] PC Linux (Ubuntu 22.04 LTS recommandé)
- [x] bladeRF xA4 ou xA9
- [x] Antenne TX/RX (700-2700 MHz)
- [x] Câble USB 3.0
- [x] Connexion réseau vers le Core (192.168.1.x)

### Core Network
- [x] Open5GS installé et fonctionnel
- [x] IMS (Kamailio P-CSCF, I-CSCF, S-CSCF)
- [x] RTPEngine
- [x] HSS avec subscribers configurés

### UE (Téléphones)
- [x] 2 smartphones compatibles VoLTE
- [x] SIM programmables (sysmoISIM ou équivalent)
- [x] APN configuré : `internet` + `ims`

## Logiciels requis

### Sur PC1 et PC2

```bash
# Dépendances système
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

### Sur le Core Network

```bash
# Open5GS (Docker recommandé)
git clone https://github.com/VoicenterTeam/openimss.git
cd openimss
docker-compose up -d

# Vérifier que tout est up
docker ps | grep -E "mme|hss|sgwc|pcscf"
```

## Configuration réseau

### Plan d'adressage

| Équipement | IP | Rôle |
|------------|-----|------|
| PC1 (eNB1) | 192.168.1.100 | eNodeB source |
| PC2 (eNB2) | 192.168.1.101 | eNodeB target |
| MME | 192.168.1.102 | Mobility Management Entity |
| SGW | 192.168.1.103 | Serving Gateway |

### Vérification connectivité

```bash
# Depuis PC1
ping -c 3 192.168.1.102  # MME
ping -c 3 192.168.1.101  # PC2

# Depuis PC2
ping -c 3 192.168.1.102  # MME
ping -c 3 192.168.1.100  # PC1
```

## Subscribers HSS

### Ajouter les subscribers

```bash
# Via l'interface web Open5GS (http://localhost:3000)
# Ou via script

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

## Vérifications finales

### Checklist avant de continuer

- [ ] Les 2 PC peuvent ping le MME
- [ ] bladeRF détecté sur les 2 PC (`bladeRF-cli -p`)
- [ ] Open5GS containers running (`docker ps`)
- [ ] Subscribers ajoutés au HSS
- [ ] SIM programmées avec les bonnes valeurs

### Test bladeRF

```bash
# Sur chaque PC
bladeRF-cli -p
# Doit afficher: "Backend: libusb, Serial: xxxxxx"

bladeRF-cli -i
bladeRF> version
# Doit afficher la version firmware
bladeRF> quit
```

---

➡️ **Étape suivante** : [02-INSTALLATION.md](02-INSTALLATION.md)

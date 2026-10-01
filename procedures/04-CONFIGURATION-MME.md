# 04 — Configuration du MME

## Configuration Open5GS MME

### Fichier mme.yaml

Le MME doit être configuré pour accepter les 2 eNodeB et supporter le S1 Handover.

```yaml
mme:
  freeDiameter: /etc/freeDiameter/mme.conf
  s1ap:
    - addr: 192.168.1.102    # IP accessible par les eNB
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
    tac: 1                    # ⚠️ Doit correspondre aux eNB
  security:
    integrity_order: [EIA2, EIA1, EIA0]
    ciphering_order: [EEA0, EEA1, EEA2]
  network_name:
    full: F2G Network
  mme_name: open5gs-mme0
```

### Points importants

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `s1ap.addr` | 192.168.1.102 | IP du MME accessible par les eNB |
| `tai.tac` | 1 | Doit matcher le TAC des eNB (0x0001) |
| `plmn_id` | 001/01 | MCC/MNC de votre réseau |

## Configuration de l'interface réseau

### Option 1 : macvlan (recommandé)

```bash
# Créer le réseau macvlan
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  macvlan_net

# Connecter le MME au réseau
docker network connect macvlan_net mme --ip 192.168.1.102
```

### Option 2 : Host network

Dans `docker-compose.yaml` :

```yaml
mme:
  network_mode: host
```

## Vérification de la configuration

### 1. Vérifier que le MME écoute sur S1AP

```bash
docker exec mme ss -tlnp | grep 36412
# LISTEN  0  128  192.168.1.102:36412  *:*
```

### 2. Vérifier les logs au démarrage

```bash
docker logs mme 2>&1 | head -50
```

Output attendu :
```
Open5GS daemon v2.7.x
MME initialize...
S1AP server started
GUTI: mcc:001,mnc:01,mme_gid:2,mme_code:1
TAI: mcc:001,mnc:01,tac:1
```

### 3. Vérifier la connexion Diameter (HSS)

```bash
docker logs mme 2>&1 | grep -i diameter
# CONNECTED TO 'hss.epc.mnc001.mcc001.3gppnetwork.org'
```

## Configuration du TAC

⚠️ **Le TAC est critique pour le Handover**

Le TAC configuré dans le MME doit correspondre au TAC des eNodeB :

```
MME (tai.tac)     = 1      (0x0001)
eNB1 (cell.tac)   = 0x0001 ✅
eNB2 (cell.tac)   = 0x0001 ✅  <- Doit être identique !
```

### Erreur commune

Si eNB2 a un TAC différent (ex: 0x0002), l'UE fera un **TAU (Tracking Area Update)** au lieu d'un **Handover**, ce qui peut couper l'appel VoLTE.

## Redémarrage du MME

Après modification de la config :

```bash
# Redémarrer
docker restart mme

# Vérifier
docker logs -f mme 2>&1 | head -30
```

## Vérification des eNB connectés

```bash
# Écouter les connexions S1
docker logs -f mme 2>&1 | grep -iE "eNB|Number"
```

Output attendu :
```
eNB-S1 accepted[192.168.1.100]:xxxxx in s1_path module
eNB-S1 accepted[192.168.1.100] in master_sm module
[Added] Number of eNBs is now 1
eNB-S1 accepted[192.168.1.101]:xxxxx in s1_path module
eNB-S1 accepted[192.168.1.101] in master_sm module
[Added] Number of eNBs is now 2
```

## Configuration IMS pour VoLTE

### Vérifier la connexion PCRF ↔ P-CSCF

```bash
docker logs pcrf 2>&1 | grep -i connected
# CONNECTED TO 'pcscf.ims.mnc001.mcc001.3gppnetwork.org'
```

### Vérifier les subscribers IMS

```bash
docker exec mysql mysql -u root -proot -e \
  "SELECT * FROM open5gs.subscribers LIMIT 5;"
```

---

➡️ **Étape suivante** : [05-TEST-HANDOVER.md](05-TEST-HANDOVER.md)

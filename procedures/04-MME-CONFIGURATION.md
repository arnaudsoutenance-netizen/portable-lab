# 04 — MME Configuration

## Open5GS MME Configuration

### File: mme.yaml

The MME must be configured to accept both eNodeBs and support S1 Handover.

```yaml
mme:
  freeDiameter: /etc/freeDiameter/mme.conf
  s1ap:
    - addr: 192.168.1.102    # IP accessible by eNBs
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
    tac: 1                    # ⚠️ Must match the eNBs
  security:
    integrity_order: [EIA2, EIA1, EIA0]
    ciphering_order: [EEA0, EEA1, EEA2]
  network_name:
    full: F2G Network
  mme_name: open5gs-mme0
```

### Key Points

| Parameter | Value | Description |
|-----------|-------|-------------|
| `s1ap.addr` | 192.168.1.102 | MME IP accessible by eNBs |
| `tai.tac` | 1 | Must match eNB TAC (0x0001) |
| `plmn_id` | 001/01 | Your network MCC/MNC |

## Network Interface Configuration

### Option 1: macvlan (recommended)

```bash
# Create macvlan network
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  macvlan_net

# Connect MME to the network
docker network connect macvlan_net mme --ip 192.168.1.102
```

### Option 2: Host network

In `docker-compose.yaml`:

```yaml
mme:
  network_mode: host
```

## Configuration Verification

### 1. Verify MME is listening on S1AP

```bash
docker exec mme ss -tlnp | grep 36412
# LISTEN  0  128  192.168.1.102:36412  *:*
```

### 2. Check startup logs

```bash
docker logs mme 2>&1 | head -50
```

Expected output:
```
Open5GS daemon v2.7.x
MME initialize...
S1AP server started
GUTI: mcc:001,mnc:01,mme_gid:2,mme_code:1
TAI: mcc:001,mnc:01,tac:1
```

### 3. Verify Diameter connection (HSS)

```bash
docker logs mme 2>&1 | grep -i diameter
# CONNECTED TO 'hss.epc.mnc001.mcc001.3gppnetwork.org'
```

## TAC Configuration

⚠️ **TAC is critical for Handover**

The TAC configured in MME must match the eNodeB TAC:

```
MME (tai.tac)     = 1      (0x0001)
eNB1 (cell.tac)   = 0x0001 ✅
eNB2 (cell.tac)   = 0x0001 ✅  <- Must be identical!
```

### Common Error

If eNB2 has a different TAC (e.g., 0x0002), the UE will perform a **TAU (Tracking Area Update)** instead of a **Handover**, which may drop the VoLTE call.

## Restarting the MME

After modifying the config:

```bash
# Restart
docker restart mme

# Verify
docker logs -f mme 2>&1 | head -30
```

## Verify Connected eNBs

```bash
# Monitor S1 connections
docker logs -f mme 2>&1 | grep -iE "eNB|Number"
```

Expected output:
```
eNB-S1 accepted[192.168.1.100]:xxxxx in s1_path module
eNB-S1 accepted[192.168.1.100] in master_sm module
[Added] Number of eNBs is now 1
eNB-S1 accepted[192.168.1.101]:xxxxx in s1_path module
eNB-S1 accepted[192.168.1.101] in master_sm module
[Added] Number of eNBs is now 2
```

## IMS Configuration for VoLTE

### Verify PCRF ↔ P-CSCF connection

```bash
docker logs pcrf 2>&1 | grep -i connected
# CONNECTED TO 'pcscf.ims.mnc001.mcc001.3gppnetwork.org'
```

### Verify IMS subscribers

```bash
docker exec mysql mysql -u root -proot -e \
  "SELECT * FROM open5gs.subscribers LIMIT 5;"
```

---

➡️ **Next Step**: [05-HANDOVER-TESTING.md](05-HANDOVER-TESTING.md)

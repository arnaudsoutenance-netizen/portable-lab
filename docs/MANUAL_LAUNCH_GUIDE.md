# Manual Launch Guide — S1 Handover VoLTE Lab

Complete step-by-step procedure to launch the lab manually, from cold start to live Wireshark capture during handover.

**Duration:** ~10 minutes  
**Prerequisites:** All hardware connected, SIM cards provisioned

---

## Quick Reference

| Component | Machine | Command |
|-----------|---------|---------|
| Core + IMS | PC1 | `docker-compose up -d` |
| eNB1 | PC1 | `sudo srsenb /tmp/enb1_handover.conf` |
| eNB2 | PC2 | `sudo srsenb /tmp/enb2_handover.conf` |
| Wireshark | PC1 | `wireshark -i any -k -f "sctp or gtp"` |

---

## Phase 1: Pre-flight Checks (2 min)

### 1.1 Verify Network Connectivity

```bash
# On PC1
ping -c 2 192.168.1.101   # PC2 reachable
ping -c 2 192.168.1.102   # MME IP (may fail if not started yet)
```

### 1.2 Check bladeRF Devices

```bash
# On PC1
bladeRF-cli -p
# Expected: Serial XXXXXXXXXX, bladeRF 2.0 (bladeRF xA4)

# On PC2 (via SSH)
ssh f2g@192.168.1.101 "bladeRF-cli -p"
```

### 1.3 Verify Config Files Exist

```bash
# On PC1
ls -la /tmp/enb1_handover.conf /tmp/rr_enb1_ho.conf

# On PC2
ssh f2g@192.168.1.101 "ls -la /tmp/enb2_handover.conf /tmp/rr_enb2_ho.conf"
```

If config files are missing, copy them:

```bash
# PC1
cp ~/Desktop/Handover/configs/enb1/enb1_handover.conf /tmp/
cp ~/Desktop/Handover/configs/enb1/rr_enb1_ho.conf /tmp/

# PC2
scp ~/Desktop/Handover/configs/enb2/enb2_handover.conf f2g@192.168.1.101:/tmp/
scp ~/Desktop/Handover/configs/enb2/rr_enb2_ho.conf f2g@192.168.1.101:/tmp/
```

---

## Phase 2: Start Core Network (2 min)

### 2.1 Start Docker Containers

```bash
cd /home/f2g/Telecom/Core-Network/openimss
docker-compose up -d
```

Wait 10 seconds for all services to initialize.

### 2.2 Verify Core Services

```bash
# Check containers running
docker ps --format "table {{.Names}}\t{{.Status}}" | head -15

# Check MME is listening
docker logs mme 2>&1 | tail -5
# Look for: "s1ap_server() [INFO]: Waiting for eNB connection"

# Check IMS Diameter connections
docker logs pcrf 2>&1 | grep -i "CONNECTED"
# Look for: "CONNECTED TO 'pcscf'"
```

### 2.3 Create macvlan Network (First Time Only)

```bash
# Create macvlan for MME external access
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=enp3s0 \
  macvlan_net

# Connect MME to macvlan
docker network connect --ip 192.168.1.102 macvlan_net mme
```

### 2.4 Verify MME External Connectivity

```bash
# From PC2, test S1 connectivity to MME
ssh f2g@192.168.1.101 "nc -zv 192.168.1.102 36412"
# Expected: Connection to 192.168.1.102 36412 port [tcp/*] succeeded!
```

---

## Phase 3: Start Wireshark Live Capture (1 min)

### 3.1 Launch Wireshark with S1AP/GTP Filter

Open a new terminal on PC1:

```bash
# Option A: Capture all interfaces with SCTP and GTP
sudo wireshark -i any -k -f "sctp or udp port 2152"

# Option B: Capture only macvlan interface
sudo wireshark -i enp3s0 -k -f "sctp or udp port 2152"

# Option C: CLI capture with tshark
sudo tshark -i any -f "sctp or udp port 2152" -Y "s1ap or gtpv2"
```

### 3.2 Wireshark Display Filter for Handover

In Wireshark filter bar, apply:

```
s1ap.procedureCode == 0 || s1ap.procedureCode == 1 || s1ap.procedureCode == 5
```

Or for all S1AP messages:

```
s1ap
```

### 3.3 Key S1AP Messages to Watch

| Procedure Code | Message | Direction |
|----------------|---------|-----------|
| 0 | HandoverPreparation | eNB → MME |
| 1 | HandoverResourceAllocation | MME → eNB |
| 5 | HandoverNotification | eNB → MME |
| 3 | PathSwitchRequest | eNB → MME |

---

## Phase 4: Start eNB1 on PC1 (1 min)

### 4.1 Launch srsENB on PC1

```bash
# Terminal 1 on PC1
cd /tmp
sudo srsenb enb1_handover.conf
```

### 4.2 Expected Output

```
---  Software Radio Systems LTE eNodeB  ---

Opening 1 channels in RF device=bladeRF with args=
Set RX antenna to RX
...
==== eNodeB started ===
Type <t> to view trace
Setting frequency: DL=2140.0 MHz, UL=1950.0 MHz
Found bladeRF serial XXXXXXXXXX
```

### 4.3 Verify S1 Connection in MME Logs

```bash
# In another terminal
docker logs -f mme 2>&1 | grep -i "enb\|s1ap"
# Look for: "eNB-S1 accepted[192.168.1.100]"
# Look for: "Number of eNBs is now 1"
```

---

## Phase 5: Start eNB2 on PC2 (1 min)

### 5.1 SSH to PC2 and Launch

```bash
# From PC1, SSH to PC2
ssh f2g@192.168.1.101

# On PC2
cd /tmp
sudo srsenb enb2_handover.conf
```

Password: `1234`

### 5.2 Alternative: Launch from PC1 via SSH

```bash
# One-liner from PC1
sshpass -p "1234" ssh f2g@192.168.1.101 "cd /tmp && sudo -S srsenb enb2_handover.conf" <<< "1234"
```

### 5.3 Verify Both eNBs Connected

```bash
docker logs mme 2>&1 | grep "Number of eNBs"
# Expected: "Number of eNBs is now 2"
```

In Wireshark, you should see:
- 2x `S1SetupRequest` (one from each eNB)
- 2x `S1SetupResponse` (from MME)

---

## Phase 6: Attach UEs and Register IMS (2 min)

### 6.1 Power On Phones

1. Insert SIM cards (IMSI 001010000123451 and 001010000099901)
2. Power on both phones
3. Wait for LTE attachment (signal bars appear)

### 6.2 Verify LTE Attachment

On eNB1 terminal, press `t` for trace:

```
------DL-------------------------------UL--------------------------------
rnti  cqi  ri  mcs  brate   ok  nok  (%)  pusch  pucch  phr  mcs  brate
  46   15   1   28   5.2M  100    2   2%   -8.0   -4.5   20   24   2.1M
```

### 6.3 Verify IMS Registration

```bash
docker logs scscf 2>&1 | grep -i "REGISTER"
# Look for: "REGISTER sip:ims.mnc001.mcc001.3gppnetwork.org"
# Look for: "200 OK" response
```

### 6.4 Check VoLTE Status on Phones

- Android: Settings → About Phone → SIM Status → "Voice over LTE: Available"
- Or dial `*#*#4636#*#*` → Phone Information → VoLTE Provisioned: true

---

## Phase 7: Initiate VoLTE Call (1 min)

### 7.1 Start Call Monitoring

```bash
# Terminal on PC1 - watch SIP INVITE
docker logs -f scscf 2>&1 | grep -iE "INVITE|180|200|ACK|BYE"
```

### 7.2 Make Call

From Phone 1 (1001), dial Phone 2 (1099):

```
1099
```

### 7.3 Verify Call Established

In S-CSCF logs:

```
INVITE sip:1099@ims.mnc001.mcc001.3gppnetwork.org
180 Ringing
200 OK
ACK
```

In Wireshark, verify GTP-U traffic (UDP port 2152) flowing.

---

## Phase 8: Trigger Handover (1 min)

### 8.1 Move Phone Physically

With call active, move Phone 1 closer to eNB2 and away from eNB1.

**Handover triggers when:**
- RSRP from eNB2 > RSRP from eNB1 + 6 dB (a3_offset)
- Condition holds for 480 ms (time_to_trigger)

### 8.2 Monitor Handover in eNB1

In eNB1 terminal (press `t`):

```
HO: Starting S1 Handover to eci=0x19C01 (eNB2)
HO: Sending HandoverRequired
HO: Received HandoverCommand
HO: RRC Connection Release (handover complete to target)
```

### 8.3 Monitor Handover in MME Logs

```bash
docker logs -f mme 2>&1 | grep -iE "handover|source|target"
```

Expected sequence:

```
[S1AP] Received HandoverRequired from eNB 0x19B
[S1AP] Sending HandoverRequest to eNB 0x19C
[S1AP] Received HandoverRequestAcknowledge from eNB 0x19C
[S1AP] Sending HandoverCommand to eNB 0x19B
[S1AP] Received MMEStatusTransfer
[S1AP] Sending MMEStatusTransfer to target eNB
[S1AP] Received HandoverNotify from eNB 0x19C
[S1AP] Sending UEContextReleaseCommand to source eNB
```

### 8.4 Verify in Wireshark

Complete S1AP handover sequence:

| # | Message | Source | Destination |
|---|---------|--------|-------------|
| 1 | HandoverRequired | eNB1 | MME |
| 2 | HandoverRequest | MME | eNB2 |
| 3 | HandoverRequestAcknowledge | eNB2 | MME |
| 4 | HandoverCommand | MME | eNB1 |
| 5 | eNBStatusTransfer | eNB1 | MME |
| 6 | MMEStatusTransfer | MME | eNB2 |
| 7 | HandoverNotify | eNB2 | MME |
| 8 | UEContextReleaseCommand | MME | eNB1 |
| 9 | UEContextReleaseComplete | eNB1 | MME |

---

## Phase 9: Verify Call Continuity

### 9.1 Check Audio Still Working

After handover, verify:
- No audio interruption
- Call still connected
- Both parties can hear each other

### 9.2 Check CellID Changed

On Phone (Android):
```
*#*#4636#*#* → Phone Information → Cell ID
```

- Before HO: CellID = 0x19B01 (eNB1)
- After HO: CellID = 0x19C01 (eNB2)

### 9.3 Save Wireshark Capture

File → Save As → `handover_volte_YYYYMMDD_HHMM.pcapng`

---

## Troubleshooting Quick Reference

### eNB won't connect to MME

```bash
# Check MME is reachable
nc -zv 192.168.1.102 36412

# Check MME container
docker logs mme | tail -20

# Restart MME
docker restart mme
```

### UE won't attach

```bash
# Check HSS subscriber
docker exec -it hss /bin/bash
open5gs-dbctl show

# Verify PLMN on phone matches 001-01
```

### IMS registration fails

```bash
# Check P-CSCF
docker logs pcscf | grep -i error

# Check Diameter Rx
docker logs pcrf | grep -i pcscf

# Restart IMS stack
docker restart pcrf pcscf icscf scscf hss
```

### Handover not triggering

```bash
# Check A3 parameters in rr config
grep -A10 "meas_report_desc" /tmp/rr_enb1_ho.conf

# Verify both cells in meas_cell_list
grep -A10 "meas_cell_list" /tmp/rr_enb1_ho.conf

# Increase logging
sudo srsenb enb1_handover.conf --log.all_level=debug
```

### Call drops during handover

```bash
# Check GTP tunnel
docker logs sgwu | grep -i error

# Check bearer modification
docker logs mme | grep -i "bearer\|modify"

# Verify TAC match (CRITICAL)
grep "tac" /tmp/enb1_handover.conf
ssh f2g@192.168.1.101 "grep tac /tmp/enb2_handover.conf"
# Both must be: tac = 0x0001
```

---

## Complete Startup Script

Save as `start_lab.sh`:

```bash
#!/bin/bash
# Complete lab startup script

echo "=== Starting VoLTE Handover Lab ==="

# 1. Start Core
cd /home/f2g/Telecom/Core-Network/openimss
docker-compose up -d
sleep 10

# 2. Verify Core
echo ""
echo "=== Core Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "mme|hss|cscf"

# 3. Start Wireshark in background
echo ""
echo "=== Starting Wireshark ==="
sudo wireshark -i any -k -f "sctp or udp port 2152" &
sleep 2

# 4. Start eNB1
echo ""
echo "=== Starting eNB1 ==="
gnome-terminal --title="eNB1" -- bash -c "sudo srsenb /tmp/enb1_handover.conf; exec bash"

# 5. Start eNB2 via SSH
echo ""
echo "=== Starting eNB2 on PC2 ==="
gnome-terminal --title="eNB2 (PC2)" -- bash -c "sshpass -p '1234' ssh -t f2g@192.168.1.101 'sudo srsenb /tmp/enb2_handover.conf'; exec bash"

echo ""
echo "=== Lab Started ==="
echo "1. Wait for 'Number of eNBs is now 2' in MME logs"
echo "2. Power on phones"
echo "3. Make VoLTE call"
echo "4. Move phone to trigger handover"
```

---

## Shutdown Procedure

```bash
# 1. Stop eNBs (Ctrl+C in each terminal)

# 2. Stop Core
cd /home/f2g/Telecom/Core-Network/openimss
docker-compose down

# 3. Save Wireshark capture before closing
```

---

*Document created: 2026-10-01*  
*Lab: F2G TelcoLab — S1 Handover VoLTE*

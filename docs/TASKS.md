# S1 Handover VoLTE Lab — Tasks

**Ordered work items for complete deployment**

---

## Phase 1: Infrastructure Setup

### Task 1.1: Prepare PC1 (eNB1 Host)

**Goal:** PC1 ready to run srsENB.

**Files:**
- None created. System configuration only.

**Steps:**
1. Install Ubuntu 22.04 LTS.
2. Set static IP: 192.168.1.100.
3. Install build dependencies.
4. Compile srsRAN from source.
5. Connect bladeRF xA4 via USB 3.0.
6. Verify bladeRF detection.

**Commands:**
```bash
sudo apt update
sudo apt install -y build-essential cmake libfftw3-dev \
  libmbedtls-dev libboost-program-options-dev \
  libconfig++-dev libsctp-dev libbladerf-dev

git clone https://github.com/srsran/srsRAN_4G.git
cd srsRAN_4G && mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install

bladeRF-cli -p
```

**Verify:** `bladeRF-cli -p` shows device serial number.

---

### Task 1.2: Prepare PC2 (eNB2 Host)

**Goal:** PC2 ready to run srsENB.

**Steps:** Same as Task 1.1 with IP 192.168.1.101.

**Verify:** `bladeRF-cli -p` shows device serial number.

---

### Task 1.3: Deploy Core Network

**Goal:** Open5GS and IMS running on Docker.

**Files:**
- docker-compose.yaml (from VoicenterTeam/openimss)
- mme/mme.yaml (modified)

**Steps:**
1. Clone VoicenterTeam/openimss repository.
2. Edit mme/mme.yaml. Set `s1ap.addr` to 192.168.1.102. Set `tai.tac` to 1.
3. Run docker-compose up -d.
4. Create macvlan network.
5. Connect MME to macvlan with IP 192.168.1.102.

**Commands:**
```bash
git clone https://github.com/VoicenterTeam/openimss.git
cd openimss

# Edit mme/mme.yaml
docker-compose up -d

docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 macvlan_net

docker network connect macvlan_net mme --ip 192.168.1.102
```

**Verify:** `docker ps` shows 12 containers running.

---

## Phase 2: Subscriber Configuration

### Task 2.1: Add Subscriber 1001

**Goal:** Subscriber 1001 exists in HSS.

**Data:**
```
IMSI: 001010000123451
MSISDN: 1001
K: 465B5CE8B199B49FAA5F0A2EE238A6BC
OPC: E8ED289DEBA952E4283B54E88E6183CA
```

**Steps:**
1. Open http://localhost:3000 (Open5GS web UI).
2. Add new subscriber with above values.
3. Add APN "internet" with QCI 9.
4. Add APN "ims" with QCI 5.

**Verify:** Subscriber appears in subscriber list.

---

### Task 2.2: Add Subscriber 1099

**Goal:** Subscriber 1099 exists in HSS.

**Data:**
```
IMSI: 001010000099901
MSISDN: 1099
K: 465B5CE8B199B49FAA5F0A2EE238A6BC
OPC: E8ED289DEBA952E4283B54E88E6183CA
```

**Steps:** Same as Task 2.1 with above values.

**Verify:** Subscriber appears in subscriber list.

---

### Task 2.3: Program SIM Cards

**Goal:** Two SIM cards contain correct credentials.

**Steps:**
1. Use pySim or similar tool.
2. Write IMSI, K, OPC to each SIM.
3. Insert SIMs into phones.

**Commands:**
```bash
pySim-prog.py -p 0 -t sysmoISIM-SJA2 \
  -i 001010000123451 \
  -k 465B5CE8B199B49FAA5F0A2EE238A6BC \
  --op=E8ED289DEBA952E4283B54E88E6183CA
```

**Verify:** Phone shows network name after boot.

---

## Phase 3: eNodeB Configuration

### Task 3.1: Create eNB1 Config Files

**Goal:** eNB1 config files exist with handover enabled.

**Files to create:**
- /tmp/enb1_handover.conf
- /tmp/rr_enb1_ho.conf

**Critical values:**
```
enb_id = 0x19B
tac = 0x0001
pci = 1
dl_earfcn = 1450
ho_active = true
meas_cell_list: eci = 0x19C01, pci = 2
```

**Verify:** `grep -E "tac|ho_active|pci" /tmp/rr_enb1_ho.conf` shows correct values.

---

### Task 3.2: Create eNB2 Config Files

**Goal:** eNB2 config files exist with handover enabled.

**Files to create:**
- /tmp/enb2_handover.conf
- /tmp/rr_enb2_ho.conf

**Critical values:**
```
enb_id = 0x19C
tac = 0x0001       # Same as eNB1
pci = 2            # Different from eNB1
dl_earfcn = 1450   # Same as eNB1
ho_active = true
meas_cell_list: eci = 0x19B01, pci = 1
```

**Verify:** `grep tac /tmp/rr_enb2_ho.conf` shows 0x0001.

---

### Task 3.3: Copy Config to PC2

**Goal:** eNB2 config files exist on PC2.

**Commands:**
```bash
scp /tmp/enb2_handover.conf f2g@192.168.1.101:/tmp/
scp /tmp/rr_enb2_ho.conf f2g@192.168.1.101:/tmp/
scp sib.conf rb.conf f2g@192.168.1.101:/tmp/
```

**Verify:** Files exist on PC2.

---

## Phase 4: System Startup

### Task 4.1: Start eNB1

**Goal:** eNB1 connects to MME.

**Command:**
```bash
cd /tmp
sudo srsenb enb1_handover.conf
```

**Verify:** MME log shows "Number of eNBs is now 1".

---

### Task 4.2: Start eNB2

**Goal:** eNB2 connects to MME.

**Command (on PC2):**
```bash
cd /tmp
sudo srsenb enb2_handover.conf
```

**Verify:** MME log shows "Number of eNBs is now 2".

---

### Task 4.3: Attach UE 1001

**Goal:** Phone 1001 attaches to network and registers IMS.

**Steps:**
1. Enable airplane mode on phone.
2. Disable airplane mode.
3. Wait for LTE indicator.
4. Wait for VoLTE indicator.

**Verify:**
```bash
docker logs mme 2>&1 | grep "001010000123451.*Attach complete"
docker logs scscf 2>&1 | grep "1001.*registered"
```

---

### Task 4.4: Attach UE 1099

**Goal:** Phone 1099 attaches to network and registers IMS.

**Steps:** Same as Task 4.3 for second phone.

**Verify:**
```bash
docker logs mme 2>&1 | grep "001010000099901.*Attach complete"
docker logs scscf 2>&1 | grep "1099.*registered"
```

---

## Phase 5: VoLTE Testing

### Task 5.1: Make Test Call

**Goal:** VoLTE call connects between 1001 and 1099.

**Steps:**
1. From phone 1001, dial 1099.
2. Answer on phone 1099.
3. Verify bidirectional audio.

**Verify:** Both parties hear each other.

---

### Task 5.2: Test Handover

**Goal:** Call continues during handover.

**Steps:**
1. Start call between 1001 and 1099.
2. Start MME log monitoring.
3. Move phone closer to the other eNB.
4. Observe handover in logs.
5. Verify call continues.

**Monitor command:**
```bash
docker logs -f mme 2>&1 | grep -iE "Handover|CellID|StatusTransfer"
```

**Verify:** Logs show HandoverRequest and MMEStatusTransfer. Call audio continues.

---

## Task Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 1 | 1.1-1.3 | Infrastructure setup |
| 2 | 2.1-2.3 | Subscriber configuration |
| 3 | 3.1-3.3 | eNodeB configuration |
| 4 | 4.1-4.4 | System startup |
| 5 | 5.1-5.2 | Testing |

**Total:** 12 tasks

**Estimated time:** 2-4 hours (assuming hardware available)

---

*Complete these tasks in order. Each task depends on previous tasks.*

# 05 — Handover Testing

## Pre-checks

Before testing the handover, verify:

### 1. Both eNBs are connected to MME

```bash
docker logs mme 2>&1 | grep "Number of eNBs"
# [Added] Number of eNBs is now 2
```

### 2. UEs are attached

```bash
docker logs mme 2>&1 | grep "Attach complete" | tail -2
# [001010000123451] Attach complete
# [001010000099901] Attach complete
```

### 3. UEs are IMS registered

```bash
docker logs scscf 2>&1 | grep -i "registered" | tail -4
# State: [registered]
```

### 4. Identify which cell each UE is on

```bash
docker logs mme 2>&1 | grep "CellID" | tail -5
# TAC[1] CellID[0x19b01]  <- eNB1
# TAC[1] CellID[0x19c01]  <- eNB2
```

## Test Procedure

### Step 1: Start log monitoring

```bash
# Terminal 1 — MME Handover logs
docker logs -f --since 1s mme 2>&1 | grep -iE "Handover|CellID|StatusTransfer"
```

### Step 2: Make a VoLTE call

1. On phone 1001, call **1099**
2. Wait for the call to be established (bidirectional audio)

### Step 3: Trigger the Handover

**Option A: Physical movement**
- Move the phone away from the source eNB
- Move the phone closer to the target eNB

**Option B: Signal attenuation**
- Use an RF attenuator
- Reduce the TX gain of the source eNB

### Step 4: Observe the logs

## Expected Log Sequence (MME)

```
# 1. Handover initiated
HandoverRequest
    Source : ENB_UE_S1AP_ID[X] MME_UE_S1AP_ID[Y]
    Target : ENB_UE_S1AP_ID[Unknown] MME_UE_S1AP_ID[Z]

# 2. Status transfer
MMEStatusTransfer

# 3. UE is now on the new cell
# (Optional in MME logs)
UE Context Release
```

### Real Log Example

```
15:04:10.520: HandoverRequest
15:04:10.520:     Source : ENB_UE_S1AP_ID[119] MME_UE_S1AP_ID[127]
15:04:10.520:     Target : ENB_UE_S1AP_ID[Unknown] MME_UE_S1AP_ID[128]
15:04:10.523: MMEStatusTransfer
```

## Success Verification

### 1. Call remains connected

- ✅ Audio continues without interruption
- ✅ No disconnect tone

### 2. UE is on the new cell

```bash
docker logs mme 2>&1 | grep "CellID" | tail -1
# Should show the new CellID
```

### 3. Wireshark (optional)

```bash
# Capture S1AP
sudo wireshark -i any -k -f 'sctp port 36412'

# Useful filters
s1ap.procedureCode == 0   # HandoverRequest
s1ap.procedureCode == 1   # HandoverRequired
```

## Round-trip Test

For a complete test, perform handover in both directions:

```
eNB1 → eNB2 (first handover)
eNB2 → eNB1 (return handover)
```

The call must remain connected during both handovers.

## Metrics to Collect

| Metric | Expected Value | How to Measure |
|--------|----------------|----------------|
| Handover duration | < 100 ms | Log timestamps |
| Packet loss | 0-2 | Wireshark |
| Audio interruption | < 50 ms | Perception |
| Success rate | > 95% | Repeat 20x |

## PCAP Capture

For later analysis:

```bash
# Start capture
sudo tcpdump -i any -w handover_test.pcap \
  'sctp port 36412 or udp port 2152 or port 5060'

# Run the test

# Stop capture (Ctrl+C)
```

## Automated Test Script

```bash
#!/bin/bash
# test_handover.sh

echo "=== Starting Handover Test ==="
echo "Timestamp: $(date)"

# Monitor logs for 60 seconds
timeout 60 docker logs -f --since 1s mme 2>&1 | \
  grep -iE "Handover|CellID|StatusTransfer" | \
  tee handover_test_$(date +%Y%m%d_%H%M%S).log

echo "=== Test Complete ==="
```

---

➡️ **Next Step**: [06-TROUBLESHOOTING.md](06-TROUBLESHOOTING.md)

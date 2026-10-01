# 06 — Troubleshooting

## Common Issues and Solutions

### 1. No Handover Triggered

#### Symptom
UE stays on the same cell despite movement.

#### Causes and Solutions

| Cause | Diagnosis | Solution |
|-------|-----------|----------|
| Different TAC | `grep tac rr*.conf` | Set same TAC on both eNBs |
| ho_active = false | `grep ho_active rr*.conf` | Set `ho_active = true` |
| Empty meas_cell_list | Check config | Add neighbor cell |
| Different EARFCN | Check dl_earfcn | Same frequency on both eNBs |
| Signal too strong | RSRP > -70 dBm | Move UE away or reduce TX |

#### Diagnostic Command

```bash
# Check config on both eNBs
grep -E "tac|ho_active|dl_earfcn|pci" /tmp/rr_enb1_ho.conf
grep -E "tac|ho_active|dl_earfcn|pci" /tmp/rr_enb2_ho.conf
```

### 2. Handover Cancel

#### Symptom
```
WARNING: Action: S1 handover cancel
```

#### Causes and Solutions

| Cause | Solution |
|-------|----------|
| Timeout | Increase `a3_time_to_trigger` (e.g., 640 ms) |
| Unstable signal | Increase `a3_hysteresis` (e.g., 2) |
| Target unreachable | Verify target eNB is up |
| PCI collision | Verify different PCIs |

### 3. Call Drops After Handover

#### Symptom
Handover succeeds but VoLTE call disconnects.

#### Causes and Solutions

| Cause | Diagnosis | Solution |
|-------|-----------|----------|
| IMS bearer lost | MME logs `EBI=6` | Check QoS config |
| IMS re-registration | P-CSCF logs | Check IPsec |
| RTP path broken | Wireshark | Check RTPEngine |

#### Diagnostic

```bash
# Check IMS bearer
docker logs mme 2>&1 | grep -iE "EBI=6|ims" | tail -10

# Check IMS after handover
docker logs pcscf 2>&1 | grep -iE "error|failed" | tail -10
```

### 4. UE Doesn't See Neighbor Cell

#### Symptom
Phone only detects one cell.

#### Causes and Solutions

| Cause | Solution |
|-------|----------|
| Same PCI | Set different PCIs |
| Identical root_seq_idx | Set different values |
| Signal too weak | Increase TX gain |
| Misaligned antenna | Check antennas |

### 5. eNB Doesn't Connect to MME

#### Symptom
```
S1 Setup procedure failed
```

#### Diagnostic

```bash
# Check connectivity
ping 192.168.1.102

# Check S1AP port
nc -zv 192.168.1.102 36412

# Check MME logs
docker logs mme 2>&1 | grep -iE "error|refused"
```

#### Solutions

| Cause | Solution |
|-------|----------|
| Wrong IP | Check `mme_addr` in enb.conf |
| Firewall | `sudo ufw allow 36412` |
| MME down | `docker restart mme` |
| PLMN mismatch | Check MCC/MNC |

### 6. TAU Instead of Handover

#### Symptom
UE performs Tracking Area Update instead of Handover.

#### Cause
Different TAC on the 2 eNBs.

#### Solution

```bash
# On PC2, fix the TAC
sed -i 's/tac = 0x0002/tac = 0x0001/' /tmp/rr_enb2_ho.conf

# Restart eNB2
sudo pkill srsenb
sudo srsenb /tmp/enb2_handover.conf
```

## Diagnostic Commands

### Real-time Logs

```bash
# MME - Handover
docker logs -f mme 2>&1 | grep -iE "Handover|CellID"

# MME - All S1AP events
docker logs -f mme 2>&1 | grep -iE "S1AP|eNB"

# P-CSCF - SIP
docker logs -f pcscf 2>&1 | grep -iE "INVITE|BYE|REGISTER"

# eNB - RRC
tail -f /tmp/enb1.log | grep -iE "RRC|Handover"
```

### System Status

```bash
# Connected eNBs
docker logs mme 2>&1 | grep "Number of eNBs" | tail -1

# Attached UEs
docker logs mme 2>&1 | grep "Attach complete" | tail -5

# IMS registrations
docker logs scscf 2>&1 | grep "registered" | tail -5
```

### Network Capture

```bash
# S1AP only
sudo tcpdump -i any -w s1ap.pcap 'sctp port 36412'

# All telecom traffic
sudo tcpdump -i any -w telecom.pcap \
  'sctp or udp port 2152 or port 5060'
```

## Debug Checklist

```
□ Are both eNBs connected to MME?
□ Is TAC identical on both eNBs?
□ Is PCI different on both eNBs?
□ Is EARFCN identical?
□ Is ho_active = true?
□ Is meas_cell_list configured?
□ Does UE see both cells?
□ Is UE IMS registered?
□ Does VoLTE call work without handover?
```

## Resources and Contacts

- **Open5GS Issues**: https://github.com/open5gs/open5gs/issues
- **srsRAN Issues**: https://github.com/srsran/srsRAN_4G/issues
- **3GPP TS 23.401**: S1 Handover procedures
- **3GPP TS 36.413**: S1AP specification

---

⬅️ **Back**: [05-HANDOVER-TESTING.md](05-HANDOVER-TESTING.md)

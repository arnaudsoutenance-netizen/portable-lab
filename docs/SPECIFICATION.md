# S1 Handover VoLTE Lab — Specification

**Complete Private LTE Network with Intra-Frequency Handover**

|                |                                                        |
| -------------- | ------------------------------------------------------ |
| **Status**     | Tested and Validated                                   |
| **Owner**      | F2G Telecom Lab                                        |
| **Scope**      | S1 Handover during active VoLTE calls                  |
| **Audience**   | Telecom engineers, lab operators, researchers          |

---

## 1. Summary

This project implements S1-based handover on a private LTE network. Two physical eNodeBs connect to one Open5GS core with IMS. A phone moves between cells during a VoLTE call without audio interruption.

## 2. Goals

1. **Seamless mobility.** The UE changes cells during an active call. The call continues.
2. **Intra-frequency operation.** Both cells use EARFCN 1450. The UE measures neighbor signal strength.
3. **Real hardware.** bladeRF xA4 SDRs transmit actual RF. No simulation.
4. **VoLTE end-to-end.** IMS registration, SIP INVITE, RTP media — all functional.

## 3. Non-Goals

- X2 handover (direct eNB-to-eNB). This project uses S1 handover through the MME.
- Inter-frequency handover. Both cells share the same frequency.
- Multi-operator roaming. One PLMN (001/01) only.
- Commercial deployment. This is a lab for testing and learning.

## 4. Architecture

```
+-------------------+                 +-------------------+
|       PC1         |                 |       PC2         |
|   192.168.1.100   |                 |   192.168.1.101   |
|                   |                 |                   |
|  +-------------+  |                 |  +-------------+  |
|  |   srsENB    |  |                 |  |   srsENB    |  |
|  |   (eNB1)    |  |                 |  |   (eNB2)    |  |
|  |             |  |                 |  |             |  |
|  | PCI=1       |  |                 |  | PCI=2       |  |
|  | TAC=0x0001  |  |                 |  | TAC=0x0001  |  |
|  | ECI=0x19B01 |  |                 |  | ECI=0x19C01 |  |
|  +------+------+  |                 |  +------+------+  |
|         |         |                 |         |         |
|  +------+------+  |                 |  +------+------+  |
|  |  bladeRF    |  |      RF         |  |  bladeRF    |  |
|  |    xA4      |<-+---------------->+->|    xA4      |  |
|  +-------------+  |                 |  +-------------+  |
+--------+----------+                 +--------+----------+
         |          S1AP / GTP-U               |
         +------------------+------------------+
                            |
                    +-------+-------+
                    |    Open5GS    |
                    | 192.168.1.102 |
                    |   MME / HSS   |
                    |   SGW / PGW   |
                    +-------+-------+
                            |
                    +-------+-------+
                    |   IMS Core    |
                    |   Kamailio    |
                    |  P/I/S-CSCF   |
                    |  RTPEngine    |
                    +---------------+
```

## 5. Components

### 5.1 Hardware

| Item | Quantity | Purpose |
|------|----------|---------|
| Linux PC | 2 | Run srsENB |
| bladeRF xA4 | 2 | RF transmission |
| TX/RX antenna | 4 | 700-2700 MHz |
| USB 3.0 cable | 2 | SDR connection |
| Ethernet switch | 1 | Network connectivity |
| VoLTE phone | 2 | Test endpoints |
| Programmable SIM | 2 | USIM credentials |

### 5.2 Software

| Component | Version | Role |
|-----------|---------|------|
| Ubuntu | 22.04 LTS | Operating system |
| srsRAN | 23.11+ | eNodeB software |
| Open5GS | 2.7+ | EPC core network |
| Kamailio | 5.7+ | IMS signaling |
| RTPEngine | Latest | Media relay |
| Docker | 24+ | Container runtime |

## 6. Network Plan

### 6.1 IP Addresses

| Device | IP Address | Network |
|--------|------------|---------|
| PC1 (eNB1) | 192.168.1.100 | Physical LAN |
| PC2 (eNB2) | 192.168.1.101 | Physical LAN |
| MME | 192.168.1.102 | macvlan |
| Docker bridge | 172.22.0.0/24 | Internal |

### 6.2 Cell Parameters

| Parameter | eNB1 | eNB2 | Rule |
|-----------|------|------|------|
| enb_id | 0x19B | 0x19C | Different |
| cell_id | 0x01 | 0x01 | Any |
| ECI | 0x19B01 | 0x19C01 | Different |
| TAC | 0x0001 | 0x0001 | **Identical** |
| PCI | 1 | 2 | Different |
| EARFCN | 1450 | 1450 | **Identical** |

## 7. Subscribers

### 7.1 Phone 1

```
IMSI:   001010000123451
MSISDN: 1001
K:      465B5CE8B199B49FAA5F0A2EE238A6BC
OPC:    E8ED289DEBA952E4283B54E88E6183CA
AMF:    8000
```

### 7.2 Phone 2

```
IMSI:   001010000099901
MSISDN: 1099
K:      465B5CE8B199B49FAA5F0A2EE238A6BC
OPC:    E8ED289DEBA952E4283B54E88E6183CA
AMF:    8000
```

### 7.3 APN Configuration

| APN | Type | QCI |
|-----|------|-----|
| internet | default,supl | 9 |
| ims | ims | 5 |

## 8. Success Criteria

| Criterion | Measurement | Target |
|-----------|-------------|--------|
| eNB connection | MME log shows 2 eNBs | Both connected |
| UE attachment | Attach complete message | 100% |
| IMS registration | S-CSCF shows "registered" | Both UEs |
| VoLTE call | Bidirectional audio | Established |
| Handover trigger | A3 event in logs | Detected |
| Handover complete | MMEStatusTransfer | Success |
| Call continuity | No audio drop | Maintained |

## 9. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| TAC mismatch | TAU instead of HO | Verify TAC = 0x0001 on both |
| PCI collision | UE confusion | Use different PCIs |
| Weak signal | No handover trigger | Adjust TX gain or position |
| IMS deregistration | Call drops after HO | Check IPsec and Diameter |

## 10. References

| Document | Description |
|----------|-------------|
| 3GPP TS 23.401 | S1 Handover procedures |
| 3GPP TS 36.413 | S1AP specification |
| 3GPP TS 36.331 | RRC measurement configuration |
| 3GPP TS 24.229 | IMS SIP procedures |

---

*This specification describes what the system does. See IMPLEMENTATION.md for how to build it.*

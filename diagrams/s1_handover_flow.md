# S1 Handover Sequence Diagram

## Sequence Diagram (Mermaid)

```mermaid
sequenceDiagram
    participant UE
    participant eNB_Source as Source eNB
    participant MME
    participant eNB_Target as Target eNB
    participant SGW as SGW/PGW

    Note over UE,SGW: Phase 1: Preparation

    UE->>eNB_Source: Measurement Report (A3 Event)
    Note right of UE: RSRP target > RSRP source + offset

    eNB_Source->>MME: Handover Required
    Note right of eNB_Source: S1AP: cause, target cell ID

    MME->>eNB_Target: Handover Request
    Note right of MME: UE context, bearers info

    eNB_Target->>eNB_Target: Allocate resources
    Note right of eNB_Target: RNTI, DRB, SRB

    eNB_Target->>MME: Handover Request Acknowledge
    Note right of eNB_Target: Target to Source Container

    Note over UE,SGW: Phase 2: Execution

    MME->>eNB_Source: Handover Command
    Note right of MME: RRC Container

    eNB_Source->>UE: RRC Connection Reconfiguration
    Note right of eNB_Source: Mobility Control Info

    eNB_Source->>MME: eNB Status Transfer
    Note right of eNB_Source: PDCP SN status

    MME->>eNB_Target: MME Status Transfer
    Note right of MME: Forward PDCP status

    Note over UE,SGW: Phase 3: Completion

    UE->>eNB_Target: RRC Connection Reconfiguration Complete
    Note right of UE: Synchronization

    eNB_Target->>MME: Handover Notify
    Note right of eNB_Target: TAI, ECGI

    MME->>SGW: Modify Bearer Request
    Note right of MME: Update S1-U tunnel

    SGW->>MME: Modify Bearer Response

    MME->>eNB_Source: UE Context Release Command

    eNB_Source->>MME: UE Context Release Complete
    Note right of eNB_Source: Resources released

    Note over UE,SGW: ✅ Handover Complete
```

## S1AP Messages

### HandoverRequired (Source eNB → MME)

| IE | Description |
|----|-------------|
| MME-UE-S1AP-ID | UE ID on MME side |
| eNB-UE-S1AP-ID | UE ID on eNB side |
| Cause | Handover reason (radio, resource, etc.) |
| Target ID | Target cell (TAI + ECGI) |
| Source-ToTarget-TransparentContainer | RRC context |

### HandoverRequest (MME → Target eNB)

| IE | Description |
|----|-------------|
| MME-UE-S1AP-ID | UE ID on MME side |
| Handover Type | intraLTE, LTEtoUTRAN, etc. |
| Cause | Handover reason |
| UE Aggregate Maximum Bit Rate | QoS |
| E-RAB To Be Setup List | Bearers to establish |
| Source-ToTarget-TransparentContainer | RRC context |
| Security Context | Keys, algorithms |

### HandoverRequestAcknowledge (Target eNB → MME)

| IE | Description |
|----|-------------|
| MME-UE-S1AP-ID | UE ID on MME side |
| eNB-UE-S1AP-ID | New ID assigned by target eNB |
| E-RAB Admitted List | Accepted bearers |
| Target-ToSource-TransparentContainer | RRC HO Command |

### MMEStatusTransfer (MME → Target eNB)

| IE | Description |
|----|-------------|
| eNB Status Transfer | PDCP SN status (UL/DL) |

### HandoverNotify (Target eNB → MME)

| IE | Description |
|----|-------------|
| MME-UE-S1AP-ID | UE ID |
| TAI | Tracking Area Identity |
| EUTRAN-CGI | Cell Global Identity |

## 3GPP Timers

| Timer | Default Value | Description |
|-------|---------------|-------------|
| TS1RELOCprep | 10s | Handover preparation |
| TS1RELOCoverall | 20s | Total handover duration |
| TRELOCprep | 1s | At eNB level |

## Measurement Events (A3)

### A3 Configuration

```
A3 Event: Neighbour > Serving + Offset
```

| Parameter | Typical Value | Description |
|-----------|---------------|-------------|
| a3_offset | 6 dB | Trigger margin |
| a3_hysteresis | 0-3 dB | Prevents ping-pong |
| time_to_trigger | 480 ms | Delay before trigger |
| report_type | RSRP | Measured metric |

### Trigger Formula

```
Mn + Ofn + Ocn - Hys > Ms + Ofs + Ocs + Off

Where:
  Mn = Neighbor measurement
  Ms = Serving measurement
  Ofn/Ofs = Frequency offset
  Ocn/Ocs = Cell offset
  Hys = Hysteresis
  Off = A3 Offset
```

## 3GPP References

- **TS 23.401** § 5.5.1 — S1-based Handover
- **TS 36.413** § 8.4 — Handover Signalling
- **TS 36.331** § 5.5.4 — Measurement Configuration
- **TS 36.133** § 8.1.2 — A3 Event Requirements

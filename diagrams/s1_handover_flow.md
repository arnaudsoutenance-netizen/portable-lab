# S1 Handover Sequence Diagram

## Diagramme de séquence (Mermaid)

```mermaid
sequenceDiagram
    participant UE
    participant eNB_Source as eNB Source
    participant MME
    participant eNB_Target as eNB Target
    participant SGW as SGW/PGW

    Note over UE,SGW: Phase 1: Préparation

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

    Note over UE,SGW: Phase 2: Exécution

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
    Note right of UE: Synchronisation

    eNB_Target->>MME: Handover Notify
    Note right of eNB_Target: TAI, ECGI

    MME->>SGW: Modify Bearer Request
    Note right of MME: Update S1-U tunnel

    SGW->>MME: Modify Bearer Response

    MME->>eNB_Source: UE Context Release Command

    eNB_Source->>MME: UE Context Release Complete
    Note right of eNB_Source: Resources libérées

    Note over UE,SGW: ✅ Handover Complete
```

## Messages S1AP

### HandoverRequired (eNB Source → MME)

| IE | Description |
|----|-------------|
| MME-UE-S1AP-ID | ID de l'UE côté MME |
| eNB-UE-S1AP-ID | ID de l'UE côté eNB |
| Cause | Raison du handover (radio, resource, etc.) |
| Target ID | Cellule cible (TAI + ECGI) |
| Source-ToTarget-TransparentContainer | RRC context |

### HandoverRequest (MME → eNB Target)

| IE | Description |
|----|-------------|
| MME-UE-S1AP-ID | ID de l'UE côté MME |
| Handover Type | intraLTE, LTEtoUTRAN, etc. |
| Cause | Raison du handover |
| UE Aggregate Maximum Bit Rate | QoS |
| E-RAB To Be Setup List | Bearers à établir |
| Source-ToTarget-TransparentContainer | RRC context |
| Security Context | Keys, algorithms |

### HandoverRequestAcknowledge (eNB Target → MME)

| IE | Description |
|----|-------------|
| MME-UE-S1AP-ID | ID de l'UE côté MME |
| eNB-UE-S1AP-ID | Nouvel ID assigné par eNB target |
| E-RAB Admitted List | Bearers acceptés |
| Target-ToSource-TransparentContainer | RRC HO Command |

### MMEStatusTransfer (MME → eNB Target)

| IE | Description |
|----|-------------|
| eNB Status Transfer | PDCP SN status (UL/DL) |

### HandoverNotify (eNB Target → MME)

| IE | Description |
|----|-------------|
| MME-UE-S1AP-ID | ID UE |
| TAI | Tracking Area Identity |
| EUTRAN-CGI | Cell Global Identity |

## Timers 3GPP

| Timer | Valeur par défaut | Description |
|-------|-------------------|-------------|
| TS1RELOCprep | 10s | Préparation handover |
| TS1RELOCoverall | 20s | Durée totale handover |
| TRELOCprep | 1s | Au niveau eNB |

## Événements de mesure (A3)

### Configuration A3

```
A3 Event: Neighbour > Serving + Offset
```

| Paramètre | Valeur typique | Description |
|-----------|----------------|-------------|
| a3_offset | 6 dB | Marge de déclenchement |
| a3_hysteresis | 0-3 dB | Évite le ping-pong |
| time_to_trigger | 480 ms | Durée avant déclenchement |
| report_type | RSRP | Métrique mesurée |

### Formule de déclenchement

```
Mn + Ofn + Ocn - Hys > Ms + Ofs + Ocs + Off

Où:
  Mn = Mesure voisin
  Ms = Mesure serveur
  Ofn/Ofs = Offset fréquence
  Ocn/Ocs = Offset cellule
  Hys = Hysteresis
  Off = A3 Offset
```

## Références 3GPP

- **TS 23.401** § 5.5.1 — S1-based Handover
- **TS 36.413** § 8.4 — Handover Signalling
- **TS 36.331** § 5.5.4 — Measurement Configuration
- **TS 36.133** § 8.1.2 — A3 Event Requirements

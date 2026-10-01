# 📡 SESSION HANDOVER S1 — LAB F2G VOLTE
**Date:** 2026-10-01
**Statut:** ✅ FONCTIONNEL

---

## 🎯 OBJECTIF ATTEINT
Faire fonctionner les appels VoLTE entre 2 UE sur un lab LTE avec 2 eNB physiques (PC1 et PC2 avec bladeRF) avec S1 Handover intra-frequency.

---

## 📊 ARCHITECTURE FINALE

### Réseau Physique
```
PC1 (192.168.1.100) eNB1 ─┐
  eNB_ID: 0x19B            │
  PCI: 1, TAC: 0x0001      ├─► MME (macvlan 192.168.1.102)
  EARFCN: 1450             │
  ho_active: true          │
                           │
PC2 (192.168.1.101) eNB2 ─┘
  eNB_ID: 0x19C
  PCI: 2, TAC: 0x0001  ← CORRIGÉ (était 0x0002)
  EARFCN: 1450
  ho_active: true
```

### Docker Network (172.22.0.0/24)
| Container | IP | Rôle |
|-----------|-----|------|
| mme | 172.22.0.9 + macvlan 192.168.1.102 | MME |
| hss | 172.22.0.3 | HSS |
| pcrf | 172.22.0.4 | PCRF |
| sgwc/sgwu | 172.22.0.5/6 | SGW |
| smf/upf | 172.22.0.7/8 | SMF/UPF |
| icscf | 172.22.0.19 | I-CSCF |
| scscf | 172.22.0.20 | S-CSCF |
| pcscf | 172.22.0.21 | P-CSCF |
| rtpengine | 172.22.0.16 | RTPEngine |
| asterisk | 172.22.0.23 | PSTN Gateway |

### Subscribers
| IMSI | MSISDN | Téléphone |
|------|--------|-----------|
| 001010000123451 | 1001 | UE1 |
| 001010000099901 | 1099 | UE2 |

---

## ✅ CORRECTIONS EFFECTUÉES

### 1. TAC eNB2 corrigé
**Problème:** eNB2 avait TAC=0x0002, différent de eNB1 (TAC=0x0001)
**Impact:** Les UE faisaient des TAU au lieu de handover
**Solution:**
```bash
# Sur PC2
sed -i 's/tac = 0x0002/tac = 0x0001/' /tmp/rr_enb2_ho.conf
# Redémarrer eNB2
sudo pkill srsenb && sudo srsenb /tmp/enb2_handover.conf
```

### 2. SIP OPTIONS 398 corrigé (session précédente)
**Problème:** S-CSCF envoyait OPTIONS vers 192.168.1.155 (ancien gateway)
**Solution:**
```bash
docker exec scscf sh -c "cat > /etc/kamailio_scscf/dispatcher.list << 'EOF'
# PSTN Gateway / Asterisk
1 sip:172.22.0.23:5060
EOF"
docker exec scscf kamcmd dispatcher.reload
```

---

## 📁 FICHIERS DE CONFIGURATION

### PC1 (eNB1)
- Config principale: `/tmp/enb1_handover.conf`
- Config RR: `/tmp/rr_enb1_ho.conf`

### PC2 (eNB2)
- Config principale: `/tmp/enb2_handover.conf`
- Config RR: `/tmp/rr_enb2_ho.conf`

### Configs de référence (sauvegardées)
- `/home/f2g/Desktop/S1_Handover_Config/enb1.conf`
- `/home/f2g/Desktop/S1_Handover_Config/enb2.conf`
- `/home/f2g/Desktop/S1_Handover_Config/rr1.conf`
- `/home/f2g/Desktop/S1_Handover_Config/rr2.conf`

---

## 🔧 CONFIG RR HANDOVER (rr_enb1_ho.conf)

```
cell_list =
(
  {
    cell_id = 0x01;
    tac = 0x0001;
    pci = 1;
    root_seq_idx = 204;
    dl_earfcn = 1450;

    ho_active = true;
    meas_cell_list =
    (
      { eci = 0x19C01; dl_earfcn = 1450; pci = 2; }
    );
    meas_report_desc =
    {
      a3_report_type = "RSRP";
      a3_offset = 6;
      a3_hysteresis = 0;
      a3_time_to_trigger = 480;
    };
  }
);
```

### Config RR eNB2 (rr_enb2_ho.conf)
```
cell_list =
(
  {
    cell_id = 0x01;
    tac = 0x0001;  # CORRIGÉ - était 0x0002
    pci = 2;
    root_seq_idx = 205;
    dl_earfcn = 1450;

    ho_active = true;
    meas_cell_list =
    (
      { eci = 0x19B01; dl_earfcn = 1450; pci = 1; }
    );
    meas_report_desc =
    {
      a3_report_type = "RSRP";
      a3_offset = 6;
      a3_hysteresis = 0;
      a3_time_to_trigger = 480;
    };
  }
);
```

---

## 📡 SÉQUENCE S1 HANDOVER OBSERVÉE

```
1. HandoverRequired (eNB source → MME)
2. HandoverRequest (MME → eNB target)
3. HandoverRequestAcknowledge (eNB target → MME)
4. HandoverCommand (MME → eNB source)
5. MMEStatusTransfer (MME → eNB target)
6. HandoverNotify (eNB target → MME)
7. UE Context Release (MME → eNB source)
```

### Logs Handover observés
```
15:04:10 HandoverRequest
         Source: ENB_UE_S1AP_ID[119] MME_UE_S1AP_ID[127]
         Target: ENB_UE_S1AP_ID[Unknown] MME_UE_S1AP_ID[128]
         MMEStatusTransfer ✅

15:04:30 HandoverRequest
         Source: ENB_UE_S1AP_ID[21] MME_UE_S1AP_ID[128]
         Target: ENB_UE_S1AP_ID[Unknown] MME_UE_S1AP_ID[129]
         MMEStatusTransfer ✅
```

---

## 🛠️ COMMANDES UTILES

### Démarrage eNB
```bash
# PC1
sudo srsenb /tmp/enb1_handover.conf

# PC2
sudo srsenb /tmp/enb2_handover.conf
```

### Logs en temps réel
```bash
# Handover MME
docker logs -f mme 2>&1 | grep -iE "Handover|CellID|StatusTransfer"

# IMS Registration
docker logs -f scscf 2>&1 | grep -iE "registered|REGISTER"

# Appel VoLTE
docker logs -f pcscf 2>&1 | grep -iE "INVITE|BYE|200"
```

### Wireshark temps réel
```bash
# S1AP (Handover)
sudo wireshark -i any -k -f 'sctp port 36412'

# SIP/VoLTE
sudo wireshark -i any -k -f 'port 5060 or port 5061 or port 4070'

# Tout le trafic télécom
sudo wireshark -i any -k -f 'sctp or (udp port 2152) or (port 5060)'
```

### Vérifications
```bash
# eNB connectés
docker logs mme 2>&1 | grep "Number of eNBs"

# UE attachés
docker logs mme 2>&1 | grep "CellID" | tail -10

# IMS registration
docker logs scscf 2>&1 | grep -i "registered" | tail -5
```

---

## 📋 CHECKLIST FONCTIONNELLE

- [x] 2 eNB connectés au MME
- [x] UE attachés LTE (EBI=5)
- [x] Bearer IMS créé (EBI=6)
- [x] UE enregistrés IMS (state="active")
- [x] TAC identique sur les 2 eNB (0x0001)
- [x] ho_active = true sur les 2 eNB
- [x] meas_cell_list configurée (voisins)
- [x] HandoverRequest observé dans les logs
- [x] MMEStatusTransfer observé
- [x] Changement de CellID confirmé (0x19b01 ↔ 0x19c01)
- [ ] Appel VoLTE reste connecté pendant handover (à valider)

---

## 📚 DOCUMENTATION ASSOCIÉE

- `/home/f2g/Desktop/LAB_VOLTE_F2G_CONFIG.md` - Config VoLTE complète
- `/home/f2g/Desktop/volte-lab.sh` - Script de gestion
- `/home/f2g/Desktop/ARCHITECTURE_F2G_VOLTE_HANDOVER.md` - Architecture
- `/home/f2g/Desktop/S1_Handover_Config/` - Configs handover
- `/home/f2g/Desktop/COMPARAISON_REPOS_HANDOVER.md` - Analyse repos

---

## 🔗 RÉFÉRENCES 3GPP

- **TS 23.401** - GPRS enhancements for E-UTRAN access (S1 Handover)
- **TS 36.413** - S1 Application Protocol (S1AP)
- **TS 36.331** - RRC Protocol specification (Measurement Reports)
- **TS 23.228** - IP Multimedia Subsystem (IMS)
- **TS 24.229** - SIP procedures for IMS

---

## 📝 NOTES

1. Le TAC doit être IDENTIQUE sur tous les eNB pour un handover intra-TAC
2. L'EARFCN doit être identique pour un handover intra-frequency
3. Les PCI doivent être DIFFÉRENTS pour éviter la confusion
4. Le A3 event (a3_offset=6dB, time_to_trigger=480ms) déclenche le handover

---

*Session sauvegardée le 2026-10-01 à 16:06*
*Repo: VoicenterTeam/openimss*
*Path: /home/f2g/Telecom/Core-Network/openimss/*

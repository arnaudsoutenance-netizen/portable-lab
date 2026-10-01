# 06 — Troubleshooting

## Problèmes courants et solutions

### 1. Pas de Handover déclenché

#### Symptôme
L'UE reste sur la même cellule malgré le déplacement.

#### Causes et solutions

| Cause | Diagnostic | Solution |
|-------|------------|----------|
| TAC différent | `grep tac rr*.conf` | Mettre le même TAC sur les 2 eNB |
| ho_active = false | `grep ho_active rr*.conf` | Mettre `ho_active = true` |
| meas_cell_list vide | Vérifier config | Ajouter la cellule voisine |
| EARFCN différent | Vérifier dl_earfcn | Même fréquence sur les 2 eNB |
| Signal trop fort | RSRP > -70 dBm | Éloigner l'UE ou réduire TX |

#### Commande de diagnostic

```bash
# Vérifier la config des 2 eNB
grep -E "tac|ho_active|dl_earfcn|pci" /tmp/rr_enb1_ho.conf
grep -E "tac|ho_active|dl_earfcn|pci" /tmp/rr_enb2_ho.conf
```

### 2. Handover Cancel

#### Symptôme
```
WARNING: Action: S1 handover cancel
```

#### Causes et solutions

| Cause | Solution |
|-------|----------|
| Timeout | Augmenter `a3_time_to_trigger` (ex: 640 ms) |
| Signal instable | Augmenter `a3_hysteresis` (ex: 2) |
| Cible non joignable | Vérifier que eNB target est up |
| Collision PCI | Vérifier PCI différents |

### 3. Appel coupé après Handover

#### Symptôme
Le handover réussit mais l'appel VoLTE se coupe.

#### Causes et solutions

| Cause | Diagnostic | Solution |
|-------|------------|----------|
| Bearer IMS perdu | Logs MME `EBI=6` | Vérifier QoS config |
| Re-registration IMS | Logs P-CSCF | Vérifier IPsec |
| RTP path broken | Wireshark | Vérifier RTPEngine |

#### Diagnostic

```bash
# Vérifier le bearer IMS
docker logs mme 2>&1 | grep -iE "EBI=6|ims" | tail -10

# Vérifier IMS après handover
docker logs pcscf 2>&1 | grep -iE "error|failed" | tail -10
```

### 4. UE ne voit pas la cellule voisine

#### Symptôme
Le téléphone ne détecte qu'une seule cellule.

#### Causes et solutions

| Cause | Solution |
|-------|----------|
| Même PCI | Mettre PCI différents |
| root_seq_idx identique | Mettre des valeurs différentes |
| Signal trop faible | Augmenter TX gain |
| Antenne mal orientée | Vérifier antennes |

### 5. eNB ne se connecte pas au MME

#### Symptôme
```
S1 Setup procedure failed
```

#### Diagnostic

```bash
# Vérifier connectivité
ping 192.168.1.102

# Vérifier port S1AP
nc -zv 192.168.1.102 36412

# Vérifier logs MME
docker logs mme 2>&1 | grep -iE "error|refused"
```

#### Solutions

| Cause | Solution |
|-------|----------|
| IP incorrecte | Vérifier `mme_addr` dans enb.conf |
| Firewall | `sudo ufw allow 36412` |
| MME down | `docker restart mme` |
| PLMN mismatch | Vérifier MCC/MNC |

### 6. TAU au lieu de Handover

#### Symptôme
L'UE fait un Tracking Area Update au lieu d'un Handover.

#### Cause
TAC différent sur les 2 eNB.

#### Solution

```bash
# Sur PC2, corriger le TAC
sed -i 's/tac = 0x0002/tac = 0x0001/' /tmp/rr_enb2_ho.conf

# Redémarrer eNB2
sudo pkill srsenb
sudo srsenb /tmp/enb2_handover.conf
```

## Commandes de diagnostic

### Logs en temps réel

```bash
# MME - Handover
docker logs -f mme 2>&1 | grep -iE "Handover|CellID"

# MME - Tous les événements S1AP
docker logs -f mme 2>&1 | grep -iE "S1AP|eNB"

# P-CSCF - SIP
docker logs -f pcscf 2>&1 | grep -iE "INVITE|BYE|REGISTER"

# eNB - RRC
tail -f /tmp/enb1.log | grep -iE "RRC|Handover"
```

### État du système

```bash
# eNB connectés
docker logs mme 2>&1 | grep "Number of eNBs" | tail -1

# UE attachés
docker logs mme 2>&1 | grep "Attach complete" | tail -5

# IMS registrations
docker logs scscf 2>&1 | grep "registered" | tail -5
```

### Capture réseau

```bash
# S1AP uniquement
sudo tcpdump -i any -w s1ap.pcap 'sctp port 36412'

# Tout le trafic télécom
sudo tcpdump -i any -w telecom.pcap \
  'sctp or udp port 2152 or port 5060'
```

## Checklist de debug

```
□ Les 2 eNB sont connectés au MME ?
□ TAC identique sur les 2 eNB ?
□ PCI différent sur les 2 eNB ?
□ EARFCN identique ?
□ ho_active = true ?
□ meas_cell_list configurée ?
□ L'UE voit les 2 cellules ?
□ L'UE est enregistré IMS ?
□ L'appel VoLTE fonctionne sans handover ?
```

## Contacts et ressources

- **Open5GS Issues** : https://github.com/open5gs/open5gs/issues
- **srsRAN Issues** : https://github.com/srsran/srsRAN_4G/issues
- **3GPP TS 23.401** : S1 Handover procedures
- **3GPP TS 36.413** : S1AP specification

---

⬅️ **Retour** : [05-TEST-HANDOVER.md](05-TEST-HANDOVER.md)

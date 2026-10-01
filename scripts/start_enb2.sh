#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
#  F2G TelcoLab — Script de démarrage eNB2 (PC2 - 192.168.1.101)
#  S1 Handover Configuration
# ═══════════════════════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════════════════════════"
echo "  📡 Démarrage eNB2 (S1 Handover activé)"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
echo "  eNB ID:     0x19C"
echo "  Cell ID:    0x01"
echo "  PCI:        2"
echo "  TAC:        0x0001"
echo "  EARFCN:     1450"
echo "  MME:        192.168.1.102"
echo "  S1C bind:   192.168.1.101"
echo ""
echo "  Handover:   ACTIVÉ (ho_active=true)"
echo "  Neighbour:  eNB1 (PCI=1, eci=0x19B01)"
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"

# Aller dans le répertoire de config
cd "$(dirname "$0")"

# Vérifier que les fichiers existent
if [ ! -f "enb2.conf" ]; then
    echo "❌ Erreur: enb2.conf non trouvé!"
    exit 1
fi

if [ ! -f "rr2.conf" ]; then
    echo "❌ Erreur: rr2.conf non trouvé!"
    exit 1
fi

# Démarrer srsENB
echo "🚀 Lancement de srsENB..."
echo ""

sudo srsenb enb2.conf \
    --enb_files.rr_config=rr2.conf \
    --log.all_level=info \
    "$@"

#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
#  F2G TelcoLab — Script de démarrage eNB1 (PC1 - 192.168.1.100)
#  S1 Handover Configuration
# ═══════════════════════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════════════════════════"
echo "  📡 Démarrage eNB1 (S1 Handover activé)"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
echo "  eNB ID:     0x19B"
echo "  Cell ID:    0x01"
echo "  PCI:        1"
echo "  TAC:        0x0001"
echo "  EARFCN:     1450"
echo "  MME:        192.168.1.102"
echo "  S1C bind:   192.168.1.100"
echo ""
echo "  Handover:   ACTIVÉ (ho_active=true)"
echo "  Neighbour:  eNB2 (PCI=2, eci=0x19C01)"
echo ""
echo "════════════════════════════════════════════════════════════════════════════════"

# Aller dans le répertoire de config
cd "$(dirname "$0")"

# Vérifier que les fichiers existent
if [ ! -f "enb1.conf" ]; then
    echo "❌ Erreur: enb1.conf non trouvé!"
    exit 1
fi

if [ ! -f "rr1.conf" ]; then
    echo "❌ Erreur: rr1.conf non trouvé!"
    exit 1
fi

# Démarrer srsENB
echo "🚀 Lancement de srsENB..."
echo ""

sudo srsenb enb1.conf \
    --enb_files.rr_config=rr1.conf \
    --log.all_level=info \
    "$@"

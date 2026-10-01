#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
#  🚀 F2G VoLTE Lab — Script de Démarrage Rapide
#  Créé le: 2026-10-01
# ═══════════════════════════════════════════════════════════════════════════════

OPENIMSS_DIR="/home/f2g/Telecom/Core-Network/openimss"

echo "════════════════════════════════════════════════════════════════════════════════"
echo "  📞 F2G VoLTE Lab — Démarrage"
echo "════════════════════════════════════════════════════════════════════════════════"

cd "$OPENIMSS_DIR" || { echo "❌ Répertoire non trouvé: $OPENIMSS_DIR"; exit 1; }

case "$1" in
    start)
        echo ""
        echo "▶️  Démarrage des containers..."
        docker-compose up -d
        sleep 5
        echo ""
        echo "✅ Containers démarrés"
        $0 status
        ;;
    
    stop)
        echo ""
        echo "⏹️  Arrêt des containers..."
        docker-compose down
        echo "✅ Containers arrêtés"
        ;;
    
    restart)
        echo ""
        echo "🔄 Redémarrage..."
        docker-compose down
        sleep 2
        docker-compose up -d
        sleep 5
        $0 status
        ;;
    
    restart-ims)
        echo ""
        echo "🔄 Redémarrage IMS uniquement..."
        docker restart pcrf pcscf scscf icscf hss
        sleep 3
        echo "✅ IMS redémarré — Fais mode avion ON/OFF sur les téléphones"
        ;;
    
    status)
        echo ""
        echo "📊 État des containers principaux:"
        echo "─────────────────────────────────────────────────────────────────"
        docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "mme|hss|cscf|pcrf|rtpengine|dns|sgw|upf|smf"
        
        echo ""
        echo "📡 Connexions eNB:"
        docker logs mme 2>&1 | grep -i "Number of eNBs" | tail -1
        
        echo ""
        echo "🔗 Connexions Diameter:"
        echo "  MME ↔ HSS: $(docker logs mme 2>&1 | grep -c 'CONNECTED TO.*hss') connexion(s)"
        echo "  PCRF ↔ P-CSCF: $(docker logs pcrf 2>&1 | grep -c 'CONNECTED TO.*pcscf') connexion(s)"
        ;;
    
    logs-call)
        echo ""
        echo "📞 Écoute des logs d'appel VoLTE (Ctrl+C pour arrêter)..."
        echo "─────────────────────────────────────────────────────────────────"
        docker logs -f --since 1s scscf 2>&1 | grep -iE "INVITE|180|200|ACK|BYE|CANCEL"
        ;;
    
    logs-register)
        echo ""
        echo "📝 Écoute des enregistrements IMS (Ctrl+C pour arrêter)..."
        echo "─────────────────────────────────────────────────────────────────"
        docker logs -f --since 1s scscf 2>&1 | grep -iE "REGISTER|200 OK"
        ;;
    
    logs-handover)
        echo ""
        echo "🔄 Écoute des handovers (Ctrl+C pour arrêter)..."
        echo "─────────────────────────────────────────────────────────────────"
        docker logs -f --since 1s mme 2>&1 | grep -iE "handover|source|target|path.switch"
        ;;
    
    fix-mme)
        echo ""
        echo "🔧 Restauration du mme.yaml original..."
        git checkout mme/mme.yaml
        docker restart mme
        sleep 3
        echo "✅ MME restauré et redémarré"
        docker logs mme 2>&1 | grep -i "CONNECTED\|s1ap_server" | tail -3
        ;;
    
    *)
        echo ""
        echo "Usage: $0 {start|stop|restart|restart-ims|status|logs-call|logs-register|logs-handover|fix-mme}"
        echo ""
        echo "Commandes:"
        echo "  start         - Démarrer tous les containers"
        echo "  stop          - Arrêter tous les containers"
        echo "  restart       - Redémarrer tout"
        echo "  restart-ims   - Redémarrer uniquement l'IMS (pcrf, cscf, hss)"
        echo "  status        - Afficher l'état des containers et connexions"
        echo "  logs-call     - Suivre les logs d'appel VoLTE"
        echo "  logs-register - Suivre les enregistrements IMS"
        echo "  logs-handover - Suivre les handovers"
        echo "  fix-mme       - Restaurer la config MME originale"
        echo ""
        ;;
esac

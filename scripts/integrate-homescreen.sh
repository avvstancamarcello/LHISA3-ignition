#!/bin/bash

echo "🚀 INTEGRAZIONE WALLETCONNECT IN HOME SCREEN"
echo "==========================================="

HOME_SCREEN_PATH="$HOME/MyHardhatProjects/LHISA3-ignition/LuccaComixMobile/LuccaComixSolidary/screens/HomeScreen.js"

# Colori
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "📁 ANALISI HOME SCREEN:"
echo "----------------------"

if [ -f "$HOME_SCREEN_PATH" ]; then
    echo -e "${GREEN}✅ HomeScreen.js TROVATO${NC}"
    echo -e "   Dimensioni: $(wc -c < "$HOME_SCREEN_PATH") bytes"
    echo -e "   Linee: $(wc -l < "$HOME_SCREEN_PATH")"
    echo ""
    echo "📄 CONTENUTO ATTUALE (prime 15 linee):"
    head -15 "$HOME_SCREEN_PATH"
else
    echo -e "${RED}❌ HomeScreen.js NON TROVATO${NC}"
    echo "Cercando screens disponibili..."
    ls -la "$(dirname "$HOME_SCREEN_PATH")" 2>/dev/null || echo "Cartella screens non trovata"
    exit 1
fi

echo ""
echo "🔧 CREAZIONE HOME SCREEN AGGIORNATO:"
echo "-----------------------------------"

# Crea backup
backup_file="${HOME_SCREEN_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$HOME_SCREEN_PATH" "$backup_file"
echo -e "${YELLOW}📦 Backup creato: $backup_file${NC}"

# Crea nuovo HomeScreen con WalletConnect
cat > "$HOME_SCREEN_PATH" << 'HOMESCREEN_EOF'
import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import WalletConnect from '../components/WalletConnect';

export default function HomeScreen({ navigation }) {
  return (
    <ScrollView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>🎪 Lucca Comix Solidary</Text>
        <Text style={styles.subtitle}>Trasforma le tue emozioni in valore</Text>
      </View>

      {/* Wallet Connection Section */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>🔗 Portafoglio Blockchain</Text>
        <WalletConnect />
      </View>

      {/* Features Grid */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>✨ Funzionalità</Text>
        
        <TouchableOpacity 
          style={styles.featureCard}
          onPress={() => navigation.navigate('Camera')}
        >
          <Text style={styles.featureIcon}>📸</Text>
          <Text style={styles.featureTitle}>Scatta Foto</Text>
          <Text style={styles.featureDescription}>Crea NFT delle tue emozioni al Lucca Comics</Text>
        </TouchableOpacity>

        <View style={styles.featureCard}>
          <Text style={styles.featureIcon}>🎰</Text>
          <Text style={styles.featureTitle}>Lotteria Oraria</Text>
          <Text style={styles.featureDescription}>Vinci 100 COMIX ogni ora</Text>
        </View>

        <View style={styles.featureCard}>
          <Text style={styles.featureIcon}>❤️</Text>
          <Text style={styles.featureTitle}>Solidarietà</Text>
          <Text style={styles.featureDescription}>2.5% delle donazioni a beneficenza</Text>
        </View>
      </View>

      {/* Network Info */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>🌐 Network</Text>
        <View style={styles.networkCard}>
          <Text style={styles.networkTitle}>Base Mainnet</Text>
          <Text style={styles.networkInfo}>Contratti deployati e pronti</Text>
          <Text style={styles.networkStatus}>✅ ONLINE</Text>
        </View>
      </View>

      {/* Stats */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>📊 Statistiche</Text>
        <View style={styles.statsRow}>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>1,000,000</Text>
            <Text style={styles.statLabel}>COMIX Totali</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>2.5%</Text>
            <Text style={styles.statLabel}>Donazioni</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>100</Text>
            <Text style={styles.statLabel}>Premio Ora</Text>
          </View>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    backgroundColor: '#8B4513',
    padding: 20,
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 5,
  },
  subtitle: {
    fontSize: 16,
    color: 'white',
    opacity: 0.9,
  },
  section: {
    margin: 15,
    marginBottom: 10,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 15,
    color: '#333',
  },
  featureCard: {
    backgroundColor: 'white',
    padding: 15,
    borderRadius: 10,
    marginBottom: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  featureIcon: {
    fontSize: 24,
    marginBottom: 5,
  },
  featureTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  featureDescription: {
    fontSize: 14,
    color: '#666',
    lineHeight: 18,
  },
  networkCard: {
    backgroundColor: '#e8f5e8',
    padding: 15,
    borderRadius: 10,
    borderLeftWidth: 4,
    borderLeftColor: '#4CAF50',
  },
  networkTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  networkInfo: {
    fontSize: 14,
    color: '#666',
    marginBottom: 5,
  },
  networkStatus: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#4CAF50',
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  statItem: {
    flex: 1,
    backgroundColor: 'white',
    padding: 15,
    borderRadius: 10,
    marginHorizontal: 5,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 2,
  },
  statNumber: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#8B4513',
  },
  statLabel: {
    fontSize: 12,
    color: '#666',
    marginTop: 5,
  },
});
HOMESCREEN_EOF

echo -e "${GREEN}✅ HomeScreen AGGIORNATO con WalletConnect!${NC}"
echo ""
echo "🚀 PER TESTARE:"
echo "1. cd ~/MyHardhatProjects/LHISA3-ignition/LuccaComixMobile/LuccaComixSolidary"
echo "2. npm start"
echo "3. Scansiona il QR code con l'app Expo Go"
echo "4. Testa il pulsante 'Connetti Wallet'"


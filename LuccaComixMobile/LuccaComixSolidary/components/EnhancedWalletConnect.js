import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert, Modal } from 'react-native';
import { useWeb3 } from '../hooks/useWeb3';

const EnhancedWalletConnect = () => {
  const { 
    isConnected, 
    userAddress, 
    balance, 
    loading, 
    error,
    connectWallet, 
    disconnect 
  } = useWeb3();

  const [showWalletOptions, setShowWalletOptions] = useState(false);

  const handleConnect = async (walletType) => {
    try {
      setShowWalletOptions(false);
      await connectWallet();
    } catch (err) {
      if (walletType === 'embedded') {
        Alert.alert(
          'MetaMask Embedded', 
          'Vuoi usare MetaMask Embedded Wallet? Questa funzionalità permette:\n\n' +
          '✅ Accesso con email/social\n' +
          '✅ Nessuna estensione richiesta\n' +
          '✅ Transazioni semplificate\n' +
          '✅ Esperienza mobile ottimizzata'
        );
      }
    }
  };

  const formatAddress = (address) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  return (
    <View style={styles.container}>
      {!isConnected ? (
        <>
          <TouchableOpacity 
            style={[styles.button, styles.connectButton]}
            onPress={() => setShowWalletOptions(true)}
            disabled={loading}
          >
            <Text style={styles.buttonText}>
              {loading ? 'Connessione...' : '🔗 Connetti Wallet'}
            </Text>
          </TouchableOpacity>

          <Modal
            visible={showWalletOptions}
            animationType="slide"
            transparent={true}
            onRequestClose={() => setShowWalletOptions(false)}
          >
            <View style={styles.modalContainer}>
              <View style={styles.modalContent}>
                <Text style={styles.modalTitle}>Scegli Wallet</Text>
                
                <TouchableOpacity 
                  style={[styles.walletOption, styles.metamaskOption]}
                  onPress={() => handleConnect('metamask')}
                >
                  <Text style={styles.walletIcon}>🦊</Text>
                  <View style={styles.walletInfo}>
                    <Text style={styles.walletName}>MetaMask</Text>
                    <Text style={styles.walletDescription}>Wallet esterno (estensione/app)</Text>
                  </View>
                </TouchableOpacity>

                <TouchableOpacity 
                  style={[styles.walletOption, styles.embeddedOption]}
                  onPress={() => handleConnect('embedded')}
                >
                  <Text style={styles.walletIcon}>📱</Text>
                  <View style={styles.walletInfo}>
                    <Text style={styles.walletName}>MetaMask Embedded</Text>
                    <Text style={styles.walletDescription}>Accesso con email/social (NOVITÀ)</Text>
                  </View>
                </TouchableOpacity>

                <TouchableOpacity 
                  style={[styles.walletOption, styles.coinbaseOption]}
                  onPress={() => handleConnect('coinbase')}
                >
                  <Text style={styles.walletIcon}>🔷</Text>
                  <View style={styles.walletInfo}>
                    <Text style={styles.walletName}>Coinbase Wallet</Text>
                    <Text style={styles.walletDescription}>Wallet mobile</Text>
                  </View>
                </TouchableOpacity>

                <TouchableOpacity 
                  style={styles.cancelButton}
                  onPress={() => setShowWalletOptions(false)}
                >
                  <Text style={styles.cancelButtonText}>Annulla</Text>
                </TouchableOpacity>
              </View>
            </View>
          </Modal>
        </>
      ) : (
        <View style={styles.connectedContainer}>
          <View style={styles.walletInfo}>
            <Text style={styles.address}>👤 {formatAddress(userAddress)}</Text>
            <Text style={styles.balance}>💰 {parseFloat(balance).toFixed(2)} COMIX</Text>
          </View>
          <TouchableOpacity 
            style={[styles.button, styles.disconnectButton]}
            onPress={disconnect}
          >
            <Text style={styles.buttonText}>Disconnetti</Text>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginVertical: 10,
  },
  button: {
    padding: 15,
    borderRadius: 10,
    alignItems: 'center',
    minWidth: 200,
  },
  connectButton: {
    backgroundColor: '#007AFF',
  },
  disconnectButton: {
    backgroundColor: '#FF3B30',
    padding: 10,
    minWidth: 100,
  },
  buttonText: {
    color: 'white',
    fontWeight: 'bold',
    fontSize: 16,
  },
  connectedContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#F0F0F0',
    padding: 15,
    borderRadius: 10,
  },
  walletInfo: {
    flex: 1,
  },
  address: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  balance: {
    fontSize: 14,
    color: '#666',
  },
  modalContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0,0,0,0.5)',
  },
  modalContent: {
    backgroundColor: 'white',
    padding: 20,
    borderRadius: 15,
    width: '90%',
    maxWidth: 400,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
  },
  walletOption: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 15,
    borderRadius: 10,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  metamaskOption: {
    backgroundColor: '#f8f9fa',
  },
  embeddedOption: {
    backgroundColor: '#e8f5e8',
    borderColor: '#4CAF50',
  },
  coinbaseOption: {
    backgroundColor: '#f0f8ff',
  },
  walletIcon: {
    fontSize: 24,
    marginRight: 15,
  },
  walletInfo: {
    flex: 1,
  },
  walletName: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 2,
  },
  walletDescription: {
    fontSize: 12,
    color: '#666',
  },
  cancelButton: {
    marginTop: 15,
    padding: 12,
    borderRadius: 8,
    backgroundColor: '#8E8E93',
    alignItems: 'center',
  },
  cancelButtonText: {
    color: 'white',
    fontWeight: 'bold',
  },
});

export default EnhancedWalletConnect;

import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { useWeb3 } from '../hooks/useWeb3';

const WalletConnect = () => {
  const { 
    isConnected, 
    userAddress, 
    balance, 
    loading, 
    error,
    connectWallet, 
    disconnect 
  } = useWeb3();

  const handleConnect = async () => {
    try {
      await connectWallet();
    } catch (err) {
      Alert.alert('Errore', err.message);
    }
  };

  const handleDisconnect = () => {
    disconnect();
    Alert.alert('Disconnesso', 'Wallet disconnesso con successo');
  };

  const formatAddress = (address) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  if (error) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity style={styles.button} onPress={handleConnect}>
          <Text style={styles.buttonText}>Riprova</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {!isConnected ? (
        <TouchableOpacity 
          style={[styles.button, styles.connectButton]}
          onPress={handleConnect}
          disabled={loading}
        >
          <Text style={styles.buttonText}>
            {loading ? 'Connessione...' : '🔗 Connetti Wallet'}
          </Text>
        </TouchableOpacity>
      ) : (
        <View style={styles.connectedContainer}>
          <View style={styles.walletInfo}>
            <Text style={styles.address}>
              👤 {formatAddress(userAddress)}
            </Text>
            <Text style={styles.balance}>
              💰 {parseFloat(balance).toFixed(2)} COMIX
            </Text>
          </View>
          <TouchableOpacity 
            style={[styles.button, styles.disconnectButton]}
            onPress={handleDisconnect}
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
    minWidth: 150,
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
  errorContainer: {
    backgroundColor: '#FFE6E6',
    padding: 15,
    borderRadius: 10,
    alignItems: 'center',
  },
  errorText: {
    color: '#FF3B30',
    marginBottom: 10,
    textAlign: 'center',
  },
});

export default WalletConnect;


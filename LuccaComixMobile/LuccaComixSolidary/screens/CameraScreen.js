import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';

export default function CameraScreen({ navigation }) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>📸 Minta la tua Emozione</Text>
      <Text style={styles.subtitle}>
        Cattura un momento magico di Lucca Comics e trasformalo in NFT!
      </Text>
      
      <TouchableOpacity style={styles.cameraButton}>
        <Text style={styles.cameraButtonText}>APRI FOTOCAMERA</Text>
      </TouchableOpacity>

      <Text style={styles.info}>
        Riceverai:{"\n"}
        🎴 1 NFT personalizzato{"\n"}
        💰 100 token COMIX{"\n"}
        ❤️ 2.5% donato in beneficienza
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 10,
  },
  subtitle: {
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 30,
    color: '#7f8c8d',
  },
  cameraButton: {
    backgroundColor: '#e74c3c',
    padding: 20,
    borderRadius: 10,
    alignItems: 'center',
    marginBottom: 20,
  },
  cameraButtonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
  },
  info: {
    fontSize: 16,
    lineHeight: 24,
    textAlign: 'center',
    color: '#2c3e50',
  },
});

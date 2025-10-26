import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';

export default function HomeScreen({ navigation }) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>🎪 Lucca Comix Solidary</Text>
      <Text style={styles.subtitle}>Trasforma le tue emozioni in valore!</Text>
      
      <TouchableOpacity 
        style={styles.button}
        onPress={() => navigation.navigate('Camera')}
      >
        <Text style={styles.buttonText}>📸 Minta la tua Foto</Text>
      </TouchableOpacity>

      <View style={styles.stats}>
        <Text style={styles.statText}>❤️ 2.5% donato in beneficienza</Text>
        <Text style={styles.statText}>🎰 Lotteria ogni ora</Text>
        <Text style={styles.statText}>👻 Privacy totale garantita</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#f0f8ff',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 10,
    color: '#2c3e50',
  },
  subtitle: {
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 30,
    color: '#7f8c8d',
  },
  button: {
    backgroundColor: '#3498db',
    padding: 15,
    borderRadius: 10,
    alignItems: 'center',
    marginBottom: 20,
  },
  buttonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
  },
  stats: {
    marginTop: 20,
    padding: 15,
    backgroundColor: 'white',
    borderRadius: 10,
  },
  statText: {
    fontSize: 16,
    marginBottom: 8,
    color: '#2c3e50',
  },
});

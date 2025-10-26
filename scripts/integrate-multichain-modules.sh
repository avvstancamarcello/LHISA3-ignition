echo "🌉 INTEGRAZIONE MODULI MULTI-CHAIN..."
echo "🚀 Espandendo l'ecosistema SolidarySystem..."

# Crea directory
mkdir -p contracts/interoperability_bridges

# Copia moduli critici
cp ../LHISA3/contracts/07_interoperability_bridges/UniversalMultiChainOrchestrator.sol contracts/interoperability_bridges/
cp ../LHISA3/contracts/07_interoperability/SolidaryGamingBridge.sol contracts/interoperability_bridges/
cp ../LHISA3/contracts/07_interoperability_bridges/EthereumPolygonMultiTokenBridge.sol contracts/interoperability_bridges/

echo "✅ Moduli multi-chain integrati!"
